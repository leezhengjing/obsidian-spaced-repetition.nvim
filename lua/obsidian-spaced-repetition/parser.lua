local M = {}
local utils = require("obsidian-spaced-repetition.utils")
local config = require("obsidian-spaced-repetition.config")

---@class Card
---@field question string
---@field answer string
---@field type "single_line" | "single_line_rev" | "multi_line" | "multi_line_rev"
---@field file string
---@field line_start number
---@field line_end number
---@field side number 1 or 2 (for reversible cards)
---@field scheduling table|nil {due_date: string, interval: number, ease: number}

---Find all markdown files in the vault that contain at least one of the flashcard tags
---@param vault_path string
---@param tags string[]
---@return string[]
function M.find_files_with_tags(vault_path, tags)
    if vault_path == "" then return {} end
    local files = {}
    for _, tag in ipairs(tags) do
        local clean_tag = tag:gsub("^#", "")
        local cmd = string.format('grep -rl "%s" "%s" --include="*.md"', clean_tag, vault_path)
        local output = vim.fn.system(cmd)
        if vim.v.shell_error == 0 then
            for file in output:gmatch("[^\r\n]+") do
                files[file] = true
            end
        end
    end
    local result = {}
    for file, _ in pairs(files) do
        table.insert(result, file)
    end
    return result
end

---Parse a single file for flashcards
---@param file_path string
---@return Card[]
function M.parse_file(file_path)
    local lines = {}
    local f = io.open(file_path, "r")
    if not f then return {} end
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()

    return M.parse_lines(lines, file_path)
end

---Parse lines for flashcards
---@param lines string[]
---@param file_path string
---@return Card[]
function M.parse_lines(lines, file_path)
    local cards = {}
    local opts = config.options
    local s_sl = opts.single_line_separator or ":::"
    local s_slr = opts.single_line_reversed_separator or "::::"
    local s_ml = opts.multiline_separator or "?"
    local s_mlr = opts.multiline_reversed_separator or "??"

    -- Escape for patterns
    local function esc(s) return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") end
    local p_slr = "^(.-)%s*" .. esc(s_slr) .. "%s*(.*)$"
    local p_sl = "^(.-)%s*" .. esc(s_sl) .. "%s*(.*)$"

    local i = 1
    while i <= #lines do
        local line = lines[i]
        local trimmed = vim.trim(line)

        if vim.startswith(trimmed, "<!--") and not vim.startswith(trimmed, "<!--SR:") then
            while i <= #lines and not lines[i]:find("-->") do
                i = i + 1
            end
            i = i + 1
            goto continue
        end

        -- 1. Single Line Reversible
        local q, a = line:match(p_slr)
        if q and a then
            local sched = nil
            local line_end = i
            if i + 1 <= #lines and lines[i+1]:find("<!--SR:") then
                sched = M.parse_scheduling(lines[i+1])
                line_end = i + 1
                i = i + 1
            end
            table.insert(cards, {
                question = vim.trim(q), answer = vim.trim(a), type = "single_line_rev",
                file = file_path, line_start = i - (line_end == i and 0 or 1), line_end = line_end, side = 1,
                scheduling = sched and {sched[1]} or nil
            })
            table.insert(cards, {
                question = vim.trim(a), answer = vim.trim(q), type = "single_line_rev",
                file = file_path, line_start = i - (line_end == i and 0 or 1), line_end = line_end, side = 2,
                scheduling = sched and {sched[2]} or nil
            })
            goto next_line
        end

        -- 2. Single Line Basic
        q, a = line:match(p_sl)
        if q and a then
            local sched = nil
            local line_end = i
            if i + 1 <= #lines and lines[i+1]:find("<!--SR:") then
                sched = M.parse_scheduling(lines[i+1])
                line_end = i + 1
                i = i + 1
            end
            table.insert(cards, {
                question = vim.trim(q), answer = vim.trim(a), type = "single_line",
                file = file_path, line_start = i - (line_end == i and 0 or 1), line_end = line_end, side = 1,
                scheduling = sched
            })
            goto next_line
        end

        -- 3. Multi Line Reversible
        if trimmed == s_mlr then
            local q_lines = {}
            local j = i - 1
            while j >= 1 and vim.trim(lines[j]) ~= "" and not lines[j]:find(esc(s_sl)) and not lines[j]:find(esc(s_ml)) do
                table.insert(q_lines, 1, lines[j])
                j = j - 1
            end
            local a_lines = {}
            local k = i + 1
            while k <= #lines and vim.trim(lines[k]) ~= "" and not lines[k]:find("<!--SR:") do
                table.insert(a_lines, lines[k])
                k = k + 1
            end
            if #q_lines > 0 and #a_lines > 0 then
                local sched = nil
                local line_end = k - 1
                if k <= #lines and lines[k]:find("<!--SR:") then
                    sched = M.parse_scheduling(lines[k])
                    line_end = k
                    i = k
                else
                    i = k - 1
                end
                local q_text = table.concat(q_lines, "\n")
                local a_text = table.concat(a_lines, "\n")
                table.insert(cards, {
                    question = q_text, answer = a_text, type = "multi_line_rev",
                    file = file_path, line_start = j + 1, line_end = line_end, side = 1,
                    scheduling = sched and {sched[1]} or nil
                })
                table.insert(cards, {
                    question = a_text, answer = q_text, type = "multi_line_rev",
                    file = file_path, line_start = j + 1, line_end = line_end, side = 2,
                    scheduling = sched and {sched[2]} or nil
                })
                goto next_line
            end
        end

        -- 4. Multi Line Basic
        if trimmed == s_ml then
            local q_lines = {}
            local j = i - 1
            while j >= 1 and vim.trim(lines[j]) ~= "" and not lines[j]:find(esc(s_sl)) and not lines[j]:find(esc(s_ml)) do
                table.insert(q_lines, 1, lines[j])
                j = j - 1
            end
            local a_lines = {}
            local k = i + 1
            while k <= #lines and vim.trim(lines[k]) ~= "" and not lines[k]:find("<!--SR:") do
                table.insert(a_lines, lines[k])
                k = k + 1
            end
            if #q_lines > 0 and #a_lines > 0 then
                local sched = nil
                local line_end = k - 1
                if k <= #lines and lines[k]:find("<!--SR:") then
                    sched = M.parse_scheduling(lines[k])
                    line_end = k
                    i = k
                else
                    i = k - 1
                end
                table.insert(cards, {
                    question = table.concat(q_lines, "\n"), answer = table.concat(a_lines, "\n"), type = "multi_line",
                    file = file_path, line_start = j + 1, line_end = line_end, side = 1,
                    scheduling = sched
                })
                goto next_line
            end
        end

        ::next_line::
        i = i + 1
        ::continue::
    end
    return cards
end


---Parse scheduling data from an HTML comment
---@param line string e.g. "<!--SR:!2023-10-15,3,250-->"
---@return table|nil List of scheduling data {due_date, interval, ease}
function M.parse_scheduling(line)
    local content = line:match("<!--SR:!(.-)-->")
    if not content then return nil end
    local results = {}
    for block in content:gmatch("([^!]+)") do
        local due, ivl, ease = block:match("([^,]+),([^,]+),([^,]+)")
        if due and ivl and ease then
            table.insert(results, {
                due_date = due,
                interval = tonumber(ivl),
                ease = tonumber(ease)
            })
        end
    end
    return results
end

return M
