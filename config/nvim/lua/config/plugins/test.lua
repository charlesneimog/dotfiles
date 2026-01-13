return {
	{
		"karb94/neoscroll.nvim",
		opts = {},
	},
	{ "vuciv/golf" },
	{
		"mcauley-penney/visual-whitespace.nvim",
		event = "ModeChanged *:[vV\22]", -- optionally, lazy load on entering visual mode
		opts = {
			enabled = true,
			highlight = { link = "Visual", default = true },
			match_types = {
				space = true,
				tab = true,
				nbsp = true,
				lead = false,
				trail = false,
			},
			list_chars = {
				space = "·",
				tab = "↦",
				nbsp = "␣",
				lead = "‹",
				trail = "›",
			},
			fileformat_chars = {
				unix = "↲",
				mac = "←",
				dos = "↙",
			},
			ignore = { filetypes = {}, buftypes = {} },
		},
	},
	{
		"lowitea/aw-watcher.nvim",
		opts = {
			aw_server = {
				host = "127.0.0.1",
				port = 5600,
			},
		},
	},
}
