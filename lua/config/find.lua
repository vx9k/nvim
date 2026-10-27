-- Telescope replacement built on |:find|, |:grep| and |:buffer|.
--
-- 'findfunc' feeds :find a fuzzy-matched list from fd (or rg). The list is
-- cached while the command line is open and dropped when it closes, so new
-- files show up next time without rescanning on every keystroke.

local M = {}

local files

local function list_files()
	if vim.fn.executable("fd") == 1 then
		return vim.fn.systemlist({
			"fd",
			"--type",
			"f",
			"--hidden",
			"--exclude",
			".git",
		})
	elseif vim.fn.executable("rg") == 1 then
		return vim.fn.systemlist({ "rg", "--files", "--hidden", "--glob", "!.git" })
	end
	return vim.fn.glob("**/*", false, true)
end

function M.find(arg, _)
	files = files or list_files()
	if arg == "" then return files end
	return vim.fn.matchfuzzy(files, arg)
end

vim.o.findfunc = "v:lua.require'config.find'.find"

vim.api.nvim_create_autocmd("CmdlineLeave", {
	group = vim.api.nvim_create_augroup("config.find", {}),
	callback = function() files = nil end,
})

vim.keymap.set("n", "<leader>ff", ":find ", { desc = "Find file" })
vim.keymap.set("n", "<leader>fg", ":grep ", { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", ":buffer ", { desc = "Find buffer" })
vim.keymap.set("n", "<leader>fh", ":help ", { desc = "Find help" })

return M
