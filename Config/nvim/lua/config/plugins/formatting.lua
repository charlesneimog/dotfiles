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

		-- oscofo language
		local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		parser_config.scofo = {
			install_info = {
				url = "/home/neimog/Documents/Git/OScofo/Resources/tree-sitter-scofo",
				files = { "src/parser.c" },
				generate_requires_npm = false,
				requires_generate_from_grammar = false,
			},
			filetype = "scofo.txt", -- if filetype does not match the parser name
		}

		--

		local setup_options = {
			formatters_by_ft = formatters_by_ft,
			formatters = formatters,
			notify_on_error = true,
			format_on_save = {
				timeout_ms = 5000,
				async = true,
				lsp_fallback = function()
					return vim.g.conform_format
				end,
			},
		}

		vim.api.nvim_create_user_command("ToggleFormat", function()
			vim.g.conform_format = not vim.g.conform_format
			if vim.g.conform_format then
				require("conform").setup(setup_options)
				vim.notify("Formatting enabled", "info")
			else
				require("conform").setup({ format_on_save = false })
				vim.notify("Formatting disabled", "info")
			end
		end, {})
		vim.g.conform_format = false
	end,
}
