local vim = vim

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim", -- Mason is a build tool for Neovim plugins
			"folke/neodev.nvim", -- Neovim development environment
			"L3MON4D3/LuaSnip",
			"lewis6991/foldsigns.nvim", --
		},
		keys = {
			{
				"<leader>v",
				function()
					vim.diagnostic.open_float()
				end,
				mode = "n",
				desc = "[V]iew [D]iagnostics",
			},
		},
		config = function()
			require("mason").setup()

			vim.diagnostic.config({
				virtual_text = false,
				update_in_insert = true,
				float = {
					border = "rounded",
					source = "always",
				},
			})
			local symbols = { Error = "󰅙 ", Info = "󰋼 ", Hint = "󰌵 ", Warn = " " }
			for name, icon in pairs(symbols) do
				local hl = "DiagnosticSign" .. name
				vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
			end

			local servers = {
				clangd = {
					cmd = {
						"clangd",
						"--offset-encoding=utf-16",
					},
				},
				pyright = {},
				html = {},
				lua_ls = {},
				ltex = {
					autostart = true,
					filetypes = { "markdown", "tex", "txt" },
					settings = {
						ltex = {
							language = "pt-BR",
							diagnosticSeverity = "information",
							additionalRules = {
								enablePickyRules = true,
							},
						},
					},
				},
			}

			-- ??
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_installation = true,
			})

			for server_name, _ in pairs(servers) do
				require("lspconfig")[server_name].setup({
					capabilities = capabilities,
					on_attach = on_attach, --
					settings = servers[server_name],
				})
			end
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = "williamboman/mason.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"prettier",
					"stylua",
					"isort",
					"black",
					"clang-format",
					"yamlfmt",
					"shfmt",
				},
				run_on_start = true,
			})
		end,
	},
}
