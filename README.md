# nvim

you do need the rust toolchain, holy bloat... and obviously tree-sitter CLI to
compile the grammars/parsers.

i also suggest having zip, tar, etc, most systems prepackage this so i didn't
really worry about it

i suggest using fswatch or inotify-tools to have active file reloading
detection, it's useful for LSPs that implement `workspace/didChangeWatchedFiles`

## why did you switch back into lazy.nvim?

simple, I enjoy the lazy-system of it, and vim.pack is kinda painful if you want
things to just work with most plugins that have official support for lazy.nvim.
