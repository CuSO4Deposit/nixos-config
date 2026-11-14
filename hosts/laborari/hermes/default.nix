{
  config,
  inputs,
  pkgs,
  ...
}:
let
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
    "serper-api-key-hermes" = {
      file = ../../../secrets/serper-api-key.age;
      owner = "hermes";
    };
  };

  nightcord.restic-backup.paths = [ "/var/lib/hermes" ];

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
      pkgs.gh
      pkgs.typst
      (pkgs.writeShellScriptBin "python3" ''
        exec ${hermesPackage.passthru.hermesVenv}/bin/python3 "$@"
      '')
    ];

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
