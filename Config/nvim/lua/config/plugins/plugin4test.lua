local vim = vim

return {
	{
		"folke/twilight.nvim",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},

	{
		"DreamMaoMao/yazi.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"mateusbraga/vim-spell-pt-br",
	},
	{
		"Pocco81/true-zen.nvim",
		config = function()
			require("true-zen").setup({})
		end,
	},
	{
		"gbprod/yanky.nvim",
		dependencies = { { "kkharji/sqlite.lua", enabled = not jit.os:find("Windows") } },

		keys = {
			{
				"<leader>y",
				function()
					require("telescope").extensions.yank_history.yank_history({})
				end,
				desc = "Open Yank History",
			},
		},
		opts = {
			{
				highlight = { timer = 200 },
				ring = { storage = jit.os:find("Windows") and "shada" or "sqlite" },
			},
		},
	},
	{
		"LudoPinelli/comment-box.nvim",
		config = function()
			require("comment-box").setup({
				doc_width = 40, -- width of the document
				box_width = 40, -- width of the boxes
			})
		end,
	},
	{
		"carbon-steel/detour.nvim",
		config = function()
			vim.keymap.set("n", "<leader>w", ":Detour<cr>")
		end,
	},
}
