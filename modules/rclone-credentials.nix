{ ... }:
{
  # Single owner of the shared WebDAV credential. Imported by every module that
  # uses the remote (the FUSE mount and the restic backups), so the declaration
  # lives in exactly one place and no consumer depends on another consumer being
  # imported. Module imports are deduplicated by path, so importing this from
  # several places evaluates it once.
  age.secrets."rclone.conf".file = ../secrets/rclone.conf.age;
}
