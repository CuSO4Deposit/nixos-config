{
  config,
  lib,
  pkgs,
  ...
}:
{
  age.secrets.wg-proximo-priv = {
    file = ../secrets/wg-proximo-priv.age;
    mode = "400";
    owner = "root";
  };

  boot.loader.systemd-boot.enable = true;

  imports = [
    ./modules/juicefs-mount.nix
    ./modules/server.nix
    ./proximo-hardware-configuration.nix
  ];

  juicefs-mount.dbHost = "127.0.0.1";
  juicefs-mount.waitServices = [
    "mysql.service"
  ];

  networking.firewall.allowedTCPPorts = [
    80
    7777
  ];
  networking.firewall.allowedUDPPorts = [
    51820
  ];
  networking.firewall.trustedInterfaces = [ "wg0" ];
  networking.hostName = "nightcord-proximo";
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.20.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wg-proximo-priv.path;

    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o ens18 -j MASQUERADE
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -A FORWARD -o wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    '';

    postShutdown = ''
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o ens18 -j MASQUERADE
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -D FORWARD -o wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    '';

    peers = [
      {
        publicKey = "esLilipPwoqxajyribZ/FAJdE7HeaOO1/u+pjoa5aWk=";
        allowedIPs = [ "10.20.0.2/32" ];
      }
    ];
  };

  services.duplicity = {
    enable = true;
    include = [
      "/var/lib/minecraft"
    ];
    exclude = [
      "**"
    ];
    extraFlags = [
      "--no-encryption"
    ];
    frequency = "daily";
    targetUrl = "file:///mnt/jfs/duplicity/proximo/var/lib/minecraft";
    fullIfOlderThan = "1M";
    cleanup = {
      maxFull = 6;
    };
  };

  services.minecraft-server = {
    declarative = true;
    enable = true;
    eula = true;
    openFirewall = true;
    serverProperties = {
      allow-cheats = true;
      difficulty = "hard";
      gamemode = "survival";
      level-name = "MOTION_SICKNESS_DEMO_MC_WO_SITAI";
      max-players = 4;
      motd = "点我放松一下";
      online-mode = false;
      server-port = 25565;
      white-list = false;
    };
    package = pkgs.papermc;
    whitelist = {
      "CuSO4D" = "0f5f4275-656f-41e4-b2ef-1a7914c2e5df";
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.nginx = {
    enable = true;
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

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
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
      package = pkgs.callPackage ../derivations/fava-with-dashboards { };
    in
    {
      description = "Run Fava web interface with dashboards";
      after = [
        "network.target"
        "git-pull-ledger.service"
      ];
      wants = [ "git-pull-ledger.service" ]; # pull before starting
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

  users.users."cuso4d".extraGroups = lib.mkAfter [
    "minecraft"
  ];
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
