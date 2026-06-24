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
    targetUrl = "file:///mnt/work0/duplicity/laborari";
    fullIfOlderThan = "1M";
    cleanup = {
      maxFull = 6;
    };
  };

  systemd.services.duplicity.unitConfig.RequiresMountsFor = "/mnt/work0";
}
