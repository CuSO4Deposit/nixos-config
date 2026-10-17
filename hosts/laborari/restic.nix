{ ... }:
{
  nightcord.restic-backup = {
    enable = true;
    paths = [
      "/home/cuso4d/syncthing"
      "/var/lib/terraria"
      "/var/lib/terraria2"

      "/home/cuso4d/Documents"
      "/home/cuso4d/Pictures"

      "/home/cuso4d/.ssh"
      "/home/cuso4d/.config"

      "/home/cuso4d/.wakatime"
      "/home/cuso4d/.zsh_history"
    ];

    exclude = [
      # GitHub-hosted; the ghorg mirror already carries it.
      "/home/cuso4d/Documents/logseq"
      "/home/cuso4d/Documents/Logseq"
      "/home/cuso4d/.config/Logseq"

      # Chat app local stores the user opted out of.
      "/home/cuso4d/.config/QQ"
      "/home/cuso4d/.config/LarkShell"

      "**/node_modules"
      "**/.venv"
      "**/__pycache__"
    ];
  };
}
