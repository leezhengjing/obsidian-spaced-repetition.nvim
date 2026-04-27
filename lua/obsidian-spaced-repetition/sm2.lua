local M = {}

M.Response = {
    AGAIN = 0,
    HARD = 1,
    GOOD = 2,
    EASY = 3
}

---Calculate the next interval and ease for a card
---@param response number One of M.Response
---@param original_interval number Current interval in days
---@param ease number Current ease factor
---@param config table Plugin configuration
---@return number next_interval, number next_ease
function M.calculate_next(response, original_interval, ease, config)
    local interval = math.max(1, original_interval)
    local new_ease = ease

    -- Use defaults from config or standard SM-2 values
    local easyBonus = config.easy_delay_multiplier or 1.3
    local lapsesIntervalChange = 0.5 -- Standard for lapses
    local maximumInterval = 36525

    if response == M.Response.EASY then
        new_ease = ease + 20
        interval = interval * (new_ease / 100) * easyBonus
    elseif response == M.Response.GOOD then
        -- Good uses ease directly
        interval = interval * (new_ease / 100)
    elseif response == M.Response.HARD then
        new_ease = math.max(130, ease - 20)
        interval = math.max(1, interval * lapsesIntervalChange)
    elseif response == M.Response.AGAIN then
        new_ease = math.max(130, ease - 20)
        interval = 0
    end

    interval = math.min(interval, maximumInterval)
    -- Round to 1 decimal place as per original plugin
    interval = math.floor(interval * 10 + 0.5) / 10

    return interval, new_ease
end

return M
