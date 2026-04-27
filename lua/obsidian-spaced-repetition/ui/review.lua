local M = {}
local config = require("obsidian-spaced-repetition.config")
local sm2 = require("obsidian-spaced-repetition.sm2")
local utils = require("obsidian-spaced-repetition.utils")

local state = {
    deck = nil,
    cards_to_review = {},
    current_index = 0,
    bufnr = nil,
    winid = nil,
    showing_answer = false,
}

---Start a review session for a deck
---@param deck table
function M.start_review(deck)
    state.deck = deck
    state.cards_to_review = {}
    local today = utils.get_today()

    -- Filter Due cards
    for _, card in ipairs(deck.cards) do
        local is_due = false
        if card.scheduling and #card.scheduling > 0 then
            for _, s in ipairs(card.scheduling) do
                if s.due_date <= today then
                    is_due = true
                    break
                end
            end
        else
            -- New card (no scheduling)
            is_due = true
        end
        if is_due then
            table.insert(state.cards_to_review, card)
        end
    end

    if #state.cards_to_review == 0 then
        vim.notify("No cards to review in this deck today!", vim.log.levels.INFO)
        return
    end

    state.current_index = 1
    M.create_window()
    M.show_card()
end

---Create the floating window for review
function M.create_window()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    state.bufnr = vim.api.nvim_create_buf(false, true)
    state.winid = vim.api.nvim_open_win(state.bufnr, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Flashcard Review: " .. state.deck.name .. " ",
        title_pos = "center",
    })

    vim.api.nvim_buf_set_option(state.bufnr, "filetype", "markdown")
    vim.api.nvim_buf_set_option(state.bufnr, "buftype", "nofile")
    
    -- Mappings
    local opts = { buffer = state.bufnr, nowait = true }
    vim.keymap.set("n", "<Space>", M.toggle_answer, opts)
    vim.keymap.set("n", "1", function() M.score(sm2.Response.AGAIN) end, opts)
    vim.keymap.set("n", "2", function() M.score(sm2.Response.HARD) end, opts)
    vim.keymap.set("n", "3", function() M.score(sm2.Response.GOOD) end, opts)
    vim.keymap.set("n", "4", function() M.score(sm2.Response.EASY) end, opts)
    vim.keymap.set("n", "q", M.close, opts)
end

---Display current card's question
function M.show_card()
    local card = state.cards_to_review[state.current_index]
    state.showing_answer = false
    
    local content = {
        "# Question (" .. state.current_index .. "/" .. #state.cards_to_review .. ")",
        "",
        card.question,
        "",
        "---",
        "(Press <Space> to show answer, 'q' to quit)"
    }
    vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, content)
end

---Display current card's answer
function M.toggle_answer()
    if state.showing_answer then return end
    state.showing_answer = true
    
    local card = state.cards_to_review[state.current_index]
    local content = {
        "# Question (" .. state.current_index .. "/" .. #state.cards_to_review .. ")",
        "",
        card.question,
        "",
        "---",
        "# Answer",
        "",
        card.answer,
        "",
        "---",
        "Score: 1: Again, 2: Hard, 3: Good, 4: Easy"
    }
    vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, content)
end

---Record score for current card and proceed
---@param response number
function M.score(response)
    if not state.showing_answer then return end
    
    local card = state.cards_to_review[state.current_index]
    -- Update SM-2 logic and write back to file
    require("obsidian-spaced-repetition.writer").update_card(card, response)

    state.current_index = state.current_index + 1
    if state.current_index > #state.cards_to_review then
        vim.notify("Review complete!", vim.log.levels.INFO)
        M.close()
    else
        M.show_card()
    end
end

---Close review window
function M.close()
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        vim.api.nvim_win_close(state.winid, true)
    end
    state.winid = nil
    state.bufnr = nil
end

return M
