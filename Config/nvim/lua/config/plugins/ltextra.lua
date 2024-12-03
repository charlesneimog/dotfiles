return {
	"charlesneimog/ltextra.nvim",
	-- dir = "~/Documents/Git/ltextra.nvim",
	keys = {
		{
			"aw",
			function()
				require("ltextra.actions").add_word()
			end,
			mode = "n",
			desc = "Add word to dictionary",
		},
		{
			"dr",
			function()
				require("ltextra.actions").disable_rule()
			end,
			mode = "n",
			desc = "Disable rule",
		},
		{
			"ic",
			function()
				require("ltextra.actions").ignore_command()
			end,
			mode = "n",
			desc = "Ignore Command",
		},
		{
			"<leader>hf",
			function()
				require("ltextra.actions").hidden_false_positive()
			end,
			mode = "n",
			desc = "Hide False Positives",
		},
		{
			"<leader>r",
			function()
				require("ltextra.actions").print_rule_under_cursor()
			end,
			mode = "n",
			desc = "Print Rule Under Cursor",
		},
	},
	event = "BufRead *.tex",
	config = function()
		require("ltextra").setup({
			language = "pt-BR",
		})
	end,
}
