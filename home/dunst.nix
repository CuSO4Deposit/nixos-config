{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        # background = "#24283b";
        background = "#11111b";

        # foreground = "#cocaf5";
        foreground = "#a6e3a1";

        font = "Noto Sans CJK SC 16";

        follow = "keyboard";

        frame_color = "#11111b";

        frame_width = 3;

        height = "200";

        # Show how many messages are currently hidden (because of
        # notification_limit).
        indicate_hidden = "yes";

        # Maximum number of notificaion (0 means no limit)
        notification_limit = 0;

        # Offset from the origin
        offset = "20x20";

        origin = "top-center";

        # Padding between text and separator
        padding = 12;

        progress_bar = true;

        # Set the progress bar height. This includes the frame, so make sure
        # it's at least twice as big as the frame width.
        progress_bar_height = 10;

        # X11 only
        # transparency = 10;

        # Draw a line of "separator_height" pixel height between two
        # notifications.
        separator_height = 2;

        width = "(0, 400)";
      };
      urgency_critical = {
        foreground = "#f38ba8";
        frame_color = "#f38ba8";
      };
    };
    waylandDisplay = "true";
  };
}
