{
  pkgs,
  ...
}:
{
  xdg.desktopEntries = {
    feishu-fcitx5 = {
      name = "FeishuFcitx5";
      exec = "feishu-fcitx5 %U";
      type = "Application";
      terminal = false;
    };
    wemeet-nvidia = {
      name = "WemeetAppNvidia";
      exec = "wemeet-nvidia %u";
      type = "Application";
      terminal = false;
    };
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";
    };
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

}
