vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.cmd.colorscheme("bark")

require("config.options")
require("config.pack")
require("config.statusline")
require("config.find")
require("config.completion")
require("config.update")

-- Per-plugin setup lives in plugin/*.lua, sourced by Nvim after this file.
