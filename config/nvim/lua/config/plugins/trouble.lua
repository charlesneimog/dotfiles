return {
	"folke/trouble.nvim", -- A pretty diagnostics list for Neovim
	event = "VeryLazy",
	config = function()
		require("trouble").setup({
			position = "right",
			width = 50,
		})
	end,
}
