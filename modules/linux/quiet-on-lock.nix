{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.nightcord.quiet-on-lock;

  monitorScript = pkgs.writeShellScript "quiet-on-lock-monitor" ''
    set -u

    on_ac() {
      for d in /sys/class/power_supply/*; do
        [ "$(cat "$d/type" 2>/dev/null)" = "Mains" ] && [ "$(cat "$d/online" 2>/dev/null)" = "1" ] && return 0
      done
      return 1
    }

    set_quiet() {
      for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -w "$g" ] && echo schedutil > "$g" 2>/dev/null || true
      done
      [ -w /sys/devices/system/cpu/cpufreq/boost ] && echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
    }

    set_perf() {
      for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -w "$g" ] && echo performance > "$g" 2>/dev/null || true
      done
      [ -w /sys/devices/system/cpu/cpufreq/boost ] && echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
    }

    set_unlocked() {
      if on_ac; then
        set_perf
      else
        set_quiet
      fi
    }

    set_unlocked

    ${pkgs.dbus}/bin/dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Session'" |
      while IFS= read -r line; do
        case "$line" in
          *member=Lock*) set_quiet ;;
          *member=Unlock*) set_unlocked ;;
        esac
      done
  '';
in
{
  options.nightcord.quiet-on-lock = {
    enable = lib.mkEnableOption "quiet CPU profile while the session is locked";
  };

  config = lib.mkIf cfg.enable {
    # On AC an aggressive governor manager (previously auto-cpufreq) pins the CPU to
    # `performance`, keeping it at max frequency even when idle and spinning up the
    # fans at night. This service instead switches to a quiet profile (schedutil
    # governor, turbo off) whenever a session locks — every lock path, from a keybind
    # to hypridle's timeout to lid-close sleep, ends in logind's `Lock` signal — and
    # restores the performance profile on unlock. On battery it stays quiet.
    systemd.services.quiet-on-lock = {
      description = "Switch CPU profile on session lock/unlock";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = monitorScript;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    # power-profiles-daemon would fight this service over the governor.
    services.power-profiles-daemon.enable = false;
  };
}
