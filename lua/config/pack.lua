-- Plugin management via the built-in |vim.pack|.
--
-- Plugins marked `data = { lazy = true }` are only appended to 'runtimepath',
-- so require() works but their plugin/ files stay unsourced until something
-- calls `vim.cmd.packadd(name)`. The rest are added with `:packadd!`, so their
-- plugin/ files are sourced during the normal |load-plugins| step.

local gh = function(x) return "https://github.com/" .. x end

local M = {}

-- Build steps that need the plugin (and its dependencies) on disk. Each
-- returns an async task (or nothing). They run after vim.pack.add() or
-- vim.pack.update() returns, because PackChanged fires while dependencies may
-- still be installing.
local builds = {
	["nvim-treesitter"] = function(kind)
		if kind ~= "update" then return end
		vim.cmd.packadd("nvim-treesitter")
		return require("nvim-treesitter").update(nil, { summary = true })
	end,
}

local pending = {}

--- Run builds queued by PackChanged. With `wait`, block until they finish
--- (startup install, background updater); otherwise leave them running.
function M.build_pending(wait)
	for name, kind in pairs(pending) do
		pending[name] = nil
		local task = builds[name](kind)
		if task and wait then
			local ok, err = task:pwait()
			if not ok then
				vim.notify(
					name .. " build failed: " .. tostring(err),
					vim.log.levels.ERROR
				)
			end
		end
	end
end

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if builds[name] and (kind == "install" or kind == "update") then
			pending[name] = kind
			-- A manual vim.pack.update() inside the editor: build without
			-- freezing the UI. Headless callers flush with build_pending(true).
			if vim.v.vim_did_enter == 1 and #vim.api.nvim_list_uis() > 0 then
				vim.schedule(function() M.build_pending(false) end)
			end
		end
	end,
})

vim.pack.add({
	-- ui
	gh("saghen/blink.indent"),

	-- lsp / formatting
	gh("neovim/nvim-lspconfig"),
	{ src = gh("mason-org/mason.nvim"), data = { lazy = true } },
	gh("stevearc/conform.nvim"),

	-- treesitter
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	gh("m-demare/hlargs.nvim"),

	-- ui / navigation
	gh("nvim-tree/nvim-web-devicons"),
	gh("stevearc/oil.nvim"),
	{ src = gh("folke/which-key.nvim"), data = { lazy = true } },
	gh("karnull/switchboard.nvim"),
}, {
	load = function(plug)
		if plug.spec.data and plug.spec.data.lazy then
			vim.opt.rtp:append(plug.path)
		else
			vim.cmd.packadd({ plug.spec.name, bang = true })
		end
	end,
})

if vim.v.vim_did_enter == 0 then M.build_pending(true) end

return M
