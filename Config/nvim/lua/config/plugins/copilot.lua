-- return {
-- 	"github/copilot.vim",
-- 	event = "InsertEnter",
-- 	config = function()
-- 		-- require("copilot").setup()
-- 	end,
-- }

return {
	{ "AndreM222/copilot-lualine" },
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false, auto_trigger = false },
				panel = { enabled = false },
			})
			-- require("copilot").setup({
			-- 	panel = {
			-- 		enabled = false,
			-- 	},
			-- 	suggestion = {
			-- 		enabled = true,
			-- 		auto_trigger = false,
			-- 	},
			-- })
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		config = function()
			require("copilot_cmp").setup()
		end,
	},
}
