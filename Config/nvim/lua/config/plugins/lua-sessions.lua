return {
	"rmagatti/auto-session",
	keys = {
		-- {
		-- 	"<leader>os",
		-- 	function()
		-- 		require("auto-session.session_lens").search_session()
		-- 	end,
		-- 	desc = "Open Sessions",
		-- },
	},
	config = function()
		require("auto-session").setup({
			log_level = vim.log.levels.ERROR,
			auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
			auto_session_use_git_branch = false,
			auto_session_enable_last_session = false,
			session_lens = {
				buftypes_to_ignore = {},
				load_on_setup = true,
				theme_conf = { border = true },
				previewer = false,
			},
		})
		vim.keymap.set("n", "<leader>os>", require("auto-session.session-lens").search_session, {
			noremap = true,
		})
	end,
}
