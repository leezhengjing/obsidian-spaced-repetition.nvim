local M = {}
local parser = require("obsidian-spaced-repetition.parser")
local config = require("obsidian-spaced-repetition.config")
local utils = require("obsidian-spaced-repetition.utils")

---@class Deck
---@field name string
---@field due number
---@field new number
---@field total number
---@field cards Card[]

---Get all decks a file belongs to based on tags
---@param file_content string
---@return string[]
function M.get_file_decks(file_content)
    local tags = config.options.flashcard_tags
    local found_decks = {}

    for _, tag in ipairs(tags) do
        local clean_tag = tag:gsub("^#", "")
        local escaped_tag = clean_tag:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
        
        local pattern = "#?" .. escaped_tag .. "([/%w%-_/]*)"
        local start = 1
        while true do
            local match_start, match_end, sub = file_content:find(pattern, start)
            if not match_start then break end
            
            local char_before = match_start > 1 and file_content:sub(match_start-1, match_start-1) or " "
            local char_after = match_end < #file_content and file_content:sub(match_end+1, match_end+1) or " "
            
            local before_ok = char_before:match("[%s%[,%-]") or char_before == "#"
            local after_ok = char_after:match("[%s%]%,]")
            
            if before_ok and after_ok then
                if sub == "" then
                    found_decks[clean_tag] = true
                elseif sub:sub(1,1) == "/" then
                    found_decks[clean_tag .. sub] = true
                end
            end
            start = match_end + 1
        end
    end

    local results = {}
    for d, _ in pairs(found_decks) do
        table.insert(results, d)
    end

    if #results == 0 then
        table.insert(results, "Default")
    end
    return results
end

---Get all decks and their statistics
---@param filter_file string|nil Optional file path to filter results to a single note
---@return table<string, Deck>
function M.get_decks(filter_file)
    local vault_path = config.options.vault_path
    local tags = config.options.flashcard_tags
    local files = filter_file and { filter_file } or parser.find_files_with_tags(vault_path, tags)
    
    local decks = {}
    local today = utils.get_today()

    for _, file in ipairs(files) do
        local cards = parser.parse_file(file)
        if #cards == 0 then
            goto continue
        end

        local file_content = ""
        local f = io.open(file, "r")
        if f then
            file_content = f:read("*all")
            f:close()
        end

        local file_decks = M.get_file_decks(file_content)

        for _, deck_name in ipairs(file_decks) do
            if not decks[deck_name] then
                decks[deck_name] = { name = deck_name, due = 0, new = 0, total = 0, cards = {} }
            end

            for _, card in ipairs(cards) do
                local card_copy = vim.deepcopy(card)
                card_copy.deck = deck_name
                table.insert(decks[deck_name].cards, card_copy)
                decks[deck_name].total = decks[deck_name].total + 1
                
                if not card.scheduling or #card.scheduling == 0 then
                    decks[deck_name].new = decks[deck_name].new + 1
                else
                    local is_due = false
                    for _, s in ipairs(card.scheduling) do
                        if s.due_date <= today then
                            is_due = true
                            break
                        end
                    end
                    if is_due then
                        decks[deck_name].due = decks[deck_name].due + 1
                    end
                end
            end
        end

        ::continue::
    end
    return decks
end

return M
