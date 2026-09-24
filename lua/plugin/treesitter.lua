return {
	"m-demare/hlargs.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			vim.filetype.add({
				extension = {
					rv = "revo",
					revo = "revo",
				},
			})

			local revo_path = vim.fn.stdpath("data")
				.. "/site/parser-src/tree-sitter-revo"

			if vim.fn.isdirectory(revo_path) == 0 then
				vim.fn.system({
					"git",
					"clone",
					"--depth=1",
					"https://codeberg.org/doomy/tree-sitter-revo",
					revo_path,
				})
			end

			vim.api.nvim_create_autocmd("User", {
				pattern = "TSUpdate",
				callback = function()
					require("nvim-treesitter.parsers").revo = {
						install_info = {
							path = revo_path,
						},
					}
				end,
			})

			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			local grammars = {
				"c",
				"lua",
				"asm",
				"linkerscript",
				"revo",
				"markdown",
				"markdown_inline",
				"bash",
				"zig",
			}

			require("nvim-treesitter").install(grammars)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = grammars,
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
				end,
			})
		end,
	},
	lazy = false,
	config = function() require("hlargs").setup() end,
}
