return {
	"lewis6991/gitsigns.nvim",
	event = "BufEnter",
	keys = {
		{
			"<leader>gb",
			":Gitsigns toggle_current_line_blame<CR>",
			desc = "Preview Hunk",
			mode = "n",
		},
		{
			"<leader>gp",
			":Gitsigns preview_hunk<CR>",
			desc = "Preview Hunk",
			mode = "n",
		},
	},
	config = function()
		require("gitsigns").setup({
			signs = {
				add = { text = "+ " },
				change = { text = "~ " },
				delete = { text = "- " },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
		})
	end,
}
