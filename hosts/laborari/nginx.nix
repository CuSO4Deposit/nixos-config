{ config, ... }:
{
  services.nginx = {
    enable = true;
    clientMaxBodySize = "512m";
    recommendedProxySettings = true;
    streamConfig = ''
      server {
        listen 25599;
        proxy_pass 10.20.0.1:25565;
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
      include ${config.age.secrets."haitun-nginx.conf".path};
      include ${config.age.secrets."api-laborari-nginx.conf".path};
      include ${config.age.secrets."observable-nginx.conf".path};
    '';
  };
}
