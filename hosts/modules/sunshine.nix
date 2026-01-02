{ ... }:
{
  services.sunshine = {
    autoStart = true;
    capSysAdmin = true; # wayland
    enable = true;
    openFirewall = true;
  };
}
