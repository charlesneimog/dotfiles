return {
	"numToStr/Comment.nvim",
	lazy = false,
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("Comment").setup({
			mappings = {
				basic = true,
				extra = false,
			},
		})
	end,
}
