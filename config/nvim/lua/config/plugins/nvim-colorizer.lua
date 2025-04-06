return {
	"brenoprata10/nvim-highlight-colors",
	event = "VeryLazy",
	config = function()
		local c = require("nvim-highlight-colors")
		c.setup({
			render = "virtual",
			virtual_symbol_position = "eol",
			virtual_symbol_suffix = "",
		})
	end,
}
