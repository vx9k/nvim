-- Built-in LSP client (|lsp-config|). Server defaults (cmd, filetypes, root
-- markers) for clangd and zls come from nvim-lspconfig's lsp/*.lua files.

vim.lsp.config("revo", {
	cmd = { "revo", "lsp" },
	filetypes = { "revo" },
	root_markers = { "lib.json", "exe.json", ".git" },
})

vim.lsp.config("zls", {
	settings = {
		zls = {
			enable_inlay_hints = true,
			inlay_hints_show_builtin = true,
			inlay_hints_exclude_single_argument = true,
			inlay_hints_hide_redundant_param_names = false,
			inlay_hints_hide_redundant_param_names_last_token = false,
		},
	},
})

vim.lsp.enable({ "clangd", "zls", "revo" })
vim.lsp.inlay_hint.enable(true)

-- Mappings carried over from lsp-setup.nvim, on top of the |lsp-defaults|.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("config.lsp", {}),
	callback = function(ev)
		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		map("gD", vim.lsp.buf.declaration, "Go To Declaration")
		map("gd", vim.lsp.buf.definition, "Go To Definition")
		map("gi", vim.lsp.buf.implementation, "Go To Implementation")
		map("gr", vim.lsp.buf.references, "Go To References")
		map("<C-k>", vim.lsp.buf.signature_help, "Show Signature Help")
		map("<leader>rn", vim.lsp.buf.rename, "Rename")
		map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("<leader>f", vim.lsp.buf.format, "Format Code")
		map("<leader>e", vim.diagnostic.open_float, "Show Diagnostics")
		map(
			"[d",
			function() vim.diagnostic.jump({ count = -1, float = true }) end,
			"Prev Diagnostic"
		)
		map(
			"]d",
			function() vim.diagnostic.jump({ count = 1, float = true }) end,
			"Next Diagnostic"
		)
	end,
})

-- mason.nvim stays unloaded until one of its commands is used. Its only
-- startup effect is putting installed tools on $PATH, which we do directly.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local mason_cmds = {
	"Mason",
	"MasonInstall",
	"MasonLog",
	"MasonUninstall",
	"MasonUninstallAll",
	"MasonUpdate",
}
for _, name in ipairs(mason_cmds) do
	vim.api.nvim_create_user_command(name, function(args)
		for _, c in ipairs(mason_cmds) do
			vim.api.nvim_del_user_command(c)
		end
		vim.cmd.packadd("mason.nvim")
		require("mason").setup({
			max_concurrent_installers = jit.os:find("Windows")
					and (vim.uv.available_parallelism() * 2)
				or nil,
			pip = { upgrade_pip = true },
		})
		vim.cmd(name .. (args.bang and "! " or " ") .. args.args)
	end, { nargs = "*", bang = true })
end
