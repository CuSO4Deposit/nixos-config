{ ... }:
{
  services.nginx = {
    enable = true;

    # Compression was off, which is unnoticeable on the LAN and painful through
    # laborari's public entry: the dashboards are ~2.7MB of JSON and JS that shrinks
    # to roughly 0.5MB, and without this the JS could fail to load outright. Host
    # level rather than per-vhost, since cgit's pages benefit the same way.
    recommendedGzipSettings = true;
  };
}
