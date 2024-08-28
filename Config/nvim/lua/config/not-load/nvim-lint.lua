local vim = vim

return {
	"mfussenegger/nvim-lint",
	config = function()
		local lint = require("lint")
		local chktex = lint.linters.chktex
		chktex.ignore_exitcode = true
		lint.linters_by_ft = {
			javascript = { "eslint" },
			html = { "htmlhint" },
			c = { "clangtidy" },
			lua = { "luacheck" },
			tex = { "chktex" },
		}
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
