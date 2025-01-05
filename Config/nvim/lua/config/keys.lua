local vim = vim

-- Salvar arquivo
vim.keymap.set({ "i", "v", "n" }, "<C-s>", "<Esc>:w<CR>", { desc = "Salvar arquivo" })
vim.keymap.set({ "i", "v" }, "<C-c>", '"+y', { desc = "Copiar para o clipboard" })
vim.keymap.set({ "i", "v" }, "<C-v>", '"+p', { desc = "Colar do clipboard" })
vim.keymap.set({ "n", "v" }, "<C-a>", "ggVG", { desc = "Selecionar tudo" })
vim.keymap.set({ "n", "v" }, "<TAB>", ">gv", { desc = "Indentar" })
vim.keymap.set({ "n", "v" }, "<S-TAB>", "<gv", { desc = "Desindentar" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Sair do modo de inserção" })
vim.keymap.set("i", "JK", "<Esc>", { desc = "Sair do modo de inserção" })
vim.keymap.set("n", "<leader>m", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.notify("Apenas um buffer aberto!", "info", { title = "Buffers", timeout = 1500 })
		vim.cmd("bnext")
	else
		vim.cmd("bnext")
	end
end, { desc = "Próximo buffer" })
vim.keymap.set("n", "<leader>n", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.notify("Apenas um buffer aberto!", "info", { title = "Buffers", timeout = 1500 })
		vim.cmd("bprevious")
	else
		vim.cmd("bprevious")
	end
end, { desc = "Buffer anterior" })
vim.keymap.set("n", "<leader>t", "<cmd>Floaterminal<CR>i", { desc = "Abrir terminal flutuante" })
