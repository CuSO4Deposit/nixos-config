{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-auto-build;

  dashboardHtml = ./dashboard.html;

  buildScript = pkgs.writeShellScript "nix-auto-build" ''
    set -euo pipefail

    REPO="${cfg.repoPath}"
    CACHE="${cfg.cachePath}"
    STATUS_DIR="${cfg.statusDir}"
    SIGNING_KEY="$CREDENTIALS_DIRECTORY/signing-key"
    HOSTS="${lib.concatStringsSep " " cfg.hosts}"
    WORKTREE="$STATUS_DIR/worktree"

    mkdir -p "$STATUS_DIR"

    # Initialize status.json
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq -n --arg t "$now" '{last_run: $t, hosts: {}}' > "$STATUS_DIR/status.json"

    update_status() {
      local host="$1" status="$2" extra="''${3:-}"
      local ts
      ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      local expr=".hosts[\"$host\"].status = \"$status\" | .hosts[\"$host\"].updated = \"$ts\""
      [ -n "$extra" ] && expr="$expr | $extra"
      jq "$expr" "$STATUS_DIR/status.json" > "$STATUS_DIR/status.json.tmp"
      mv "$STATUS_DIR/status.json.tmp" "$STATUS_DIR/status.json"
    }

    # Mark all hosts as pending
    for h in $HOSTS; do update_status "$h" "pending"; done

    # Set up git worktree
    rm -rf "$WORKTREE"
    git -c safe.directory='*' -C "$REPO" worktree add --detach "$WORKTREE" HEAD

    cleanup() {
      git -c safe.directory='*' -C "$REPO" worktree remove --force "$WORKTREE" 2>/dev/null || true
    }
    trap cleanup EXIT

    cd "$WORKTREE"

    # Update flake inputs
    nix flake update 2>&1 || true

    # Build each host
    for h in $HOSTS; do
      update_status "$h" "building"
      echo "=== Building $h ==="
      if STORE_PATH=$(nix build ".#nixosConfigurations.$h.config.system.build.toplevel" \
            --no-link --print-out-paths 2>&1); then
        echo "Signing $STORE_PATH"
        nix store sign --key-file "$SIGNING_KEY" -r "$STORE_PATH"
        echo "Copying to cache"
        nix copy --to "file://$CACHE" "$STORE_PATH"
        update_status "$h" "success" ".hosts[\"$h\"].store_path = \"$STORE_PATH\""
        echo "=== $h succeeded ==="
      else
        update_status "$h" "failed" ".hosts[\"$h\"].error = \"build failed\""
        echo "=== $h FAILED ==="
      fi
    done

    # Save flake.lock for cached rebuilds
    cp "$WORKTREE/flake.lock" "$STATUS_DIR/flake.lock"

    # Update last_run timestamp
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg t "$now" '.last_run = $t' "$STATUS_DIR/status.json" > "$STATUS_DIR/status.json.tmp"
    mv "$STATUS_DIR/status.json.tmp" "$STATUS_DIR/status.json"

    # Generate dashboard
    cp "${dashboardHtml}" "$STATUS_DIR/dashboard.html"
  '';

  gcScript = pkgs.writeShellScript "nix-auto-build-gc" ''
    set -euo pipefail
    CACHE="${cfg.cachePath}"
    STATUS_DIR="${cfg.statusDir}"
    STATUS="$STATUS_DIR/status.json"

    [ -f "$STATUS" ] || exit 0

    # Collect all successful store paths
    PATHS=$(jq -r '.hosts[].store_path // empty' "$STATUS")
    [ -z "$PATHS" ] && exit 0

    # Build full closure
    KEEP=$(mktemp)
    for p in $PATHS; do
      nix-store -qR "$p" >> "$KEEP"
    done
    sort -u "$KEEP" -o "$KEEP"

    # Remove narinfos not in closure
    find "$CACHE" -name '*.narinfo' | while read -r ni; do
      sp=$(grep -m1 '^StorePath:' "$ni" | cut -d' ' -f2)
      if ! grep -qxF "$sp" "$KEEP"; then
        # Remove narinfo and its nar file
        nar=$(grep -m1 '^URL:' "$ni" | cut -d' ' -f2)
        [ -n "$nar" ] && rm -f "$CACHE/$nar"
        rm -f "$ni"
      fi
    done
    rm -f "$KEEP"
  '';
in
{
  options.nix-auto-build = {
    enable = lib.mkEnableOption "automatic background NixOS builds";
    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/cuso4d/.nixos";
    };
    cachePath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/minio/nix-cache";
    };
    statusDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/nix-auto-build";
    };
    calendar = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 19:00:00";
    };
    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "nightcord-laborari"
        "nightcord-lexikos"
        "nightcord-proximo"
        "nightcord-dynamica"
      ];
    };
    gcCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
    };
    cachePublicKey = lib.mkOption {
      type = lib.types.str;
      description = "Public key for the binary cache signing key";
    };
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.20.0.2";
      description = "nginx listen address (wg2 IP)";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-auto-build = {
      description = "Automatic background NixOS builds";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = buildScript;
        Nice = 19;
        CPUWeight = 10;
        MemoryMax = "60%";
        TimeoutStartSec = "4h";
        LoadCredential = "signing-key:${config.age.secrets."nix-cache-signing-key".path}";
      };
      wants = [
        "rclone-minio-mount.service"
        "network-online.target"
      ];
      after = [
        "rclone-minio-mount.service"
        "network-online.target"
      ];
      environment = {
        http_proxy = "http://127.0.0.1:20172";
        https_proxy = "http://127.0.0.1:20172";
      };
      path = with pkgs; [
        git
        nix
        jq
        coreutils
        findutils
        gnugrep
      ];
    };

    systemd.timers.nix-auto-build = {
      description = "Timer for automatic NixOS builds";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
        Persistent = true;
      };
    };

    systemd.services.nix-auto-build-gc = {
      description = "Garbage collect nix binary cache";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = gcScript;
      };
      path = with pkgs; [
        nix
        jq
        coreutils
        findutils
        gnugrep
      ];
    };

    systemd.timers.nix-auto-build-gc = {
      description = "Timer for nix cache garbage collection";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.gcCalendar;
        Persistent = true;
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."nix-auto-build.internal" = {
      listen = [
        {
          addr = cfg.listenAddress;
          port = 80;
        }
      ];
      locations."/" = {
        root = cfg.cachePath;
        extraConfig = "autoindex on;";
      };
      locations."= /dashboard" = {
        alias = "${cfg.statusDir}/dashboard.html";
      };
      locations."= /status.json" = {
        alias = "${cfg.statusDir}/status.json";
      };
    };
  };
}
