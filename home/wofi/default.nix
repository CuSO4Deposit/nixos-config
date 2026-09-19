{ ... }:
{
  programs.wofi = {
    enable = true;
    # Tokyo Night palette, keeps in sync with ~/source/cus-nixvim
    style = ./style.css;
  };
}
