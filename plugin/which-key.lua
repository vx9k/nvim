-- Loaded once the UI is up (lazy.nvim's "VeryLazy").
local function load()
	vim.cmd.packadd("which-key.nvim")
	require("which-key").setup({})
	load = function() end
end

vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function() vim.schedule(load) end,
})

vim.keymap.set("n", "<leader>?", function()
	load()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
