# AGENTS.md

## Environment

- Unless explicitly stated otherwise for the current task, this session runs on
  the host `@hostname@` (@platform@) with Nix Flakes enabled.
- The user refers to other machines by their short hostname (e.g. `lexikos`,
  `proximo`), you can ssh there.
- To use a tool that is not already installed, run it ad hoc with
  `@shellTool@<package> -c <command>` instead of installing it globally. If
  several such tools are needed at once, combine them into a single invocation.

## Collaboration

- Other people you collaborate with do not use NixOS.
- Do not introduce NixOS-specific artifacts (e.g. `flake.nix`, `shell.nix`,
  `nix develop`/`nix-shell`), or change shared build/tooling files to depend on
  Nix, unless explicitly asked to.

## Web access

- Never send repeated automated requests to a website. Do not wrap
  `curl`/`wget`/`http` calls in a `for`/`while` loop, do not brute-force
  URLs, numeric IDs, or endpoints. The machine's IP may be banned.
- Fetch each page once and follow only directly relevant links. Use search
  and fetch tools / MCPs for discovery instead of crawling or spidering.
- If a task genuinely requires many sequential requests (e.g. an authorized
  scrape), stop and ask first. Then keep it to one request per second, a small
  total count.

## Coding

- Limit the amount of comments you put in the code to a strict minimum. You
  should almost never add comments, except sometimes on non-trivial code,
  function definitions if the arguments aren't self-explanatory, and class
  definitions and their members.
- Reference a name, not a position. Text outlives the code it describes,
  so cite a selector, function, class, pref or flag name; name a file without a
  line, and avoid positional phrasing ("the rule above X").

## Searching

- Prefer `rg` over `grep`.
- Do not search `/nix/store` (e.g. `grep -r`, `rg /nix/store`). It is huge,
  machine-generated, and almost never what you want. Use `nix eval`,
  `nix path-info`, or read the flake input sources instead.
