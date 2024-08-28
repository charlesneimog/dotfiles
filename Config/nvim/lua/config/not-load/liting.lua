return {
	"mfussenegger/nvim-lint",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	keys = {
		{
			"<leader>L",
			function()
				lint.try_lint()
			end,
			mode = "n",
			desc = "Toogle [L]int",
		},
	},
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			json = { "jsonlint" },
			python = { "flake8" },
			lua = { "luacheck" },
		}
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
