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
      env = {
        vars = {
          ZOTERO_API_KEY_FILE = "/run/agenix/zotero-api-key";
          ZOTERO_USER_ID_FILE = "/run/agenix/zotero-user-id";
        };
      };
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
              id = "glm-5";
              name = "glm-5";
            }
            {
              id = "qwen3.5-plus";
              input = [
                "text"
                "image"
              ];
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
          primary = "bailian/glm-5";
          fallbacks = [
            "bailian/qwen3.5-plus"
            "bailian/qwen3-max-2026-01-23"
            "bailian/qwen-vl-max"
          ];
        };
        compaction.mode = "safeguard";
      };

      skills = {
        load = {
          extraDirs = [
            "~/.openclaw/data/workspace-yoshino/skills/arxiv-summarizer/skills"
            "~/.openclaw/data/workspace-yoshino/skills/knowledge-archiver/skills"
            "~/.openclaw/data/workspace-yoshino/skills/zotero"
            "~/.openclaw/data/workspace/skills/caldav-calendar"
            "~/.openclaw/data/workspace/skills/miniflux-news"
            "~/.openclaw/data/workspace/skills/logseq-todo"
          ];
          watch = true;
        };
        entries = {
          "arxiv-search-collector" = {
            enabled = true;
          };
          "arxiv-search-processor" = {
            enabled = true;
          };
          "arxiv-search-reporter" = {
            enabled = true;
          };
          "arxiv-summarizer-orchestrator" = {
            enabled = true;
          };
          "arxiv-paper-processor" = {
            enabled = true;
          };
          "arxiv-batch-reporter" = {
            enabled = true;
          };
          "archive-knowledge" = {
            enabled = true;
          };
          "zotero" = {
            enabled = true;
          };
        };
      };

      tools = {
        web.fetch = {
          enabled = false;
          maxChars = 50000;
          timeoutSeconds = 30;
        };
        web.search = {
          enabled = false;
          maxResults = 5;
        };
        media.models = [
          {
            provider = "modelscope";
            model = "Qwen/Qwen3.5-397B-A17B";
          }
        ];
      };

      browser = {
        enabled = true;
        executablePath = "/etc/profiles/per-user/cuso4d/bin/google-chrome";
        headless = true;
      };

      commands = {
        native = "auto";
        nativeSkills = "auto";
        restart = false;
        ownerDisplay = "raw";
      };

      channels.telegram = {
        enabled = true;
        dmPolicy = "pairing";
        proxy = "http://127.0.0.1:20172";
        groups."-1003886118286" = {
          enabled = true;
          groupPolicy = "open";
          requireMention = true;
        };
        allowFrom = [ 7058410044 ];
        groupPolicy = "allowlist";
        streaming = "partial";
        accounts = {
          sayori = {
            "dmPolicy" = "pairing";
            "tokenFile" = "/run/agenix/telegram-bot-token";
            "groupPolicy" = "allowlist";
          };
          yoshino = {
            "dmPolicy" = "pairing";
            "tokenFile" = "/run/agenix/telegram-bot-token-yoshino";
            "groupPolicy" = "allowlist";
          };
          default = {
            "dmPolicy" = "pairing";
            "allowFrom" = [
              7058410044
            ];
            "groupPolicy" = "allowlist";
            "streaming" = "partial";
          };
        };
      };

      agents.list = [
        {
          id = "sayori";
          default = true;
          workspace = "/home/cuso4d/.openclaw/data/workspace";
        }
        {
          id = "yoshino";
          workspace = "/home/cuso4d/.openclaw/data/workspace-yoshino";
        }
      ];

      bindings = [
        {
          agentId = "sayori";
          match = {
            channel = "telegram";
            accountId = "sayori";
          };
        }
        {
          agentId = "yoshino";
          match = {
            channel = "telegram";
            accountId = "yoshino";
          };
        }
      ];

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
    gh # GitHub Skill
    google-chrome # Browser Tool
    khal # caldav-calendar Skill
    python314 # Zotero Skill
    vdirsyncer # caldav-calendar Skill
  ];
}
