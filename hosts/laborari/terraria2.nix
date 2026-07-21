{ pkgs, lib, ... }:
# The upstream `services.terraria` NixOS module is a singleton, so this is a
# hand-rolled second Terraria server. It mirrors the upstream module's
# tmux-wrapped `terraria-server` approach but uses its own data dir/socket and
# reuses the `terraria` user/group created by the first (services.terraria)
# instance.
let
  port = 15555;
  dataDir = "/var/lib/terraria2";
  package = pkgs.terraria-server;

  flags = [
    "-port ${toString port}"
    "-maxPlayers 4"
    "-password \"c404\""
    "-motd \"Hello, Docker 大王\""
    "-world \"${dataDir}/Docker_Shitproducing_King.wld\""
    "-autocreate 2"
  ];

  tmuxCmd = "${lib.getExe pkgs.tmux} -S ${lib.escapeShellArg dataDir}/terraria.sock";

  stopScript = pkgs.writeShellScript "terraria2-stop" ''
    if ! [ -d "/proc/$1" ]; then
      exit 0
    fi

    lastline=$(${tmuxCmd} capture-pane -p | grep . | tail -n1)

    if [[ "$lastline" =~ ^'Choose World' ]]; then
      ${tmuxCmd} kill-session
    else
      ${tmuxCmd} send-keys Enter exit Enter
    fi

    tail --pid="$1" -f /dev/null
  '';
in
{
  # The `terraria` user/group already exist (created by services.terraria).
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 terraria terraria - -"
  ];

  systemd.services.terraria2 = {
    description = "Terraria Server Service (second instance, port ${toString port})";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "terraria";
      Group = "terraria";
      Type = "forking";
      GuessMainPID = true;
      UMask = 7;
      ExecStart = "${tmuxCmd} new -d ${lib.getExe package} ${lib.concatStringsSep " " flags}";
      ExecStop = "${stopScript} $MAINPID";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];
}
