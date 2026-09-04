# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A standalone [Home Manager](https://github.com/nix-community/home-manager) flake that manages the user environment for `timch` on a **non-NixOS Ubuntu** machine (no NixOS module layer, no system-level config). There is no application code, no build, no test suite - the "build" is activating a Home Manager generation.

## Commands

```bash
./rebuild.sh          # the only apply loop: symlinks ~/.dotfiles -> repo, then home-manager switch --flake ~/.dotfiles#ubuntu
nix flake update      # bump all inputs (nixpkgs, home-manager) in flake.lock
nix flake update nixpkgs   # bump a single input

# Validate without activating (fast, eval-only - catches Nix syntax/attr errors):
nix eval --raw .#homeConfigurations.ubuntu.activationPackage.drvPath

# Build without activating:
nix build .#homeConfigurations.ubuntu.activationPackage

home-manager generations              # list past generations
/nix/store/<hash>-home-manager-generation/activate   # roll back to one
```

`init.sh` is not executable - it is a comment-only crib sheet for bootstrapping Determinate Nix on a fresh machine.

The eval/build commands always print two warnings that are benign and not worth chasing: `Git tree ... has uncommitted changes` (flakes evaluate the git tree, so any dirty file triggers it) and a `builtins.derivation ... options.json ... without a proper context` warning from Home Manager's own news module.

## Architecture

### Two delivery mechanisms, and why the distinction matters

Config reaches `$HOME` by one of two paths, and which one a file uses determines whether editing it requires a rebuild:

1. **Nix-generated** (`programs.zsh`, `programs.starship`, `programs.git` in `home.nix`) - Home Manager renders the file into the Nix store and symlinks it read-only. Changing it means editing `home.nix` and running `./rebuild.sh`.
2. **Out-of-store symlinks** (`config.lib.file.mkOutOfStoreSymlink`) - `~/.config/nvim`, `~/.config/herdr`, `~/.claude/settings.json`, and the AGENTS.md fan-out point at live files under `~/.dotfiles/home/...`. Edits take effect **immediately, with no rebuild**. This is deliberate: fast-moving configs (Neovim plugins, agent instructions) live here.

The mirror layout under `home/` matches the `$HOME` layout it targets (`home/.config/nvim` -> `~/.config/nvim`).

### The `~/.dotfiles` indirection is load-bearing

`home.nix` hardcodes `dotfiles = "${config.home.homeDirectory}/.dotfiles"` as the symlink target - never the repo's real path. `rebuild.sh` creates `~/.dotfiles -> <repo>` before switching. Moving or renaming the repo checkout without re-running `rebuild.sh` breaks every out-of-store symlink.

### Flake wiring

`flake.nix` pins `nixos-26.05` / `home-manager release-26.05`, has exactly two inputs, and exposes exactly one output: `homeConfigurations."ubuntu"`. All packages live in `home.packages` in `home.nix`; the inline module in `flake.nix` carries only identity and `programs.home-manager.enable`.

### One AGENTS.md, three agents

`home/AGENTS.md` is the single source of global agent instructions, symlinked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.config/opencode/AGENTS.md`. Edit it once; all three pick it up live.

This is self-referential: the global instructions loaded into any agent session in this repo are the very file in the working tree. Editing `home/AGENTS.md` rewrites the instructions the next session will run under, so treat changes to it as a config change, not a docs change.

### Neovim

`home/.config/nvim` is a LazyVim starter. Plugins go in `lua/plugins/*.lua` (one file per plugin, returning a lazy.nvim spec); `lua/config/{options,keymaps,autocmds}.lua` are LazyVim's override hooks and are currently empty. `lazy-lock.json` is committed - commit it after `:Lazy update` so the plugin set stays reproducible. This directory carries its own `.gitignore` and `LICENSE` from the starter template.

## Gotchas

- **Flakes only see git-tracked files.** A brand-new `.nix` file imported by `home.nix` is invisible to `home-manager switch` until `git add`ed. (Out-of-store symlink *contents* are read at runtime and are exempt.)
- **`home.file.".config/wezterm"` points at `home/.config/wezterm`, which does not exist in the repo.** The symlink is created dangling and wezterm runs on stock defaults. Restore the directory or drop the line if touching that area.
- **`home/.config/starship.toml` is dead config.** Starship is configured via `programs.starship.settings` in `home.nix`, which generates `~/.config/starship.toml` itself. Nothing references the checked-in TOML - editing it has no effect.
- **Do not add `wezterm` to `home.packages`.** It is installed from apt (WezTerm's own `apt.fury.io/wez` repo) so it links against the system Mesa/X11 stack. A Nix wezterm on this non-NixOS host cannot find a GL driver and needs either [nixGL](https://github.com/nix-community/nixGL) or an `LD_LIBRARY_PATH` wrapper - and installing both causes a subtle conflict: `~/.nix-profile/bin` precedes `/usr/bin` in `PATH`, while `XDG_DATA_DIRS` puts `/usr/share` first, so the apt `.desktop` entry ends up launching the Nix binary. Home Manager manages the *config* only.
- **Do not add `herdr` to `home.packages` or re-add its flake input.** Herdr ships its own updater (`herdr update`, with `stable`/`preview` channels) that installs to `~/.local/bin/herdr`. That directory precedes `~/.nix-profile/bin` on PATH, so a Nix-built herdr is permanently shadowed and silently never runs - this repo shipped a Nix herdr 0.7.1 that was dead behind a self-installed 0.7.5 for a month. Herdr owns its binary; Home Manager manages only its config. Bootstrap on a new machine is one line in `init.sh`; after that, `herdr update`.
- **Herdr writes runtime state into the repo.** Because `~/.config/herdr` is an out-of-store symlink, logs, `session.json`, `release-notes.json`, and `.plugins.lock` land in the working tree. They are gitignored - do not commit or hand-edit them. Its two live sockets land there too and are absent from `.gitignore`; git skips them because it does not track non-regular files, so do not "fix" that by adding a rule.
- **Agents rewrite `home/.claude/settings.json` under you.** `~/.claude/settings.json` is an out-of-store symlink to that file, so Claude Code writing its own settings (a model change, a new toggle, or just reserializing with reordered keys) shows up as an uncommitted repo diff. Run `git diff` and confirm a change is yours before committing it.
- **`home.stateVersion = "24.11"` is deliberately older than the pinned nixpkgs.** It records the release the profile was first built against and gates backwards-compatible defaults. Do not bump it to match `nixos-26.05`.
- `.claude/settings.local.json` at the repo root is untracked because the user's **global** git ignore (`~/.config/git/ignore`) excludes it, not this repo's `.gitignore`. On another machine it would show up as untracked.
- `programs.git.settings.user` sets a personal identity (`tea24864@gmail.com`) that differs from the account email used elsewhere; that is intentional, not a mistake to "fix".
