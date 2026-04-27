local M = {}
local config = require("obsidian-spaced-repetition.config")
local sm2 = require("obsidian-spaced-repetition.sm2")
local utils = require("obsidian-spaced-repetition.utils")

---Update a card's scheduling data in its source file
---@param card Card
---@param response number
function M.update_card(card, response)
    local lines = {}
    local f = io.open(card.file, "r")
    if not f then return end
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()

    local today = utils.get_today()
    local current_sched = (card.scheduling and card.scheduling[1]) or {
        due_date = today,
        interval = 0,
        ease = config.options.default_ease or 250
    }

    local next_ivl, next_ease = sm2.calculate_next(response, current_sched.interval, current_sched.ease, config.options)
    local next_due = utils.add_days(today, next_ivl)

    local sr_line_idx = nil
    local existing_sr = nil
    
    -- Check if card.line_end is valid and points to an SR comment
    if card.line_end <= #lines and lines[card.line_end]:find("<!--SR:") then
        sr_line_idx = card.line_end
        existing_sr = lines[sr_line_idx]
    end

    local new_sr_content = ""
    if existing_sr then
        local content = existing_sr:match("<!--SR:!(.-)-->")
        local sides = {}
        if content then
            for block in content:gmatch("([^!]+)") do
                table.insert(sides, block)
            end
        end
        
        -- Ensure we have enough sides for reversible cards
        if card.type:find("_rev") and #sides < 2 then
            if #sides == 0 then
                sides[1] = string.format("%s,%s,%s", today, 0, config.options.default_ease)
            end
            sides[2] = string.format("%s,%s,%s", today, 0, config.options.default_ease)
        end

        sides[card.side] = string.format("%s,%s,%s", next_due, next_ivl, next_ease)
        new_sr_content = "<!--SR:!" .. table.concat(sides, "!") .. "-->"
    else
        local sides = {}
        if card.type:find("_rev") then
            sides[1] = string.format("%s,%s,%s", today, 0, config.options.default_ease)
            sides[2] = string.format("%s,%s,%s", today, 0, config.options.default_ease)
            sides[card.side] = string.format("%s,%s,%s", next_due, next_ivl, next_ease)
        else
            sides[1] = string.format("%s,%s,%s", next_due, next_ivl, next_ease)
        end
        new_sr_content = "<!--SR:!" .. table.concat(sides, "!") .. "-->"
    end

    if sr_line_idx then
        lines[sr_line_idx] = new_sr_content
    else
        -- If no SR comment existed, append it after the card
        table.insert(lines, card.line_end + 1, new_sr_content)
    end

    -- Write back to file
    f = io.open(card.file, "w")
    if f then
        f:write(table.concat(lines, "\n"))
        f:close()
    end
end

return M
