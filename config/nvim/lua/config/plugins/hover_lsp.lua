return {
	{
		"lewis6991/hover.nvim",
		keys = {
			{
				"K",
				function()
					require("hover").hover()
				end,
				desc = "Get hover information",
				mode = { "n", "v" },
			},
		},
		config = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
				end,
				preview_opts = {
					border = "single",
				},
				preview_window = false,
				title = true,
				mouse_providers = {
					"LSP",
				},
				mouse_delay = 1000,
			})
		end,
	},
}
