# Feishu Document Workflows

Read this reference before fetching, creating, or editing a Feishu document.

## Supported Inputs

`lark-cli docs` accepts document URLs such as:

```text
https://example.feishu.cn/docx/<document_id>
https://example.feishu.cn/wiki/<node_token>
```

Knowledge-base document links are supported when the signed-in user has access
to that wiki node. Spreadsheet and Bitable data are separate domains.

## Read

Fetch the current document:

```bash
lark-cli docs +fetch \
  --doc "<URL or token>" \
  --doc-format markdown \
  --as user
```

Use the default simple detail for summaries. Before modifying structure, fetch
block IDs with `--detail with-ids` or `--detail full`.

For a large document, start with the outline:

```bash
lark-cli docs +fetch \
  --doc "<URL or token>" \
  --scope outline \
  --max-depth 3 \
  --as user
```

Then read the relevant section or search for a phrase:

```bash
lark-cli docs +fetch \
  --doc "<URL or token>" \
  --scope section \
  --start-block-id "<block-id>" \
  --detail with-ids \
  --as user

lark-cli docs +fetch \
  --doc "<URL or token>" \
  --scope keyword \
  --keyword "old text|another phrase" \
  --detail with-ids \
  --as user
```

## Create

When the user supplies complete content, prefer Markdown:

```bash
lark-cli docs +create \
  --doc-format markdown \
  --content - \
  --as user < ./draft.md
```

Or use a workspace-relative file:

```bash
lark-cli docs +create \
  --doc-format markdown \
  --content @./draft.md \
  --as user
```

The result contains `document.document_id` and `document.url`. Return the URL
to the user. Use `--parent-token` only when the user specified a destination
folder or wiki node.

For semantically authored Feishu content, the CLI's native default is XML.
Read the installed `lark-doc` skill or run `lark-cli docs +create --help` before
using advanced XML elements. Do not mix a complete XML document with Markdown.

## Edit

The user's requested change is the authorization to apply that change. Keep it
scoped to the exact target and read the latest document first.

Append content:

```bash
lark-cli docs +update \
  --doc "<URL or token>" \
  --command append \
  --content "<p>New final paragraph</p>" \
  --as user
```

Replace a unique text fragment:

```bash
lark-cli docs +update \
  --doc "<URL or token>" \
  --command str_replace \
  --pattern "old text" \
  --content "new text" \
  --as user
```

For structural edits, fetch block IDs, change only the necessary blocks, and
discard those IDs after writing:

```bash
lark-cli docs +update \
  --doc "<URL or token>" \
  --command block_replace \
  --block-id "<block-id>" \
  --content "<p>Replacement paragraph</p>" \
  --as user

lark-cli docs +update \
  --doc "<URL or token>" \
  --command block_insert_after \
  --block-id "<anchor-block-id>" \
  --content "<h2>New section</h2><p>Section content</p>" \
  --as user
```

Use `overwrite` only after explicit confirmation because it can remove comments
and resource blocks. Deleting blocks, changing sharing permissions, and
transferring ownership also require explicit user confirmation.

## Verify a Write

Inspect the CLI result for `ok`, `warnings`, and `result`. Unless the user asked
to replace the entire document, fetch the affected section or the whole
document again and confirm the new content is present. Do not claim success
based only on a model-generated edit description.
