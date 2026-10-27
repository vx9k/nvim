-- conform.nvim is set up on the first write instead of at startup.
local function setup()
	require("conform").setup({
		formatters_by_ft = {
			lua = { "stylua" },
			c = { "clang-format" },
			markdown = { "panache" },
		},
	})
	setup = function() end
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("config.format", {}),
	callback = function(ev)
		setup()
		require("conform").format({
			bufnr = ev.buf,
			timeout_ms = 1000,
			lsp_format = "prefer",
		})
	end,
})
