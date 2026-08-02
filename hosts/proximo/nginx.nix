{ ... }:
{
  services.nginx = {
    enable = true;

    # Compression was off, which is unnoticeable on the LAN and painful through
    # laborari's public entry: the dashboards are ~2.7MB of JSON and JS that shrinks
    # to roughly 0.5MB, and without this the JS could fail to load outright. Host
    # level rather than per-vhost, since cgit's pages benefit the same way.
    #
    # Both options turn on their `*_static` directive, which is the point here: the
    # observable build writes `.br` and `.gz` siblings next to each asset, so a
    # request is answered by sending an already-compressed file rather than by
    # compressing again. Precompression can afford `brotli -q 11`, roughly 25-30%
    # smaller than gzip on this data, where the per-request setting could not.
    #
    # Keep both. Brotli is preferred when the client offers it and gzip covers the
    # rest, and a client offering neither still gets the plain file.
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
  };
}
