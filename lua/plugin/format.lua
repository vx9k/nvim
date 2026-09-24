return {
	"stevearc/conform.nvim",
	lazy = false,
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			c = { "clang-format" },
			markdown = { "panache" },
		},

		format_on_save = {
			timeout_ms = 1000,
			lsp_format = "prefer",
		},
	},
}
