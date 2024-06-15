local vim = vim

local function mylocation()
	local line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	return string.format("%3d-%-2d", line, total_lines)
end

return {
	"nvim-lualine/lualine.nvim",
	event = "VimEnter",
	config = function()
		local darktheme = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme"):match("dark")
		local mytheme = require("lualine.themes.onedark")
		if darktheme then
			mytheme = require("lualine.themes.onedark")
			mytheme.normal.c.bg = "#303030"
		else
			mytheme = require("lualine.themes.onelight")
			mytheme.normal.c.bg = "#ffffff"
		end

		require("lualine").setup({
			options = {
				theme = mytheme,
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = true,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},
			winbar = {
				lualine_a = { "buffers" },
				lualine_z = { "os.date('%a')", "data", "require'lsp-status'.status()" },
			},
			inactive_winbar = {
				lualine_a = { "buffers" },
				lualine_z = { "os.date('%a')", "data", "require'lsp-status'.status()" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					"branch",
					{
						"diff",
						colored = true,
						symbols = { added = "+", modified = "~", removed = "-" },
						diff_color = {
							added = "DiffAdd", -- Changes the diff's added color
							modified = "DiffChange", -- Changes the diff's modified color
							removed = "DiffDelete", -- Changes the diff's removed color you
						},
					},
					"diagnostics",
				},
				lualine_c = {
					{
						"filename",
						file_status = true, -- Displays file status (readonly status, modified status)
						newfile_status = false, -- Display new file status (new file means no write after created)
						path = 1, -- 0: Just the filename
						shorting_target = 40, -- Shortens path to leave 40 spaces in the window
						symbols = {
							modified = "[+]", -- Text to show when the file is modified.
							readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
							unnamed = "[No Name]", -- Text to show for unnamed buffers.
							newfile = "[New]", -- Text to show for newly created file before first write
						},
					},
				},
				lualine_x = {
					"copilot",
					{
						require("lazy.status").updates,
						cond = require("lazy.status").has_updates,
						-- color = { fg = "#ff9e64" },
					},
					{
						function()
							local client = vim.lsp.get_active_clients()
							-- client and clien ~= 'copilot'
							if client and client[1].name ~= "copilot" then
								local clients = " "
								local numClients = #client
								for i, v in ipairs(client) do
									clients = clients .. v.name
									if i < numClients then
										clients = clients .. ", "
									end
								end
								return clients
							end
							return ""
						end,
						-- color = { fg = "#ff9e64" },
					},
				},
				lualine_z = { mylocation },
			},
		})
		for _, kind in ipairs({ "Add", "Change", "Delete" }) do
			local group = "Diff" .. kind
			local bg = vim.api.nvim_get_hl_by_name("lualine_b_visual", true)["background"]
			local color = ""
			if group == "DiffAdd" then
				color = vim.api.nvim_get_hl_by_name("lualine_a_buffers_active", true)["background"]
			elseif group == "DiffChange" then
				color = "#E1AD0F"
			elseif group == "DiffDelete" then
				color = "#A90000"
			end
			vim.api.nvim_set_hl(0, group, { fg = color, bg = string.format("#%06X", bg) })
		end
	end,
}
