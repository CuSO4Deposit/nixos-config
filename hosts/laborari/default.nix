{
  config,
  ...
}:
{
  imports = [
    ../modules/desktop.nix
    ../modules/internal-dns.nix
    ../modules/juicefs-mount.nix
    ../modules/minio-mount.nix
    ../modules/rclone-webdav-mount.nix
    ../modules/nix-auto-build
    ../modules/opencode-web.nix
    ../modules/office-wg.nix
    ../modules/server.nix
    ../modules/syncthing.nix
    ../hardware-configuration/laborari.nix
    ./nginx.nix
    ./terraria.nix
    ./duplicity.nix
  ];

  nightcord.internal-dns = {
    enable = true;
    hostOverrides = {
      "10.20.0.2" = [ "nix-auto-build.internal" ];
    };
    laborariAddress = "127.0.0.1";
    proximoAddress = "10.20.0.1";
  };

  nightcord.syncthing.deviceName = "nightcord-laborari";

  age.secrets = {
    "office-band.conf".file = ../../secrets/office-band.conf.age;
    "wg-laborari.conf".file = ../../secrets/wg-laborari.conf.age;
    "nix-cache-signing-key".file = ../../secrets/nix-cache-signing-key.age;
    "piwigo-nginx.conf" = {
      file = ../../secrets/piwigo-nginx.conf.age;
      owner = "nginx";
      group = "nginx";
    };
    "cloudflare-origin-cert.pem" = {
      file = ../../secrets/cloudflare-origin-cert.pem.age;
      owner = "nginx";
      group = "nginx";
    };
    "cloudflare-origin-key.pem" = {
      file = ../../secrets/cloudflare-origin-key.pem.age;
      owner = "nginx";
      group = "nginx";
    };
    "opencode-nginx.conf" = {
      file = ../../secrets/opencode-nginx.conf.age;
      owner = "nginx";
      group = "nginx";
    };
    "opencode-server-password" = {
      file = ../../secrets/opencode-server-password.age;
      owner = "cuso4d";
    };
  };

  boot.binfmt.emulatedSystems = [
    "loongarch64-linux"
  ];

  nightcord.nix-auto-build = {
    enable = true;
    cachePath = "/mnt/minio/nix-cache-54168";
    cachePublicKey = "nix-cache.laborari:wPKpQRXxNF7jBk6A1vn26ObhXAEWN8jF0QCTkdT+qe0=";
  };
  nightcord.proxy = "http://127.0.0.1:20172";
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  # OpenGL
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
  home-manager.users.cuso4d = {
    imports = [ ../modules/home/laborari.nix ];
  };

  nightcord.juicefs-mount = {
    dbHost = "10.20.0.1";
    enable = true;
    waitServices = [
      "wg-quick-wg2.service"
    ];
  };

  nightcord.rclone-minio.waitServices = [
    "wg-quick-wg0.service"
  ];

  nightcord.rclone-webdav = {
    enable = true;
    remotePath = "/webdav";
  };

  networking.firewall.allowedTCPPorts = [
    22222
    2053
  ];
  networking.firewall.allowedUDPPorts = [ 5182 ];
  networking.firewall.trustedInterfaces = [ "wg2" ];
  networking.hostName = "nightcord-laborari";
  # Keep NetworkManager from changing the kernel's IPv4 forwarding state.
  networking.networkmanager.settings.connection."ipv4.forwarding" = 3;
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg2" ];
    externalInterface = "enp4s0";
  };
  networking.networkmanager.enable = true;
  networking.proxy.httpProxy = config.nightcord.proxy;
  networking.proxy.httpsProxy = config.nightcord.proxy;
  networking.proxy.noProxy = "127.0.0.1,localhost,mirrors.ustc.edu.cn,mirrors.tuna.tsinghua.edu.cn";
  networking.wg-quick.interfaces.wg1.configFile = config.age.secrets."office-band.conf".path;
  networking.wg-quick.interfaces.wg2.configFile = config.age.secrets."wg-laborari.conf".path;

  programs.mosh.enable = true;
  programs.steam.enable = true;

  services.openssh.ports = [ 22222 ];
  services.xserver.videoDrivers = [ "nvidia" ];
  services.v2raya.enable = true;

  time.timeZone = "Etc/UTC";

  users.users."guest" = {
    isNormalUser = true;
    home = "/home/guest";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIEu5dDs5aj4vo5cG7BFiGCDPAyQ6VEnijrO1X2m34v"
    ];
  };

  virtualisation.docker = {
    daemon.settings = {
      proxies = {
        http-proxy = config.nightcord.proxy;
        https-proxy = config.nightcord.proxy;
      };
      registry-mirrors = [
        "https://docker-0.unsee.tech"
        "https://docker.mirrors.kclab.cloud/"
        "https://docker.1panel.live"
      ];
    };
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
