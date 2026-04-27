local M = {}

---@class ObsidianSRConfig
---@field vault_path string Path to the Obsidian vault
---@field flashcard_tags string[] Tags to look for in notes to identify flashcard decks
---@field default_ease number Default ease factor for new cards (default 250)
---@field again_delay number Delay in minutes for "Again" score (default 1)
---@field hard_delay number Delay in days for "Hard" score (default 1)
---@field good_delay_multiplier number Multiplier for "Good" score (default 2.5)
---@field easy_delay_multiplier number Multiplier for "Easy" score (default 3.5)

M.defaults = {
    vault_path = "", -- Should be set by user
    flashcard_tags = { "#flashcards" },
    default_ease = 250,
    again_delay = 1,
    hard_delay = 1,
    good_delay_multiplier = 2.5,
    easy_delay_multiplier = 3.5,
}

M.options = {}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
    if M.options.vault_path == "" then
        vim.notify("obsidian-spaced-repetition.nvim: vault_path is not set", vim.log.levels.WARN)
    end
end

return M
