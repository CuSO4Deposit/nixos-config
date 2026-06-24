{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.nightcord.rclone-webdav;
in
{
  options.nightcord.rclone-webdav = {
    enable = lib.mkEnableOption "Rclone WebDAV mount (via systemd automount)";
    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "webdav";
      description = "remote name in rclone.conf";
    };
    remotePath = lib.mkOption {
      type = lib.types.str;
      description = "remote path to mount (a dedicated dir, NOT the root shared with JuiceFS)";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/work0";
    };
    vfsCacheMaxSize = lib.mkOption {
      type = lib.types.str;
      default = "2G";
      description = "max size of the VFS disk cache (--vfs-cache-max-size)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Make the mount.rclone helper discoverable by mount(8).
    system.fsPackages = [ pkgs.rclone ];

    # Declarative FUSE mount. systemd owns the lifecycle: "active" means the
    # mount is actually in the kernel mount table, the mountpoint dir is
    # created on demand, and stale endpoints from a crashed rclone are
    # cleaned up automatically. x-systemd.automount mounts lazily on first
    # access so a switch/boot never blocks on the remote being reachable.
    fileSystems.${cfg.mountPoint} = {
      device = "${cfg.remoteName}:${cfg.remotePath}";
      fsType = "rclone";
      options = [
        "nodev"
        "nofail"
        "_netdev"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "config=${config.age.secrets."rclone.conf".path}"
        "vfs-cache-mode=full"
        "vfs-cache-max-size=${cfg.vfsCacheMaxSize}"
        "allow-other"
        "uid=1000"
        "gid=100"
        "umask=0077"
        "buffer-size=32M"
      ];
    };

    age.secrets."rclone.conf".file = ../../secrets/rclone.conf.age;
  };
}
