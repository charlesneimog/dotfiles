local vim = vim

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
	"micangl/cmp-vimtex",
	{
		"lervag/vimtex",
		ft = { "tex", "latex", "bib" },
		event = { "BufEnter *.tex,*.bib" },
		config = function() end,
	},
	{
		"barreiroleo/ltex_extra.nvim",
		ft = { "markdown", "tex" },
		dependencies = { "neovim/nvim-lspconfig" },
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
				"hh", -- Key mapping
				function()
					local cursor_pos = vim.api.nvim_win_get_cursor(0)
					local line = cursor_pos[1] - 1 -- Adjust because line numbers are 0-based in diagnostics
					local diagnostics = vim.diagnostic.get(0, { lnum = line })

					if #diagnostics == 0 then
						print("No diagnostic under cursor")
						return
					end

					-- Get the first diagnostic and its message
					local diagnostic = diagnostics[1]
					local message = diagnostic.message
					local rule = diagnostic.user_data.ltex and diagnostic.user_data.ltex.rule or "UNKNOWN_RULE"
					local lang = getCurrentLang()

					local commands = vim.lsp.commands
					if commands["_ltex.hideFalsePositives"] then
						local funcHideFalsePositives = commands["_ltex.hideFalsePositives"]
						local args = {
							arguments = {
								{
									falsePositives = {
										[lang] = {
											-- Create the JSON string for the rule and the message
											'{"rule":"'
												.. rule
												.. '","sentence":"^'
												.. vim.fn.escape(message, "\\")
												.. '$"}',
										},
									},
									uri = vim.uri_from_fname(vim.fn.expand("%")), -- Ensure correct URI from the current file
								},
							},
						}
						funcHideFalsePositives(args)
						print(
							"Ignored false positive: " .. message .. " (Language: " .. lang .. ", Rule: " .. rule .. ")"
						)
					else
						-- If the command isn't found, notify the user
						print("Command _ltex.hideFalsePositives not found")
					end
				end,
				mode = { "n" }, -- Normal mode
				desc = "Ignore rule", -- Description for the keymap
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
							additionalLanguages = { "pt-BR", "en-US" }, -- Idiomas extras
							hiddenFalsePositives = {},
						},
					},
				},
			})
		end,
	},
}
