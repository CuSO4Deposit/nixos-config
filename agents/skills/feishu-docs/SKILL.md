---
name: feishu-docs
description: "Read, create, or edit Feishu/Lark Docs through the official lark-cli, including /docx/ and /wiki/ links, and diagnose CLI authentication or document permission problems."
metadata:
  short-description: "Read and edit Feishu Docs with lark-cli"
---

# Feishu Docs

Use the official `larksuite/cli` package and explicitly act as the signed-in
user. A request to inspect, create, or edit a specific document authorizes that
operation; deletion, overwrite, sharing, permission changes, and ownership
transfer require explicit confirmation for the target document.

## Preflight

1. Find the CLI and inspect authentication. If `lark-cli` is not executable
   on `PATH`, use this skill's `scripts/lark-cli` wrapper:

   ```bash
   cli="./scripts/lark-cli"
   "$cli" --version
   LARKSUITE_CLI_NO_UPDATE_NOTIFIER=1 \
     LARKSUITE_CLI_NO_SKILLS_NOTIFIER=1 \
     "$cli" auth status --json --verify
   "$cli" whoami
   ```

   If `lark-cli` is missing, read
   [references/setup.md](references/setup.md) before installing it.

2. For a personal Feishu document, require an authenticated `user` identity and
   pass `--as user` on every document command. Do not silently use the bot
   identity: it cannot normally see the user's personal drive or documents.

3. If configuration or user authorization is missing, read
   [references/setup.md](references/setup.md). Surface any verification URL
   unchanged and wait for the user to complete the Feishu authorization.

4. Read [references/document-workflows.md](references/document-workflows.md)
   before the first fetch, create, or update in a task. It contains the exact
   commands and the safe editing procedure.

## Operating Rules

- Work with a supplied Feishu `/docx/` or `/wiki/` URL, or a document ID. If
  several documents could match, ask which one to change.
- Read the latest document content before editing. Re-read after every write
  and verify the requested content, structure, and returned URL.
- Keep the smallest useful edit. Never use whole-document `overwrite` unless
  the user explicitly asks to replace the document.
- Treat the successful JSON result as `ok == true` or a zero process exit code.
  A top-level API `code` is not part of the CLI success envelope.
- Never print app secrets, access tokens, refresh tokens, or authorization
  codes. URLs may be shown to the user when the CLI asks them to authorize.
- `docs` handles Feishu documents and knowledge-base nodes. Use the separate
  `sheets` or `base` domains for spreadsheet and Bitable data.
- When the official `lark-doc` and `lark-shared` skills are installed, read
  their relevant reference only for advanced XML authoring, media, history, or
  an unfamiliar permission error.

## Setup and Permission Failures

The two permission layers are both required:

- the Feishu app must have the cloud-document API scopes approved in the
  developer console;
- the signed-in user must be able to access the target document.

With `--as user`, an existing personal document normally needs no separate
"add document app" collaborator entry. A `missing_scopes` error requires app
scope approval; an HTTP/API document-permission error usually means the user
account itself cannot access that document.

Follow CLI-provided `console_url`, `hint`, and `missing_scopes` fields. If a
command exits with code 10 for a high-risk write, stop, show the action and
target to the user, obtain explicit approval, then retry with the confirmation
flag named by the CLI.
