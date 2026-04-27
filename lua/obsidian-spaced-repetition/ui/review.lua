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
    rendered_images = {},
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

    vim.bo[state.bufnr].filetype = "markdown"
    vim.bo[state.bufnr].buftype = "nofile"
    vim.bo[state.bufnr].modifiable = true
    
    -- Mappings
    local opts = { buffer = state.bufnr, nowait = true, silent = true }
    vim.keymap.set("n", "<Space>", M.toggle_answer, opts)
    vim.keymap.set("n", "<CR>", M.toggle_answer, opts)
    vim.keymap.set("n", "1", function() M.score(sm2.Response.AGAIN) end, opts)
    vim.keymap.set("n", "2", function() M.score(sm2.Response.HARD) end, opts)
    vim.keymap.set("n", "3", function() M.score(sm2.Response.GOOD) end, opts)
    vim.keymap.set("n", "4", function() M.score(sm2.Response.EASY) end, opts)
    vim.keymap.set("n", "q", M.close, opts)
    vim.keymap.set("n", "<Esc>", M.close, opts)
    
    -- Ensure window is focused
    vim.api.nvim_set_current_win(state.winid)
end

---Clear all rendered images
local function clear_images()
    for _, img in ipairs(state.rendered_images) do
        pcall(function() img:clear() end)
    end
    state.rendered_images = {}
end

---Render images found in lines
---@param lines string[]
local function render_images(lines)
    local has_image_nvim, image_api = pcall(require, "image")
    if not has_image_nvim then return end

    clear_images()
    local vault_path = config.options.vault_path
    local card = state.cards_to_review[state.current_index]

    for line_idx, line in ipairs(lines) do
        -- 1. Match ![[Image.png]]
        for link in line:gmatch("!%[%[(.-)%]%]") do
            local path = utils.resolve_image_path(vault_path, card.file, link)
            if path then
                local img = image_api.from_file(path, {
                    window = state.winid,
                    buffer = state.bufnr,
                    y = line_idx - 1,
                    x = 0,
                    with_virtual_padding = true,
                })
                if img then
                    img:render()
                    table.insert(state.rendered_images, img)
                end
            end
        end
        -- 2. Match ![alt](path/to/img.png)
        for _, img_path in line:gmatch("!%[(.-)%]%((.-)%)") do
            local path = utils.resolve_image_path(vault_path, card.file, img_path)
            if path then
                local img = image_api.from_file(path, {
                    window = state.winid,
                    buffer = state.bufnr,
                    y = line_idx - 1,
                    x = 0,
                    with_virtual_padding = true,
                })
                if img then
                    img:render()
                    table.insert(state.rendered_images, img)
                end
            end
        end
    end
end

---Update buffer content safely
---@param lines string[]
local function set_lines(lines)
    local final_lines = {}
    for _, line in ipairs(lines) do
        -- Split any line that contains internal newlines
        for s in string.gmatch(line .. "\n", "([^\n]*)\n") do
            table.insert(final_lines, s)
        end
    end

    vim.bo[state.bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, final_lines)
    vim.bo[state.bufnr].modifiable = false
    -- Reset cursor to top
    vim.api.nvim_win_set_cursor(state.winid, {1, 0})
    
    -- Defer image rendering slightly to ensure buffer is ready
    vim.defer_fn(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
            render_images(final_lines)
        end
    end, 100)
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
        "(Press <Space> or <CR> to show answer, 'q' to quit)"
    }
    set_lines(content)
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
    set_lines(content)
end

---Record score for current card and proceed
---@param response number
function M.score(response)
    if not state.showing_answer then return end
    
    local card = state.cards_to_review[state.current_index]
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
    clear_images()
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        vim.api.nvim_win_close(state.winid, true)
    end
    state.winid = nil
    state.bufnr = nil
end

return M
