{ ... }:
{
  services.cgit."git-ro" = {
    enable = true;
    group = "ghorg";
    gitHttpBackend.enable = false;
    scanPath = "/data/ghorg";
    nginx.virtualHost = "git-ro.internal";
    settings = {
      clone-url = "http://git-ro.internal/$CGIT_REPO_URL";
      enable-index-links = true;
      remove-suffix = true;
      root-desc = "Read-only view of /data/ghorg on proximo";
      root-title = "git-ro.internal";
    };
  };
}
