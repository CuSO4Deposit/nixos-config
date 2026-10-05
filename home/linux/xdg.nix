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
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
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
