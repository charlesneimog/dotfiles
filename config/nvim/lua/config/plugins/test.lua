return {
	{
		"karb94/neoscroll.nvim",
		opts = {},
	},
	{
		"charlesneimog/Concentrate",
		lazy = false,
		config = function()
			require("focusservice").setup({ port = 7079 })
		end,
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
}
