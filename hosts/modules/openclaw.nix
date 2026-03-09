{ pkgs, ... }:
{
  # Inject API keys and gateway token at runtime via agenix-decrypted env file
  systemd.user.startServices = "sd-switch";

  systemd.user.services.openclaw-gateway = {
    Unit.After = [ "run-agenix.mount" ];
    Install.WantedBy = [ "default.target" ];
    Service.EnvironmentFile = "/run/agenix/openclaw-env";
  };

  programs.openclaw.instances.default = {
    enable = true;
    stateDir = "/home/cuso4d/.openclaw/data";
    workspaceDir = "/home/cuso4d/.openclaw/data/workspace";
    config = {
      secrets.providers.secrets-host.source = "env";

      models.providers = {
        bailian = {
          baseUrl = "https://coding.dashscope.aliyuncs.com/v1";
          apiKey = {
            source = "env";
            provider = "secrets-host";
            id = "BAILIAN_API_KEY";
          };
          auth = "api-key";
          api = "openai-completions";
          models = [
            {
              id = "qwen3.5-plus";
              name = "qwen3.5-plus";
            }
            {
              id = "qwen3-max-2026-01-23";
              name = "qwen3-max-2026-01-23";
            }
          ];
        };

        modelscope = {
          baseUrl = "https://api-inference.modelscope.cn/v1";
          apiKey = {
            source = "env";
            provider = "secrets-host";
            id = "MODELSCOPE_API_KEY";
          };
          auth = "api-key";
          api = "openai-completions";
          models = [
            {
              id = "Qwen/Qwen3.5-397B-A17B";
              name = "Qwen3.5-397B-A17B";
            }
          ];
        };
      };

      agents.defaults = {
        model = {
          primary = "bailian/qwen3.5-plus";
          fallbacks = [ "bailian/qwen3-max-2026-01-23" ];
        };
        compaction.mode = "safeguard";
      };

      tools = {
        web.fetch = {
          enabled = false;
          maxChars = 50000;
          timeoutSeconds = 30;
        };
        media.models = [
          {
            provider = "modelscope";
            model = "Qwen/Qwen3.5-397B-A17B";
          }
        ];
      };

      commands = {
        native = "auto";
        nativeSkills = "auto";
        restart = true;
        ownerDisplay = "raw";
      };

      channels.telegram = {
        enabled = true;
        dmPolicy = "pairing";
        proxy = "http://127.0.0.1:20172";
        tokenFile = "/run/agenix/telegram-bot-token";
        groups."*".requireMention = true;
        allowFrom = [ 7058410044 ];
        groupPolicy = "allowlist";
        streaming = "partial";
      };

      # gateway.auth.token is intentionally absent here.
      # OPENCLAW_GATEWAY_TOKEN is injected at runtime via the systemd drop-in
      # EnvironmentFile pointing to /run/agenix/openclaw-env.
      gateway = {
        mode = "local";
        controlUi.allowedOrigins = [
          "http://localhost:18789"
          "http://127.0.0.1:18789"
        ];
      };
    };
  };

  # For openclaw
  home.packages = with pkgs; [
    gh
  ];
}
