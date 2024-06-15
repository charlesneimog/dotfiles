return {
	"chentoast/marks.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("marks").setup({})
		local bg = vim.api.nvim_get_hl_by_name("Normal", true)["background"]
		if bg ~= nil then
			vim.api.nvim_set_hl(0, "MarkSignHL", { fg = "#FF0000", bg = string.format("#%06X", bg) })
		end
	end,
}
