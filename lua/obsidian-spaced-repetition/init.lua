local M = {}
local config = require("obsidian-spaced-repetition.config")

function M.setup(opts)
    config.setup(opts)
end

function M.review_decks()
    require("obsidian-spaced-repetition.ui.picker").show_decks()
end

---Review flashcards in the current buffer
---@param review_all boolean|nil
function M.review_note(review_all)
    local bufnr = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path == "" or vim.bo[bufnr].filetype ~= "markdown" then
        vim.notify("Not a markdown file!", vim.log.levels.WARN)
        return
    end

    require("obsidian-spaced-repetition.ui.picker").show_decks(file_path, review_all)
end

---Review all flashcards in the current buffer (bypass due date)
function M.review_note_all()
    M.review_note(true)
end

return M
