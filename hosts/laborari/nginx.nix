{ config, ... }:
{
  services.nginx = {
    enable = true;
    clientMaxBodySize = "512m";
    recommendedProxySettings = true;
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
    '';
  };
}
