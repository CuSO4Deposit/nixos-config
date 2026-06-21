{ ... }:
{
  services.duplicity = {
    enable = true;
    include = [
      "/var/lib/terraria"
    ];
    exclude = [
      "**"
    ];
    extraFlags = [
      "--no-encryption"
    ];
    frequency = "daily";
    targetUrl = "file:///mnt/jfs/duplicity/laborari";
    fullIfOlderThan = "1M";
    cleanup = {
      maxFull = 6;
    };
  };
}
