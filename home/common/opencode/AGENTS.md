# AGENTS.md

## Environment

- Unless explicitly stated otherwise for the current task, the machine running
  this session is @platform@ with Nix Flakes enabled.
- To use a tool that is not already installed, run it ad hoc with
  `@shellTool@<package> -c <command>` instead of installing it globally.
- If several such tools are needed at once, combine them into a single
  invocation.

## Collaboration

- Other people you collaborate with do not use NixOS.
- Do not introduce NixOS-specific artifacts (e.g. `flake.nix`, `shell.nix`,
  `nix develop`/`nix-shell`), or change shared build/tooling files to depend on
  Nix, unless explicitly asked to.

## Web access

- Never send repeated automated requests to a website. Do not wrap
  `curl`/`wget`/`http` calls in a `for`/`while` loop, do not brute-force
  URLs, numeric IDs, or endpoints, and do not run load or stress tests.
  This is a DoS attack from the server's perspective and can get the
  machine's IP banned.
- Fetch each page once and follow only directly relevant links. Use search
  and fetch tools for discovery instead of crawling or spidering.
- If a task genuinely requires many sequential requests (e.g. an
  authorized scrape), stop and ask first. Then keep it to one request per
  second, a small total count, and stop immediately on `429`/`403` or a
  `Retry-After` header.
