local function getCurrentLang()
	local clients = vim.lsp.buf_get_clients(0)
	local ltex_language = "pt-BR"
	for _, client in pairs(clients) do
		if client.name == "ltex" then
			local ltex_settings = client.config.settings
			ltex_language = ltex_settings and ltex_settings.ltex and ltex_settings.ltex.language or "pt-BR"
		end
	end
	return ltex_language
end

return {
	{
		"barreiroleo/ltex_extra.nvim",
		ft = { "markdown", "tex" }, -- Especifica os tipos de arquivos
		dependencies = { "neovim/nvim-lspconfig" }, -- LSP necessário
		keys = {
			{
				"aw",
				function()
					local commands = vim.lsp.commands
					if commands["_ltex.addToDictionary"] then
						local funcAddToDictionary = commands["_ltex.addToDictionary"]
						local ltex_language = getCurrentLang()
						local word = vim.fn.expand("<cword>")
						local args = {
							arguments = {
								{
									words = {
										[ltex_language] = { word },
									},
								},
							},
						}
						funcAddToDictionary(args)
						print("Added word to dictionary: " .. word)
					else
						print("Command _ltex.addToDictionary not found")
					end
				end,
				mode = { "n" },
				desc = "Add word to dictionary",
			},
			{
				"hh",
				function()
					local cursor_pos = vim.api.nvim_win_get_cursor(0)
					local line, _ = cursor_pos[1] - 1, cursor_pos[2]
					local diagnostics = vim.diagnostic.get(0, { lnum = line })
					if #diagnostics == 0 then
						print("No diagnostic under cursor")
						return
					end
					local diagnostic = diagnostics[1]
					local message = diagnostic.message
					local lang = getCurrentLang()
					local commands = vim.lsp.commands
					if commands["_ltex.hideFalsePositives"] then
						local funcHideFalsePositives = commands["_ltex.hideFalsePositives"]
						local args = {
							arguments = {
								{
									falsePositives = {
										[lang] = { message },
									},
								},
							},
						}
						funcHideFalsePositives(args)
						print("Ignored false positive: " .. message .. " (Language: " .. lang .. ")")
					else
						print("Command _ltex.hideFalsePositives not found")
					end
				end,
				mode = { "n" },
				desc = "Ignore rule",
			},
		},

		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
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
}
