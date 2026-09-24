return {
	"saghen/blink.cmp",
	dependencies = {
		"saghen/blink.lib",
		"saghen/blink.indent",
		"rafamadriz/friendly-snippets",
	},
	build = function() require("blink.cmp").build():pwait() end,

	opts = {
		keymap = { preset = "super-tab" },

		completion = {
			keyword = { range = "full" },
			accept = {
				dot_repeat = true,
				create_undo_point = true,
				resolve_timeout_ms = 500,
				auto_brackets = {
					enabled = true,
					default_brackets = { "(", ")" },
					override_brackets_for_filetypes = {},
					kind_resolution = {
						enabled = true,
					},
					semantic_token_resolution = {
						enabled = true,
						timeout_ms = 1000,
					},
				},
			},
			menu = {
				draw = {
					align_to = "cursor",
					treesitter = { "lsp" },
				},
			},
			documentation = {
				auto_show = true,
			},
			ghost_text = {
				enabled = true,
			},
		},
		signature = {
			enabled = true,
			trigger = {
				enabled = true,
			},
			window = {
				direction_priority = { "n", "s" },
				treesitter_highlighting = true,
				show_documentation = true,
			},
		},
		sources = { default = { "lsp", "path", "snippets", "buffer" } },
		fuzzy = {
			implementation = "rust",
			sorts = {
				"exact",
				"score",
				"sort_text",
			},
		},
	},
}
