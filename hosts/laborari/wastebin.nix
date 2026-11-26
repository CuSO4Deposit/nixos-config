{
  config,
  lib,
  pkgs,
  ...
}:
{
  age.secrets = {
    "wastebin-env" = {
      file = ../../secrets/wastebin.env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "wastebin-nginx.conf" = {
      file = ../../secrets/wastebin-nginx.conf.age;
      owner = "nginx";
      group = "nginx";
    };
    "wastebin-url" = {
      file = ../../secrets/wastebin-url.age;
      owner = "cuso4d";
      group = "users";
      mode = "0400";
    };
    "wastebin-auth" = {
      file = ../../secrets/wastebin-auth.age;
      owner = "cuso4d";
      group = "users";
      mode = "0400";
    };
    "wastebin.htpasswd" = {
      file = ../../secrets/wastebin.htpasswd.age;
      owner = "nginx";
      group = "nginx";
      mode = "0400";
    };
  };

  programs.zsh.interactiveShellInit = lib.mkAfter ''
    wastebin_url=${config.age.secrets.wastebin-url.path}
    if [ -r "$wastebin_url" ]; then
      export WASTEBIN_URL="$(cat "$wastebin_url")"
    fi
    wastebin_auth=${config.age.secrets.wastebin-auth.path}
    if [ -r "$wastebin_auth" ]; then
      export WASTEBIN_AUTH="$(cat "$wastebin_auth")"
    fi

    waste() {
      local extension="''${1:-txt}"
      if [ -z "''${WASTEBIN_URL:-}" ]; then
        echo "waste: WASTEBIN_URL is not set" >&2
        return 1
      fi
      if [ -z "''${WASTEBIN_AUTH:-}" ]; then
        echo "waste: WASTEBIN_AUTH is not set" >&2
        return 1
      fi
      ${pkgs.jq}/bin/jq -Rs --arg extension "$extension" '{text: ., extension: $extension}' |
        ${pkgs.curl}/bin/curl -fsS --user "$WASTEBIN_AUTH" \
          -H 'Content-Type: application/json' --data-binary @- \
          "''${WASTEBIN_URL%/}/" |
        ${pkgs.jq}/bin/jq -r --arg url "''${WASTEBIN_URL%/}" '($url + .path)'
    }
  '';

  services.nginx.appendHttpConfig = lib.mkAfter ''
    include ${config.age.secrets."wastebin-nginx.conf".path};
  '';

  services.wastebin = {
    enable = true;

    settings = {
      WASTEBIN_ADDRESS_PORT = "127.0.0.1:8082";
      WASTEBIN_DATABASE_PATH = "/var/lib/wastebin/sqlite3.db";
      WASTEBIN_MAX_BODY_SIZE = 8388608;
      WASTEBIN_PASTE_EXPIRATIONS = "1d,7d,1M,3M=d,6M,1y";
    };

    secretFile = config.age.secrets.wastebin-env.path;
  };
}
