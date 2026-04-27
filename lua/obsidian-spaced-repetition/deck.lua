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

---Get all decks and their statistics
---@return table<string, Deck>
function M.get_decks()
    local vault_path = config.options.vault_path
    local tags = config.options.flashcard_tags
    local files = parser.find_files_with_tags(vault_path, tags)
    
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

        local deck_name = "Default"
        local found_tag = false

        for _, tag in ipairs(tags) do
            local clean_tag = tag:gsub("^#", "")
            local escaped_tag = clean_tag:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
            
            -- Match tag precisely: either #tag or in a list/YAML
            -- We look for word boundaries or specific delimiters
            -- Pattern explanation:
            -- #? : optional hashtag
            -- escaped_tag : the tag text
            -- ([/%w%-_/]*) : optional sub-path starting with /
            -- Then we ensure it's followed by a space, newline, comma, or end of string
            local pattern = "#?" .. escaped_tag .. "([/%w%-_/]*)"
            local match_start, match_end, sub = file_content:find(pattern)
            
            if sub then
                -- Validate that it's a "clean" match (not middle of another word)
                -- Checking character before match
                local char_before = match_start > 1 and file_content:sub(match_start-1, match_start-1) or " "
                local char_after = match_end < #file_content and file_content:sub(match_end+1, match_end+1) or " "
                
                local before_ok = char_before:match("[%s%[,%-]") or char_before == "#"
                local after_ok = char_after:match("[%s%]%,]")
                
                if before_ok and after_ok then
                    if sub == "" then
                        deck_name = clean_tag
                    else
                        if sub:sub(1,1) == "/" then
                            -- It's a subdeck: tag/subdeck
                            deck_name = clean_tag .. sub
                        else
                            -- It's something else like tag-suffix, ignore if not starting with /
                            goto next_tag
                        end
                    end
                    found_tag = true
                    break
                end
            end
            ::next_tag::
        end

        if not decks[deck_name] then
            decks[deck_name] = { name = deck_name, due = 0, new = 0, total = 0, cards = {} }
        end

        for _, card in ipairs(cards) do
            card.deck = deck_name
            table.insert(decks[deck_name].cards, card)
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

        ::continue::
    end
    return decks
end

return M
