{ ... }:
{
  nightcord.restic-backup = {
    enable = true;
    paths = [
      "/home/cuso4d/Documents"
      "/home/cuso4d/Pictures"
      "/home/cuso4d/archive"
      "/home/cuso4d/.ssh"
      "/home/cuso4d/.local/share/Terraria"
      "/home/cuso4d/.local/share/Steam/userdata/1113845821/105600"
      "/home/cuso4d/.local/share/hmcl"
    ];
    exclude = [
      # GitHub-hosted; the ghorg mirror already carries it.
      "/home/cuso4d/Documents/logseq"
      "/home/cuso4d/Documents/Logseq"
    ];
  };
}
