return {
	{
		"barreiroleo/ltex_extra.nvim",
		ft = { "markdown", "tex" }, -- Especifica os tipos de arquivos
		dependencies = { "neovim/nvim-lspconfig" }, -- LSP necessário
		config = function()
			local function add_word_to_dictionary()
				local params = vim.lsp.util.make_position_params()
				vim.lsp.buf.execute_command({
					command = "_ltex.addToDictionary",
					arguments = { params.textDocument.uri, vim.fn.expand("<cword>") }, -- Palavra sob o cursor
				})
			end

			-- Mapeamento da tecla 'aw' no modo normal
			vim.api.nvim_set_keymap("n", "aw", function()
				add_word_to_dictionary()
			end, { noremap = true, silent = true, desc = "Adicionar palavra ao dicionário do LTeX" })

			local capabilities = require("cmp_nvim_lsp").default_capabilities() -- Para autocompletar avançado (se estiver usando nvim-cmp)
			require("ltex_extra").setup({

				server_opts = {
					capabilities = capabilities,
					settings = {
						ltex = {
							language = "pt-BR", -- Idioma principal (pode ser ajustado)
							additionalLanguages = { "pt-BR" }, -- Idiomas extras
							dictionary = {
								["en-US"] = { "customword" },
								["pt-BR"] = { "exemplo", "latex" },
							},
							disabledRules = {
								["en-US"] = { "PROFANITY" }, -- Regras desativadas em inglês
								["pt-BR"] = { "TIPO", "ACENTUACAO" }, -- Regras desativadas em português
							},
							hiddenFalsePositives = {},
						},
					},
				},
			})
		end,
	},

	-- {
	-- 	"charlesneimog/ltextra.nvim",
	-- 	-- dir = "~/Documents/Git/ltextra.nvim",
	-- 	keys = {
	-- 		{
	-- 			"aw",
	-- 			function()
	-- 				require("ltextra.actions").add_word()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Add word to dictionary",
	-- 		},
	-- 		{
	-- 			"dr",
	-- 			function()
	-- 				require("ltextra.actions").disable_rule()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Disable rule",
	-- 		},
	-- 		{
	-- 			"ic",
	-- 			function()
	-- 				require("ltextra.actions").ignore_command()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Ignore Command",
	-- 		},
	-- 		{
	-- 			"<leader>hf",
	-- 			function()
	-- 				require("ltextra.actions").hidden_false_positive()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Hide False Positives",
	-- 		},
	-- 		{
	-- 			"<leader>r",
	-- 			function()
	-- 				require("ltextra.actions").print_rule_under_cursor()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Print Rule Under Cursor",
	-- 		},
	-- 	},
	-- 	event = "BufRead *.tex",
	-- 	config = function()
	-- 		require("ltextra").setup({
	-- 			language = "pt-BR",
	-- 		})
	-- 	end,
	-- },
}
