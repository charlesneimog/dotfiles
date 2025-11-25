-- ─────────────────────────────────────
local function lualine_setup()
	local function mylocation()
		local line = vim.fn.line(".")
		local total_lines = vim.fn.line("$")
		return string.format("%3d-%-2d", line, total_lines)
	end

	require("lualine").setup({
		options = {
			theme = "catppuccin",
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
					colored = false,
					symbols = { added = "+", modified = "~", removed = "-" },
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
			},
			lualine_z = {
				mylocation,
			},
		},
	})
end

-- ─────────────────────────────────────
return {
	"nvim-lualine/lualine.nvim",
	event = "VimEnter",
	priority = 999,
	config = function()
		lualine_setup()
	end,
}
