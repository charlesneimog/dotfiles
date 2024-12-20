local vim = vim

return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim", -- Mason is a build tool for Neovim plugins
			-- "j-hui/fidget.nvim", -- A minimal, distraction-free statusline for Neovim
			"folke/neodev.nvim", -- Neovim development environment
			"L3MON4D3/LuaSnip",
			"lewis6991/foldsigns.nvim", --
		},

		keys = {
			{
				"<leader>rn",
				function()
					vim.lsp.buf.rename()
				end,
				mode = "n",
				desc = "[R]ename [N]ode",
			},
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
				-- tsserver = {},
			}

			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_installation = true,
			})
			mason_lspconfig.setup_handlers({
				function(server_name)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
						on_attach = on_attach, --
						settings = servers[server_name],
					})
				end,
			})

			local cmp_nvim_lsp = require("cmp_nvim_lsp")

			require("lspconfig").ltex.setup({
				autostart = false,
				filetypes = { "markdown", "tex", "txt" }, -- Add other filetypes you want ltex to handle
			})
			require("lspconfig").clangd.setup({
				on_attach = on_attach,
				capabilities = cmp_nvim_lsp.default_capabilities(),
				cmd = {
					"clangd",
					"--offset-encoding=utf-16",
				},
			})
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
