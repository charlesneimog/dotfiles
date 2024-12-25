return {
	"stevearc/conform.nvim",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
	},
	config = function()
		local conform = require("conform")
		local formatters_by_ft = {
			-- web
			javascript = { "prettier" },
			css = { "prettier" },
			html = { "prettier" },

			-- data
			yaml = { "yamlfix" },
			json = { "prettier" },

			-- scripting
			lua = { "stylua" },
			python = { "black" },
			bash = { "shfmt" },

			-- cmake
			cpp = { "clang-format" },
			c = { "clang-format" },
			cmake = { "cmake_format" },
		}
		local formatters = {}
		local mason_conform = {
			cmake_format = "cmakelang",
		}

		local mason_registry = require("mason-registry")
		for ft, formatter in pairs(formatters_by_ft) do
			local len = #formatter
			if len == 1 then
				local form = formatter[1]
				local mason_name = form
				if mason_conform[form] then
					mason_name = mason_conform[form]
				end

				local package = mason_registry.get_package(mason_name)
				if not package:is_installed() then
					package:install()
					vim.notify("Installing" .. formatter[1] .. " for " .. ft(". Wait for mason message"), "info")
				end

				-- check if conform has the formatter
				if not require("conform").get_formatter_config(package.spec.name) then
					local bin = next(package.spec.bin)
					local prefix = vim.fn.stdpath("data") .. "/mason/bin/"
					formatters[package.spec.name] = {
						command = prefix .. bin,
						args = { "$FILENAME" },
						stdin = true,
						require_cwd = false,
					}
				end
			else
				vim.notify("Multiple formatters for " .. ft .. " not implemented", "info")
			end
		end

		conform.setup({
			formatters_by_ft = formatters_by_ft,
			formatters = formatters,
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 5000,
			},
		})
	end,
}
