return {
	"akinsho/toggleterm.nvim", -- Terminal
	event = "VimEnter",

	keys = {
		{
			"<leader>t",
			function()
				vim.cmd(":ToggleTerm size=10 direction=float")
			end,
			mode = { "n", "x", "o" },
			desc = "Toogle [T]erminal",
		},
	},

	config = function()
		require("toggleterm").setup({
			dir = "git_dir",
		})
	end,
}
