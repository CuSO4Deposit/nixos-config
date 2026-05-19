{
  config,
  lib,
  ...
}:
let
  cfg = config.nightcord.internal-dns;
  laborariAliases = [
    "nix-auto-build.internal"
    "opencode.internal"
  ];
  proximoAliases = [
    "fava.internal"
    "git-ro.internal"
  ];
  overrideAliases = builtins.concatLists (builtins.attrValues cfg.hostOverrides);
in
{
  options.nightcord.internal-dns = {
    enable = lib.mkEnableOption "internal DNS aliases";

    laborariAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.20.0.2";
      description = "The address that should be used to reach laborari from this host.";
    };

    proximoAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.20.0.1";
      description = "The address that should be used to reach proximo from this host.";
    };

    hostOverrides = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = {
        "10.20.0.2" = [ "nix-auto-build.internal" ];
      };
      description = "Address-to-alias overrides that should take precedence over the default host mappings.";
    };

    extraHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Additional entries to merge into networking.hosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.hosts =
      lib.optionalAttrs (cfg.laborariAddress != null) {
        "${cfg.laborariAddress}" = lib.subtractLists overrideAliases laborariAliases;
      }
      // lib.optionalAttrs (cfg.proximoAddress != null) {
        "${cfg.proximoAddress}" = lib.subtractLists overrideAliases proximoAliases;
      }
      // cfg.hostOverrides
      // cfg.extraHosts;
  };
}
