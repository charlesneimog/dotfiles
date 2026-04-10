local vim = vim

local is_mac = vim.loop.os_uname().sysname == "Darwin"
if is_mac then
	vim.g.cmdkey = "D-"
else
	vim.g.cmdkey = "C-"
end

-- Save File
vim.keymap.set({ "i", "v", "n" }, "<" .. vim.g.cmdkey .. "s>", "<Esc>:w<CR>", { desc = "Salvar arquivo" })
vim.keymap.set({ "i", "v" }, "<" .. vim.g.cmdkey .. "c>", '"+y', { desc = "Copiar para o clipboard" })
vim.keymap.set({ "i", "v" }, "<" .. vim.g.cmdkey .. "v>", '"+p', { desc = "Colar do clipboard" })
vim.keymap.set({ "n", "v" }, "<" .. vim.g.cmdkey .. "a>", "ggVG", { desc = "Selecionar tudo" })
vim.keymap.set({ "n", "v" }, "<TAB>", ">gv", { desc = "Indentar" })
vim.keymap.set({ "n", "v" }, "<S-TAB>", "<gv", { desc = "Desindentar" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Sair do modo de inserção" })
vim.keymap.set("i", "JK", "<Esc>", { desc = "Sair do modo de inserção" })

-- Next Buffer
vim.keymap.set("n", "<leader>m", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.cmd("bnext")
	else
		vim.cmd("bnext")
	end
end, { desc = "Próximo buffer" })

-- Previous Buffer
vim.keymap.set("n", "<leader>n", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.cmd("bprevious")
	else
		vim.cmd("bprevious")
	end
end, { desc = "Buffer anterior" })
vim.keymap.set("n", "<leader>t", "<cmd>Floaterminal<CR>i", { desc = "Abrir terminal flutuante" })

vim.keymap.set("n", "<leader>a", function()
	require("telescope").extensions.aerial.aerial()
end)

--╭─────────────────────────────────────╮
--│              TELESCOPE              │
--╰─────────────────────────────────────╯
local builtin = require("telescope.builtin")
local telescope = require("telescope")

vim.keymap.set({ "n", "i" }, "<leader>sf", "<cmd>Telescope find_files<cr>", {
	desc = "[S]earch [F]iles",
})

-- search
vim.keymap.set({ "n", "i" }, "<leader>sf", function()
	builtin.find_files()
end, { desc = "[S]earch [F]iles" })

vim.keymap.set({ "n", "i" }, "<leader>sg", function()
	builtin.git_files()
end, { desc = "[S]earch [G]it Files" })

vim.keymap.set({ "n", "i" }, "<leader>ss", function()
	builtin.live_grep()
end, { desc = "[S]earch [S]tring" })

vim.keymap.set({ "n", "i" }, "<leader>si", function()
	builtin.lsp_implementations()
end, { desc = "[S]earch [I]mplementations" })

vim.keymap.set({ "n", "i" }, "<leader>sd", function()
	builtin.lsp_definitions()
end, { desc = "[S]earch [D]efinitions" })

-- file browser
vim.keymap.set({ "n", "i" }, "<leader>bf", function()
	telescope.extensions.file_browser.file_browser()
end, { desc = "[F]ile [B]rowser" })

-- aerial
vim.keymap.set("n", "<leader>a", function()
	telescope.extensions.aerial.aerial()
end, { desc = "Aerial" })


--          ╭─────────────────────────────────────────────────────────╮
--          │                          Mason                          │
--          ╰─────────────────────────────────────────────────────────╯
--
vim.api.nvim_set_keymap(
	"n",
	"<leader>rn",
	"<cmd>lua vim.lsp.buf.rename()<CR>",
	{ noremap = true, silent = true, desc = "[R]ename [N]ode" }
)

vim.api.nvim_set_keymap(
	"n",
	"<leader>v",
	"<cmd>lua vim.diagnostic.open_float()<CR>",
	{ noremap = true, silent = true, desc = "[V]iew [D]iagnostics" }
)

vim.api.nvim_set_keymap(
	"n",
	"ca",
	"<cmd>lua vim.lsp.buf.code_action()<CR>",
	{ noremap = true, silent = true, desc = "Code [A]ction" }
)
