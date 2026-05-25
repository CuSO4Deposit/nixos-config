{ pkgs, ... }:
{
  services.nginx = {
    virtualHosts = {
      "fava.internal" = {
        locations."/".proxyPass = "http://127.0.0.1:5000";
        locations."/".extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };

  systemd.user.services.git-pull-ledger =
    let
      ledgerPath = "/home/cuso4d/source/beancount";
    in
    {
      description = "git pull ledger repo";
      path = with pkgs; [
        git
        openssh
      ];
      script = ''
        cd ${ledgerPath}
        ${pkgs.git}/bin/git pull
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "cuso4d";
        WorkingDirectory = "${ledgerPath}";
        Environment = [ "HOME=/home/cuso4d" ];
      };
    };
  systemd.user.timers.git-pull-ledger = {
    description = "trigger git-pull-ledger daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.user.services.fava-web =
    let
      package = pkgs.callPackage ../../derivations/fava-with-dashboards { };
    in
    {
      description = "Run Fava web interface with dashboards";
      after = [
        "network.target"
        "git-pull-ledger.service"
      ];
      wants = [ "git-pull-ledger.service" ]; # pull before starting
      wantedBy = [ "default.target" ];
      script = ''
        export HOME=/home/cuso4d
        exec ${package}/bin/fava-with-dashboards \
          --host 127.0.0.1 \
          --port 5000 \
          /home/cuso4d/source/beancount/main.beancount
      '';
      serviceConfig = {
        Type = "simple";
        User = "cuso4d";
        WorkingDirectory = "/home/cuso4d/source/beancount";
        Environment = [ "HOME=/home/cuso4d" ];
      };
    };
}
