-- Native 'statusline' replacing lualine, same layout:
--   mode >> branch diagnostics >> file  ...  encoding format filetype
--   << lsp << location
--
-- Rendered by Nvim on redraw instead of on a 16ms timer. The git branch is
-- read from .git/HEAD (no git process) and cached until focus/cwd changes.

local M = {}

local modes = {
	["n"] = { "NORMAL", "Normal" },
	["no"] = { "O-PENDING", "Normal" },
	["v"] = { "VISUAL", "Visual" },
	["V"] = { "V-LINE", "Visual" },
	["\22"] = { "V-BLOCK", "Visual" },
	["s"] = { "SELECT", "Visual" },
	["S"] = { "S-LINE", "Visual" },
	["\19"] = { "S-BLOCK", "Visual" },
	["i"] = { "INSERT", "Insert" },
	["R"] = { "REPLACE", "Replace" },
	["c"] = { "COMMAND", "Command" },
	["r"] = { "PROMPT", "Command" },
	["!"] = { "SHELL", "Terminal" },
	["t"] = { "TERMINAL", "Terminal" },
}

local function set_hl()
	local dark, mid, fg = "#202020", "#3a3a3a", "#b0b0b0"
	local colors = {
		Normal = "#7cafc2",
		Insert = "#a1b56c",
		Visual = "#dc9656",
		Replace = "#ab4642",
		Command = "#f7ca88",
		Terminal = "#86c1b9",
	}
	for name, color in pairs(colors) do
		vim.api.nvim_set_hl(
			0,
			"StlMode" .. name,
			{ fg = dark, bg = color, bold = true }
		)
	end
	vim.api.nvim_set_hl(0, "StlSection", { fg = fg, bg = mid })
end

local branches = {}

local function read(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("*l")
	f:close()
	return s
end

local function branch()
	local buf = vim.api.nvim_get_current_buf()
	local cached = branches[buf]
	if cached then return cached end

	local name = vim.api.nvim_buf_get_name(buf)
	local is_file = name ~= "" and vim.bo[buf].buftype == ""
	local root = vim.fs.root(is_file and name or vim.uv.cwd(), ".git")
	local result = ""
	if root then
		local gitdir = root .. "/.git"
		-- worktrees and submodules use a file pointing at the real git dir
		local link = vim.uv.fs_stat(gitdir).type == "file" and read(gitdir)
		if link then
			local target = link:match("^gitdir:%s*(.-)%s*$")
			gitdir = vim.fs.normalize(vim.fs.joinpath(root, target))
		end
		local head = read(gitdir .. "/HEAD") or ""
		result = head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7)
	end
	branches[buf] = result
	return result
end

local function lsp()
	local names = vim.tbl_map(
		function(c) return c.name end,
		vim.lsp.get_clients({ bufnr = 0 })
	)
	return table.concat(names, ", ")
end

local function esc(s) return (s:gsub("%%", "%%%%")) end

function M.render()
	local mode = modes[vim.api.nvim_get_mode().mode]
		or modes[vim.api.nvim_get_mode().mode:sub(1, 1)]
		or { "NORMAL", "Normal" }

	local left = {}
	local b = branch()
	if b ~= "" then left[#left + 1] = " " .. esc(b) end
	if package.loaded["vim.diagnostic"] then
		local d = vim.diagnostic.status()
		if d ~= "" then left[#left + 1] = d end
	end

	local right = {}
	local enc = vim.bo.fileencoding
	right[#right + 1] = enc ~= "" and enc or vim.o.encoding
	right[#right + 1] = vim.bo.fileformat
	if vim.bo.filetype ~= "" then right[#right + 1] = vim.bo.filetype end

	local clients = esc(lsp())
	local progress = vim.ui.progress_status and vim.ui.progress_status() or ""

	return table.concat({
		"%#StlMode" .. mode[2] .. "# " .. mode[1] .. " ",
		#left > 0 and ("%#StlSection# " .. table.concat(left, " >> ") .. " ") or "",
		"%#StatusLine# %<%f %h%m%r",
		"%=",
		esc(progress) .. " ",
		table.concat(right, " << ") .. " ",
		clients ~= "" and ("%#StlSection# " .. clients .. " ") or "",
		"%#StlMode" .. mode[2] .. "# %l:%c ",
	})
end

set_hl()

local group = vim.api.nvim_create_augroup("config.statusline", {})
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })
vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged", "BufFilePost" }, {
	group = group,
	callback = function() branches = {} end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
	group = group,
	callback = function(ev) branches[ev.buf] = nil end,
})
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach", "LspProgress" }, {
	group = group,
	callback = function() vim.cmd.redrawstatus() end,
})

vim.o.statusline = "%!v:lua.require'config.statusline'.render()"

return M
