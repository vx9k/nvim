-- Deferred: setup only stores config and searches for a project override
-- file, and the :Switchboard command is never needed before the first redraw.
vim.schedule(
	function()
		require("switchboard").setup({
			build_run_config = {
				extension = { "c", "h" },
				cd_root = true,
				commands = {
					run = "make run",
					build = "make",
					debug = "gdb ./bin",
				},
				binds = {
					divide = "I//<Esc>78A=<Esc>o",
					import = "I#include ",
				},
			},
		})
	end
)
