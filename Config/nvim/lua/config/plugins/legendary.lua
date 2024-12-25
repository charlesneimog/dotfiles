return {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
    keys = {
        {
            "<leader>l",
            ":Legendary<CR>",
            desc = "Toggle legendary.nvim scratchpad",
            mode = { "i", "n" },
        },
        {
            "<C-s>",
            "<Esc>:w<CR>",
            desc = "Save file",
            mode = { "i", "v", "n" },
        },
        {
            "<C-S>",
            "<Esc>:w<CR>",
            desc = "Save file",
            mode = { "i", "v", "n" },
        },
        {
            "<C-c>",
            '"+y',
            desc = "Copy to clipboard",
            mode = { "i", "v" },
        },
        {
            "<C-v>",
            '"+p',
            desc = "Paste from clipboard",
            mode = { "i", "v" },
        },
        {
            "<C-v>",
            '"+p',
            desc = "Paste from clipboard",
            mode = { "i", "v" },
        },
        {
            "<C-a>",
            "ggVG",
            desc = "Select all",
            mode = { "n", "v" },
        },
        {
            "<TAB>",
            ">gv",
            desc = "Indent",
            mode = { "n", "v" },
        },
        {
            "<S-TAB>",
            "<gv",
            desc = "Unindent",
            mode = { "n", "v" },
        },
        {
            "jk",
            "<Esc>",
            desc = "Exit insert mode",
            mode = { "i" },
        },
        {
            "JK",
            "<Esc>",
            desc = "Exit insert mode",
            mode = { "i" },
        },
        {
            "<leader>m",
            function()
                local buffers = vim.api.nvim_list_bufs()
                if buffers == 2 then
                    vim.notify("Just one buffer open!", "info", { title = "Buffers", timeout = 1500 })
                    vim.cmd("bnext")
                else
                    vim.cmd("bnext")
                end
            end,
        },
        {
            "<leader>n",
            function()
                local buffers = vim.api.nvim_list_bufs()
                if #buffers == 2 then
                    vim.notify("Just one buffer open!", "info", { title = "Buffers", timeout = 1500 })
                    vim.cmd("bprevious")
                else
                    vim.cmd("bprevious")
                end
            end,
        },
        {
            "<leader>s",
            function()
                local ls = require("luasnip")
                ls.jump(1)
            end,
            desc = "Exit insert mode",
            mode = { "i", "s" },
        },
        {
            "<leader>t",
            "<cmd>Floaterminal<CR>i",
        },
    },

    config = function()
        require("legendary").setup({
            extensions = {
                lazy_nvim = { auto_register = true },
                nvim_tree = false,
                which_key = {
                    auto_register = true,
                    mappings = {},
                    opts = {},
                    do_binding = true,
                    use_groups = true,
                },
            },
            scratchpad = {
                view = "float",
                results_view = "float",
                float_border = "rounded",
                keep_contents = true,
            },
        })
    end,
}
