{
  networking.hostName = "nightcord-laborari";

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
    settings.KbdInteractiveAuthentication = false;
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    "proxies" = {
      "http-proxy" = "http://172.31.80.1:7890";
      "https-proxy" = "http://172.31.80.1:7890";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
