{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nightcord.notify;

  notify = pkgs.writeShellApplication {
    name = "nightcord-ntfy-send";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''
      # Usage: nightcord-ntfy-send <title> [body] [priority] [tags]
      title=''${1:?usage: nightcord-ntfy-send <title> [body] [priority] [tags]}
      body=''${2:-}
      priority=''${3:-default}
      tags=''${4:-}

      topic=$(cat ${cfg.ntfy.topicFile})
      exec curl -fsS \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$body" \
        "${cfg.ntfy.server}/$topic"
    '';
  };
in
{
  options.nightcord.notify = {
    enable = lib.mkEnableOption "ntfy push notifications";

    ntfy.server = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.sh";
      description = "ntfy server base URL.";
    };

    ntfy.topicFile = lib.mkOption {
      type = lib.types.str;
      default = config.age.secrets."ntfy-topic".path;
      defaultText = lib.literalExpression ''config.age.secrets."ntfy-topic".path'';
      description = "File holding the ntfy topic. Treat the topic as a password.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets."ntfy-topic".file = ../../secrets/ntfy-topic.age;

    environment.systemPackages = [ notify ];

    # Invoked via `OnFailure=nightcord-ntfy-alert@%N.service` on a unit; `%i` is the failed unit
    # name without its type suffix.
    systemd.services."nightcord-ntfy-alert@" = {
      description = "Send an ntfy notification for failed unit %i";
      path = [
        config.systemd.package
        pkgs.coreutils
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        unit="''${1:?usage: nightcord-ntfy-alert@ <unit>}.service"
        host=$(uname -n)
        status=$(systemctl show --value -p Result -p ExecMainStatus "$unit" | paste -sd' ' -)
        log=$(journalctl -u "$unit" -n 5 --no-pager -o cat 2>/dev/null || true)
        body=$(printf 'status: %s\n%s' "$status" "$log")
        ${notify}/bin/nightcord-ntfy-send "FAILED: $host $unit" "$body" high rotating_light
      '';
      scriptArgs = "%i";
    };
  };
}
