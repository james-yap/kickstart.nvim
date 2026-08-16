-- 1. Add the plugin and its dependencies explicitly
vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/kawre/leetcode.nvim" },
})

-- 2. Call the setup function manually (replaces lazy's `opts` table)
require("leetcode").setup({
    -- configuration goes here
    lang = "python3",
    image_support = true
})

-- 3. Handle the build command (replaces lazy's `build = ...`)
vim.api.nvim_create_autocmd("User", {
    pattern = "PackChanged",
    callback = function(ev)
        -- `ev.data.spec.name` automatically infers the repository name from the src URL
        if ev.data.spec.name == "leetcode.nvim" then
            vim.schedule(function()
                vim.cmd("TSUpdate html")
            end)
        end
    end,
})

