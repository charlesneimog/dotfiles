return {
    {
        "gbprod/yanky.nvim",
        dependencies = { { "kkharji/sqlite.lua", enabled = not jit.os:find("Windows") } },

        keys = {
            {
                "<leader>y",
                function()
                    require("telescope").extensions.yank_history.yank_history({})
                end,
                desc = "Open Yank History",
            },
        },
        opts = {
            {
                highlight = { timer = 200 },
                ring = { storage = jit.os:find("Windows") and "shada" or "sqlite" },
            },
        },
    },

}
