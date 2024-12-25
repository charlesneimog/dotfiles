local vim = vim

return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },

	config = function()
		local lint = require("lint")

		local linters = {
			javascript = { "eslint" },
			html = { "htmlhint" },
			lua = { "luacheck" },
			python = { "flake8" },
			c = { "clangtidy" },
			cpp = { "clangtidy" },
			tex = { "vale" },
			markdown = { "vale" },
		}

		local mason_lint = {
			clangtidy = "clangd",
			eslint = "eslint_d",
		}

		local mason_registry = require("mason-registry")
		for ft, linter in pairs(linters) do
			local len = #linter
			if len == 1 then
				local mason_name = linter[1]
				if mason_lint[linter[1]] then
					mason_name = mason_lint[linter[1]]
				end

				local package = mason_registry.get_package(mason_name)
				if not package:is_installed() then
					package:install()
					vim.notify("Installing " .. linter[1] .. " for " .. ft .. ". Wait for mason message", "info")
				end
			else
				vim.notify("Multiple formatters for " .. ft .. " not implemented", "info")
			end
		end

		-- fix chktex
		local chktex = lint.linters.chktex
		chktex.ignore_exitcode = true

		lint.linters_by_ft = linters
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
