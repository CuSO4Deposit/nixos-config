{ config, ... }:
{
  age.secrets."api-laborari-env".file = ../../secrets/api-laborari-env.age;

  # Cloudflare-facing nginx server block, included by ./nginx.nix. Encrypted
  # because it carries the public domain; edit with `agenix -e`.
  age.secrets."api-laborari-nginx.conf" = {
    file = ../../secrets/api-laborari-nginx.conf.age;
    owner = "nginx";
    group = "nginx";
  };

  services.api-laborari = {
    enable = true;
    environmentFile = config.age.secrets."api-laborari-env".path;
  };
}
