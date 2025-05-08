return {
	"m4xshen/hardtime.nvim",
	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	config = function()
		require("hardtime").setup({
			hint = true,
			hints = {
				["Di"] = {
					message = function()
						local cursor = vim.api.nvim_win_get_cursor(0)
						local col = cursor[2]
						local line = vim.api.nvim_get_current_line()
						local before_cursor = line:sub(1, col)
						if col == 0 or before_cursor:match("^%s*$") then
							return "Consider using 'Shift+c' instead of 'Di'"
						end
						return nil
					end,
					length = 2,
				},
			},
		})
	end,
	opts = {},
}
