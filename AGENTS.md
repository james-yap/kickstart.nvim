# Agent notes — kickstart.nvim fork

This is a personal fork of [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
Goal: keep `init.lua` merge-friendly with upstream while housing preferences under `lua/custom/`.

**Upstream diff:** https://github.com/nvim-lua/kickstart.nvim/compare/master...james-yap:kickstart.nvim:master

## Rules of thumb

1. **Prefer `lua/custom/` over editing mid-file `init.lua`.**
2. **Do not edit `lua/kickstart/plugins/*` for personal tweaks.** Override afterward from `lua/custom/`.
3. **Machine-specific lists stay gitignored** (seeded from tracked `*.example` files).
4. **When in doubt, leave upstream text in place** and apply overrides later via a second `setup()` / keymap set / `require`.
5. **If unsure or ambiguous, ask the user** before changing structure or defaults.

## Layout

```
init.lua                      # stay close to upstream
lua/custom/
  init.lua                    # single entrypoint (SECTION 10: require 'custom')
  options.lua                 # late options / colorscheme / statusline
  telescope.lua               # telescope defaults + personal pickers
  keymaps.lua                 # personal keymaps
  lsp_servers.lua             # gitignored — servers, tools, optional mason_skip
  lsp_servers.lua.example     # tracked seed
  plugins/
    init.lua                  # seeds format.lua, then requires each *.lua plugin
    format.lua                # gitignored — conform format_on_save + formatters_by_ft
    format.lua.example        # tracked seed
    indent.lua                # ibl prefs after kickstart indent_line
    *.lua                     # personal plugins
```

### Load order (`lua/custom/init.lua`)

1. Optional kickstart examples (`indent_line`, `autopairs`, `gitsigns`) — keep those lines **commented** in upstream SECTION 10
2. `custom.plugins` (format seed + personal plugins + ibl override)
3. `custom.options`
4. `custom.telescope`
5. `custom.keymaps`

## What may stay in `init.lua`

| Change | Why |
| --- | --- |
| OSC 52 `vim.g.clipboard = 'osc52'` under `SSH_CONNECTION` | Must run **early** in SECTION 1, before clipboard provider selection. Do **not** move to end-loaded `custom/options.lua`. |
| LSP seed + `require 'custom.lsp_servers'` + `tools` / `mason_skip` filter | Per-machine server/tool lists |
| Conform base install + `notify_on_error` / `default_format_opts` + `<leader>f` | Shared base only |
| `require 'custom'` in SECTION 10 | Single personal entrypoint (upstream comments stay; only this line active) |

### SECTION 7 (formatting) — important

- **Do not** copy upstream’s empty `format_on_save` into the first `conform.setup()` if a later personal setup will own format-on-save.
- First setup: base defaults only (no per-machine filetypes/formatters, no seed).
- `lua/custom/plugins/init.lua` seeds `format.lua` from `format.lua.example`, then loads it.
- `format.lua` calls a **second** `conform.setup()` with `format_on_save` + `formatters_by_ft` (conform merges tables; autocmd comes from this later setup).

### LSP

- Real LSPs → `servers`; Mason-only tools → `tools`; optional skips → `mason_skip`.
- `lua_ls` `workspace.library` must be `vim.api.nvim_get_runtime_file('', true)` only.
  - **Never** `vim.tbl_extend('force', runtime_paths, { '${3rd}/luv/library', ... })` — that overwrites array indices 1..n instead of appending.

## Adding personal config

| Want | Put it here |
| --- | --- |
| New plugin | `lua/custom/plugins/<name>.lua` |
| Option / colorscheme / statusline | `lua/custom/options.lua` |
| Telescope ignore patterns or pickers | `lua/custom/telescope.lua` |
| Keymap | `lua/custom/keymaps.lua` |
| Enable a kickstart optional example | `require` it in `lua/custom/init.lua`, leave SECTION 10 commented |
| LSP / Mason tool on this machine | gitignored `lua/custom/lsp_servers.lua` (update `.example` only when the seed baseline should change) |
| Format-on-save / formatters | gitignored `lua/custom/plugins/format.lua` (same for `.example`) |

## Upstream sync

```bash
git fetch upstream
git merge upstream/master   # or rebase
```

Expect conflicts mainly around the intentional `init.lua` hooks above. Resolve by keeping upstream wording where possible and preserving the small personal hooks + `require 'custom'`.

## Do not

- Scatter preferences through SECTION 4/5 of `init.lua` (colorscheme, telescope maps, statusline, etc.)
- Commit gitignored `lsp_servers.lua` / `format.lua`
- “Fix” `lua_ls` library with `tbl_extend` + luv/busted paths
- Move OSC 52 assignment to a late-loaded module
