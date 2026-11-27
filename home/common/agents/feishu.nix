{ pkgs, ... }:
{
  home.packages = [ pkgs.lark-cli ];

  home.file = {
    ".agents/skills/feishu-docs".source = ../../../agents/skills/feishu-docs;
    ".agents/skills/lark-doc".source = "${pkgs.lark-cli.src}/skills/lark-doc";
    ".agents/skills/lark-shared".source = "${pkgs.lark-cli.src}/skills/lark-shared";
  };
}
