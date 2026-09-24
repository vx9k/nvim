return {
	"junnplus/lsp-setup.nvim",
	lazy = false,
	dependencies = {
		{
			"mason-org/mason.nvim",
			opts = {
				max_concurrent_installers = jit.os:find("Windows")
						and (vim.uv.available_parallelism() * 2)
					or nil,
				pip = { upgrade_pip = true },
			},
		},
		{
			"neovim/nvim-lspconfig",
			config = function()
				vim.lsp.config("revo", {
					cmd = { "revo", "lsp" },
					filetypes = { "revo" },
					root_markers = { "lib.json", "exe.json", ".git" },
				})
				vim.lsp.enable("revo")
			end,
		},
	},
	config = function()
		require("lsp-setup").setup({
			inlay_hints = {
				enabled = true,
			},
			servers = {
				clangd = {},
				zls = {
					settings = {
						zls = {
							enable_inlay_hints = true,
							inlay_hints_show_builtin = true,
							inlay_hints_exclude_single_argument = true,
							inlay_hints_hide_redundant_param_names = false,
							inlay_hints_hide_redundant_param_names_last_token = false,
						},
					},
				},
			},
		})
	end,
}
