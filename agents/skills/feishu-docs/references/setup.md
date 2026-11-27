# Feishu CLI Setup

Read this reference only when `lark-cli` is not installed, app configuration is
missing, or authentication or permissions fail.

The NixOS configuration declares the CLI package and the required Feishu skills.
Runtime credentials and OAuth tokens remain outside the Nix store.

## Install

On a declaratively managed machine, `lark-cli` comes from `pkgs.lark-cli`.
Confirm it is available:

```bash
lark-cli --version
```

For a machine outside this Nix configuration, the upstream installation
command is:

```bash
npx @larksuite/cli@latest install
```

On NixOS without global Node, use:

```bash
nix shell nixpkgs#nodejs -c npx @larksuite/cli@latest install
```

The bundled `scripts/lark-cli` wrapper can also find a native binary installed
under the local npm prefix.

## First Configuration

Initialize the app interactively:

```bash
lark-cli config init --new
```

The command normally opens or prints a Feishu Open Platform URL. Give the URL
to the user without changing it. In the browser, the user needs to:

1. sign in to the Feishu organization that owns the documents;
2. allow the CLI to create a self-built app, or select an existing app;
3. include the user in the app's availability scope;
4. enable and approve Feishu Docs and Drive API scopes;
5. publish the app version if the organization requires it.

Do not ask the user to paste an App Secret into chat. Prefer the interactive
configuration, or use `lark-cli profile add --app-id <id>
--app-secret-stdin` with a secret supplied through stdin.

### Existing Agent Workspace

`lark-cli` refuses `config init` inside OpenClaw or Hermes Agent contexts so it
does not accidentally create a duplicate app. First inspect the error:

- `FEISHU_APP_ID not found`: the existing agent has no Feishu app to reuse.
  `config bind` cannot solve it. Ask the user to confirm creation of a separate
  app, then run `lark-cli config init --new --force-init`.
- An existing app is available: ask the user to confirm both reuse and identity
  mode before `lark-cli config bind --source hermes --identity user-default`.
  Do not choose a bot-only binding when the task is to read the user's own
  documents.

Binding and force-initializing are configuration writes. Never add
`--force-init` merely to make an error disappear.

## User Authorization

Use user authorization for documents in the user's own Feishu space:

```bash
lark-cli auth login --domain docs,drive --no-wait --json
lark-cli auth status --json --verify
lark-cli whoami
```

Then pass `--as user` on every document operation.

`--no-wait --json` is intended for agent-driven authorization. Take
`verification_url` from the output, show it to the user unchanged, and wait for
the user to confirm successful authorization before consuming the returned
device code:

```bash
lark-cli auth login --device-code <DEVICE_CODE>
```

If the user is operating the terminal directly, `lark-cli auth login
--domain docs,drive` is the shorter interactive form. If a verification URL is
shown in an agent interface, `lark-cli auth qrcode <URL> --output
<relative-path>` can generate a QR code.

## Missing or Invalid Permissions

Classify the failure before changing the app:

- `missing_scopes`: the app lacks API scopes. Open `console_url`, enable the
  named permissions, get administrator approval, and publish a new app version.
- `invalid_grant`, expired code, or expired token: run the authorization again.
- A document read/edit permission error while using user identity: the user
  account lacks access to that document. Ask its owner to grant the user access.
- A bot identity sees no personal documents: use `--as user`. The bot's visible
  drive is the app's own drive.
- `refresh_token_issued: false`: the user grant may expire in about two hours.
  An app administrator must enable refresh of `user_access_token`, publish a
  new app version, and then the user must authorize again.

After fixing app scopes, run `auth login` again so the new user grant includes
them. Do not try to solve user-resource access by running `auth login` for a
bot; bot scopes are managed in the developer console.

## Verify

```bash
LARKSUITE_CLI_NO_UPDATE_NOTIFIER=1 \
  LARKSUITE_CLI_NO_SKILLS_NOTIFIER=1 \
  lark-cli auth status --json --verify
lark-cli whoami
lark-cli docs --help
```

The effective identity must be `user` before accessing personal documents.
