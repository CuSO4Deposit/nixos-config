{ config, ... }:
{
  # nginx binds 10.20.0.2:80, the wg2 address. Without this ordering, a
  # switch/system activation that restarts both the wg-quick units and nginx
  # can start nginx while wg2 is still down, so bind() fails with
  # EADDRNOTAVAIL and switch-to-configuration aborts.
  systemd.services.nginx = {
    wants = [ "wg-quick-wg2.service" ];
    after = [ "wg-quick-wg2.service" ];
  };

  services.nginx = {
    enable = true;
    clientMaxBodySize = "512m";
    recommendedProxySettings = true;
    # External TCP entries into the papermc instances on proximo. Minecraft is
    # plaintext TCP, so nginx stream forwards one external port per server.
    streamConfig = ''
      server {
        listen 25599;
        proxy_pass 10.20.0.1:25565;
      }
      server {
        listen 25598;
        proxy_pass 10.20.0.1:25566;
      }
    '';
    appendHttpConfig = ''
      server {
        listen 2053 default_server;
        server_name _;

        ssl_certificate ${config.age.secrets."cloudflare-origin-cert.pem".path};
        ssl_certificate_key ${config.age.secrets."cloudflare-origin-key.pem".path};

        return 444;
      }

      include ${config.age.secrets."piwigo-nginx.conf".path};
      include ${config.age.secrets."opencode-nginx.conf".path};
      include ${config.age.secrets."api-laborari-nginx.conf".path};
      include ${config.age.secrets."observable-nginx.conf".path};
    '';
  };
}
