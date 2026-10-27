vim.filetype.add({
	extension = {
		rv = "revo",
		revo = "revo",
	},
})

local site = vim.fn.stdpath("data") .. "/site"
local revo_path = site .. "/parser-src/tree-sitter-revo"

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

require("nvim-treesitter").setup({ install_dir = site })

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

-- Parser names are not filetype names ("bash" is "sh", "linkerscript" is
-- "ld"), so resolve the language from the filetype when it is set.
local function attach(buf)
	local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
	if not vim.list_contains(grammars, lang) then return end
	if not pcall(vim.treesitter.start, buf, lang) then return end
	vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	vim.bo[buf].formatexpr = "v:lua.require'conform'.formatexpr()"
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("config.treesitter", {}),
	callback = function(ev) attach(ev.buf) end,
})

-- Only touch the installer when a parser is actually missing; checking a few
-- files is far cheaper than letting install() resolve every grammar.
local missing = vim.tbl_filter(
	function(lang) return not vim.uv.fs_stat(site .. "/parser/" .. lang .. ".so") end,
	grammars
)
if #missing > 0 then
	vim.schedule(function()
		if vim.list_contains(missing, "revo") and not vim.uv.fs_stat(revo_path) then
			vim
				.system({
					"git",
					"clone",
					"--depth=1",
					"https://codeberg.org/doomy/tree-sitter-revo",
					revo_path,
				})
				:wait()
		end
		-- Buffers opened before their parser existed get attached afterwards.
		local reattach = vim.schedule_wrap(function()
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) then attach(buf) end
			end
		end)
		require("nvim-treesitter").install(missing):await(reattach)
	end)
end

-- hlargs attaches to already-loaded buffers when enabled, so it can wait.
vim.schedule(function() require("hlargs").setup() end)
