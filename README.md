# nvim

you need the tree-sitter CLI to compile the grammars/parsers. no rust toolchain
anymore, completion is the built-in one.

i also suggest having zip, tar, etc, most systems prepackage this so i didn't
really worry about it

i suggest using fswatch or inotify-tools to have active file reloading
detection, it's useful for LSPs that implement `workspace/didChangeWatchedFiles`

## layout

plugins are managed by the built-in `vim.pack` (nvim 0.12+), no plugin manager
plugin.

- `init.lua`: leader, colorscheme, then the modules below
- `lua/config/pack.lua`: every plugin plus build hooks (`PackChanged`)
- `lua/config/statusline.lua`: native statusline (replaced lualine)
- `lua/config/find.lua`: `:find`/`:grep` with fuzzy `findfunc` (replaced
  telescope)
- `lua/config/completion.lua`: built-in insert/cmdline autocompletion
  (replaced blink.cmp)
- `lua/config/update.lua`: daily background `vim.pack.update()`, builds, and a
  lockfile commit; `:PackUpdate` runs it now
- `plugin/*.lua`: per-plugin setup, sourced by nvim on startup

`nvim-pack-lock.json` pins every plugin revision; keep it committed.

to review updates by hand instead: `:lua vim.pack.update()`, then `:write`.
