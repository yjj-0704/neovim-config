# AGENTS.md — neovim-config

This repo is a **Neovim Lua config** (not a runtime application, library, or service). There are no tests, no linter, no formatter, no CI, and no build step. Most "how to verify" workflows below are about loading the config and keeping it in sync with the live `~/.config/nvim`.

## What this repo is

Source of truth for the user's Neovim configuration. Files live under `lua/core/` (editor options, keymaps) and `lua/plugins/` (plugin specs merged by `lua/plugins/init.lua`). Plugin manager is **lazy.nvim**, bootstrapped in `init.lua`.

Scope by design:
- Languages supported: **python, java, c, cpp** only (treesitter + LSP). Do not add gopls/rust/etc. unless the user asks.
- No AI completion module. `lua/core/ai.lua` was removed intentionally. Do not reintroduce it.
- Theme is `default`; the user switches it manually in `lua/core/options.lua`.

## Two-location sync (easy to forget)

The repo at `~/code/neovim-config` is the source of truth, but Neovim loads from `~/.config/nvim`. They are **separate copies, not a symlink**. After editing files here:

```bash
# mirror a single file
cp ~/code/neovim-config/init.lua ~/.config/nvim/init.lua

# or mirror everything (after a batch of changes)
rsync -a --delete ~/code/neovim-config/ ~/.config/nvim/
```

There is no install script and no Makefile target that does this — copy/sync manually.

## Verification

No automated tests. To verify the config loads without errors:

```bash
nvim --headless -c 'lua print("init ok")' -c 'qa' ~/.config/nvim/init.lua
```

To verify inside a running nvim: `:Lazy`, `:checkhealth`, `:LspInfo`.

A deprecation warning `nvim-lspconfig support for Nvim 0.10 or older is deprecated` is expected on **NVIM v0.10.4** (the installed version). It is not a regression caused by your edits.

## Layout quick-reference

```
init.lua                      # bootstrap lazy.nvim + require core/*
lua/core/options.lua          # vim.opt.* + mapleader = " "
lua/core/keymaps.lua          # global keymaps (no AI keys)
lua/plugins/init.lua          # merges plugins/*.lua
lua/plugins/cmp.lua           # nvim-cmp (LSP/buffer/path/luasnip)
lua/plugins/lsp.lua           # mason + lspconfig (jdtls/clangd/pyright)
lua/plugins/treesitter.lua    # ensure_installed = python/java/c/cpp, highlight only
```

`lua/plugins/init.lua` uses a `merge(...)` helper that flattens tables — each `return { ... }` in a sibling file must be a list of plugin spec tables (the convention `hrsh7th/nvim-cmp` and friends already follow).

## Conventions specific to this repo

- **Leader key is space** (`vim.g.mapleader = " "`), set in `lua/core/options.lua`. Many keymaps use `<Space>`.
- **No `lazy-lock.json` is committed.** `.gitignore` excludes it intentionally (comment in `.gitignore` documents the opt-in: change to `!lazy-lock.json` to lock versions). Do not commit one unless asked.
- **Branch is `master`** (not `main`). PRs target `master`.
- **Remote**: `https://github.com/yjj-0704/neovim-config.git`.
- When adding a new plugin, append a new file under `lua/plugins/` returning `{ { ... spec ... } }`; it gets picked up automatically by `merge(...)`. Avoid editing `lua/plugins/init.lua` unless you are changing the merge logic itself.
- When adding an LSP server, update both the `ensure_installed` list in `lua/plugins/lsp.lua` **and** the `lspconfig.<name>.setup{...}` block in the same file.

## What an agent is likely to break

- Adding a fifth language to treesitter/LSP without being asked — out of scope.
- Re-adding `core.ai` or AI keymaps — explicitly removed.
- Committing `lazy-lock.json` — gitignored on purpose.
- Editing only `~/.config/nvim/` without mirroring back to the repo — changes get lost on next sync.
- Adding a `package.json` / test runner — none exists; this is not an npm project.
