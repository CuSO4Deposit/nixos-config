{
  boot.loader.systemd-boot.enable = true;

  imports = [
    ./proximo-hardware-configuration.nix
  ];

  networking.hostName = "nightcord-proximo";

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  users.users."cuso4d".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJD6JpxiKFEThom4/HMchI8S08+Tuxvp04xSLxtMMLH cuso4d"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgnoIeHJv3VVT9SgOELc0rlnPz+cv4uA2yESbLdJ7Vv cuso4d"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAuc62mBhz6WsjQ8A18hy4LhtmZpBtj/6vMsAUF0/gm cuso4d"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzaVljG6lJvVE4u5h9p76FIgWm4HQuWjdBPD7P1bQ+t cuso4d"
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
