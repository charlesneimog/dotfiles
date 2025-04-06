local vim = vim

local function lualine_setup()
	local function mylocation()
		local line = vim.fn.line(".")
		local total_lines = vim.fn.line("$")
		return string.format("%3d-%-2d", line, total_lines)
	end
	local darktheme = vim.g.wezterm_theme
	local mytheme
	if darktheme == "dark" then
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
					path = 0, -- 0: Just the filename
					shorting_target = 10, -- Shortens path to leave 40 spaces in the window
					symbols = {
						modified = "[+]", -- Text to show when the file is modified.
						readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
						unnamed = "[No Name]", -- Text to show for unnamed buffers.
						newfile = "[New]", -- Text to show for newly created file before first write
					},
				},
				function()
					local result = require("lsp-progress").progress()
					local spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }
					local truncated = ""
					local spinner_found = false
					for i = 1, math.min(#result, 20) do
						truncated = truncated .. result:sub(i, i)
						if vim.tbl_contains(spinner, result:sub(i, i)) then
							spinner_found = true
							break
						end
					end
					if spinner_found then
						return truncated
					elseif #result > 20 then
						return truncated 
					else
						return result
					end
				end,
			},
			lualine_x = {
				{
					"buffers",
					buffers_color = {
						active = "lualine_b_normal",
						inactive = "lualine_b_inactive",
					},
				},
				{
					function()
						local client = vim.lsp.get_active_clients()
						if client("copilot") then
							local clients = " "
							local numClients = #client
							for i, v in ipairs(client) do
								if v.name ~= "copilot" then
									clients = clients .. v.name
									if i < numClients then
										clients = clients .. ", "
									end
								end
							end
							return clients
						end
						return ""
					end,
				},
			},
			lualine_z = {
				mylocation,
				-- "copilot",
				-- function()
				-- 	return require("codeium.virtual_text").status_string()
				-- end,
			},
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
end

return {
	"nvim-lualine/lualine.nvim",
	event = "VimEnter",
	priority = 999,
	config = function()
		lualine_setup()
	end,
}
