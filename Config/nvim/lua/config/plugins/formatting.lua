return {
	"stevearc/conform.nvim",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	config = function()
		local conform = require("conform")
		-- create new command to disaple formating on save
		vim.api.nvim_create_user_command("ToggleFormatOnSave", function()
			conform.setup({
				format_on_save = nil,
			})
		end, {})
		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				markdown = { "prettier" },
				lua = { "stylua" },
				python = { { "isort", "black" } },
				cpp = { "clang-format" },
				c = { "clang-format" },
				yaml = { "yamlfmt" },
				bash = { "shfmt" },
			},
			format_on_save = {
				lsp_fallback = true,
				-- async = true,
				timeout_ms = 5000,
			},
		})
	end,
}
