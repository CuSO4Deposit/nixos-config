{
  config,
  lib,
  ...
}:
let
  cfg = config.nightcord.attic-cache;

  s3Upstream = lib.removeSuffix "/" cfg.s3Upstream;
in
{
  options.nightcord.attic-cache = {
    enable = lib.mkEnableOption "the Attic Nix binary cache server";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "attic.internal";
      description = "Public hostname the cache is served under (through nginx).";
    };

    bucket = lib.mkOption {
      type = lib.types.str;
      default = "attic";
      description = "S3 bucket holding the chunk and NAR stores.";
    };

    region = lib.mkOption {
      type = lib.types.str;
      default = "us-east-1";
    };

    s3Upstream = lib.mkOption {
      type = lib.types.str;
      description = "Real S3 endpoint that nginx proxies to (e.g. the MinIO server).";
    };

    s3Host = lib.mkOption {
      type = lib.types.str;
      description = "Authority of s3Upstream, used for the Host and TLS names of proxied requests.";
    };

    resolver = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.53";
      description = "Resolver nginx uses for the lazily resolved s3Upstream.";
    };

    s3ProxyPort = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Port on listenAddress that exposes the S3 API to cache clients.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.20.0.2";
      description = "Address nginx binds for both the cache and the S3 proxy.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Loopback port atticd listens on.";
    };

    retentionPeriod = lib.mkOption {
      type = lib.types.str;
      default = "90 days";
      description = "How long unaccessed store paths stay in the cache.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        EnvironmentFile with ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 and the
        S3 credentials. Not a store path, so point it at an agenix secret.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.atticd = {
      enable = true;
      environmentFile = cfg.environmentFile;
      settings = {
        listen = "127.0.0.1:${toString cfg.listenPort}";
        "allowed-hosts" = [ cfg.hostName ];
        "api-endpoint" = "http://${cfg.hostName}/";
        database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
        storage = {
          type = "s3";
          region = cfg.region;
          bucket = cfg.bucket;
          endpoint = s3Upstream;
        };
        chunking = {
          "nar-size-threshold" = 16384;
          "min-size" = 16384;
          "avg-size" = 65536;
          "max-size" = 262144;
        };
        compression = {
          type = "zstd";
          level = 8;
        };
        "garbage-collection" = {
          interval = "12 hours";
          "default-retention-period" = cfg.retentionPeriod;
        };
      };
    };

    # The chunk store is reachable only over the office tunnel.
    systemd.services.atticd = {
      wants = [ "wg-quick-wg0.service" ];
      after = [ "wg-quick-wg0.service" ];
    };

    services.nginx.enable = lib.mkDefault true;
    services.nginx.recommendedProxySettings = lib.mkDefault true;

    services.nginx.virtualHosts."${cfg.hostName}" = {
      listen = [
        {
          addr = cfg.listenAddress;
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.listenPort}";
        extraConfig = ''
          proxy_redirect ${s3Upstream}/ http://${cfg.hostName}:${toString cfg.s3ProxyPort}/;
          client_max_body_size 0;
          proxy_request_buffering off;
          proxy_buffering off;
        '';
      };
    };

    # Single-chunk NARs redirect to a presigned URL on the upstream authority,
    # so the client-visible copy is rewritten and the proxy keeps the signed Host.
    services.nginx.appendHttpConfig = ''
      server {
        listen ${cfg.listenAddress}:${toString cfg.s3ProxyPort};
        client_max_body_size 0;
        resolver ${cfg.resolver} valid=30s ipv6=off;
        set $s3_upstream '${s3Upstream}';

        location /${cfg.bucket}/ {
          limit_except GET {
            deny all;
          }
          proxy_pass $s3_upstream;
          proxy_set_header Host ${cfg.s3Host};
          proxy_ssl_server_name on;
          proxy_ssl_name ${cfg.s3Host};
          proxy_request_buffering off;
          proxy_buffering off;
          proxy_http_version 1.1;
        }
      }
    '';
  };
}
