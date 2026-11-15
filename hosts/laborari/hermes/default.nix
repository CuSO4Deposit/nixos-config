{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hermesHome = "${config.services.hermes-agent.stateDir}/.hermes";
  resticDumpDir = "/var/lib/hermes/restic-dumps";

  sqliteDbs = [
    "state.db"
    "kanban.db"
    "shared-state.db"
    "cron/executions.db"
  ];

  dumpSqlite = lib.concatMapStrings (db: ''
    if [ -e "${hermesHome}/${db}" ]; then
      sqlite3 -cmd ".timeout 10000" "${hermesHome}/${db}" ".backup '${resticDumpDir}/${builtins.baseNameOf db}'"
    fi
  '') sqliteDbs;

  serper-mcp = import ../../../lib/serper-mcp.nix {
    inherit pkgs;
    secretPath = config.age.secrets."serper-api-key-hermes".path;
  };

  hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal.override {
    extraDependencyGroups = [
      "messaging"
      "matrix"
    ];
  };
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  age.secrets = {
    "hermes-env" = {
      file = ../../../secrets/hermes-env.age;
      owner = "hermes";
    };
    "sayori-git-token" = {
      file = ../../../secrets/sayori-git-token.age;
      owner = "hermes";
    };
    "serper-api-key-hermes" = {
      file = ../../../secrets/serper-api-key.age;
      owner = "hermes";
    };
  };

  nightcord.restic-backup = {
    paths = [ "/var/lib/hermes" ];

    # The live SQLite files are dumped by backupPrepareCommand instead.
    exclude = [
      "${hermesHome}/.git"
      "${hermesHome}/cache"
      "${hermesHome}/sandboxes"
      "${hermesHome}/pending_messages"
      "${hermesHome}/models_dev_cache.json"
      "${hermesHome}/models_dev_cache.etag"
      "${hermesHome}/state.db*"
      "${hermesHome}/kanban.db*"
      "${hermesHome}/shared-state.db*"
      "${hermesHome}/cron/executions.db*"
    ];

    backupPrepareCommand = ''
      rm -rf ${resticDumpDir}
      mkdir -p ${resticDumpDir}
      ${dumpSqlite}
    '';
    backupCleanupCommand = "rm -rf ${resticDumpDir}";
  };

  systemd.services."restic-backups-${config.nightcord.restic-backup.name}".path = [
    pkgs.coreutils
    pkgs.sqlite
  ];

  users.users.cuso4d.extraGroups = [ "hermes" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/Documents 0750 hermes hermes -"
  ];

  systemd.services.hermes-agent.serviceConfig.BindReadOnlyPaths = [
    "/home/cuso4d/Documents/logseq:/var/lib/hermes/Documents/logseq"
  ];

  services.hermes-agent = {
    enable = true;
    package = hermesPackage;
    addToSystemPackages = true;
    environmentFiles = [ config.age.secrets."hermes-env".path ];
    extraPackages = [
      (pkgs.writeShellScriptBin "gh" ''
        export GH_TOKEN="$(cat ${config.age.secrets."sayori-git-token".path})"
        exec ${pkgs.gh}/bin/gh "$@"
      '')
      pkgs.typst
      (pkgs.writeShellScriptBin "python3" ''
        exec ${hermesPackage.passthru.hermesVenv}/bin/python3 "$@"
      '')
    ];
    hermesHomeFiles."scripts/sayori-sync.sh" = ./sayori-sync.sh;

    environment = {
      HERMES_TIMEZONE = "Asia/Tokyo";
      HTTP_PROXY = "http://127.0.0.1:20172";
      HTTPS_PROXY = "http://127.0.0.1:20172";
      TELEGRAM_PROXY = "http://127.0.0.1:20172";
      NO_PROXY = "127.0.0.1,localhost,::1,api.deepseek.com,mirrors.ustc.edu.cn,mirrors.tuna.tsinghua.edu.cn";
      TELEGRAM_ALLOWED_USERS = "7058410044";
      TELEGRAM_REQUIRE_MENTION = "true";
      MATRIX_E2EE_MODE = "optional";
      MATRIX_RECOVERY_KEY_OUTPUT_FILE = "/var/lib/hermes/.hermes/matrix-recovery-key.txt";
      MATRIX_REQUIRE_MENTION = "true";
    };

    settings.model = {
      provider = "deepseek";
      default = "deepseek-flash";
    };

    mcpServers.serper = {
      command = "${serper-mcp}/bin/serper-mcp";
      args = [ ];
    };
  };
}
