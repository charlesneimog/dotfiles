return {
	"LintaoAmons/bookmarks.nvim",
	dependencies = {
		{ "kkharji/sqlite.lua" },
		{ "nvim-telescope/telescope.nvim" },
		{ "stevearc/dressing.nvim" }, -- optional: better UI
	},
	keys = {
		{
			"mm",
			"<cmd>BookmarksMark<cr>",
			mode = { "n" },
			desc = "Mark current line into active BookmarkList.",
		},
		{
			"mo",
			"<cmd>BookmarksGoto<cr>",
			mode = { "n" },
			desc = "Go to bookmark at current active BookmarkList",
		},
		{
			"ma",
			"<cmd>BookmarksCommands<cr>",
			mode = { "n" },
			desc = "Find and trigger a bookmark command.",
		},
		{
			"md",
			function()
				require("bookmarks.commands").delete_mark_of_current_file()
			end,
			mode = { "n" },
			desc = "Booksmark Clear Line",
		},
	},
	event = "BufEnter",

	config = function()
		local opts = {
			keymap = {
				telescope = {
					n = {
						quit = { "q", "<ESC>" },
						delete_mark = "d",
						clear_marks = "c",
					},
				},
			},
			signs = {
				mark = {
					icon = "󰃁",
					color = "red",
					line_bg = "#ffffff",
				},
			},
		}
		require("bookmarks").setup(opts)
	end,
}

-- run :BookmarksInfo to see the running status of the plugin
