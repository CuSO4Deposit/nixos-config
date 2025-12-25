{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.wofi = {
    enable = true;
    # https://github.com/Sit-Back/wofi-tokyonight/blob/0909aacff8d578777e2d2c261a40bf456226e4c8/style.css
    style = ''
        window {
            background-color: rgb(26, 27, 38);
            border-radius: 0.5em;
        }

        #input {
            padding: 0.7em;
            border-radius: 0.5em 0.5em 0 0;
            background-color: #2d2e40;
            color: #c0caf5;
            border: none;
        }

        #text {
            color: #c0caf5;
        }

        #entry {
            padding: 0.7em;
            color: #c0caf5;
        }

      #entry:selected {
            background-color: #7aa2f7;
        } 

      #text:selected {
            color: #eee;
            font-weight: bold;
        }
    '';
  };
}
