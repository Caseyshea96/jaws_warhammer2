-- Read-only diagnostic. No simulation changes or gameplay commands.
-- Uses the common WH2 mod loader in frontend, campaign, and battle.
local mode = core:is_campaign() and "campaign" or (core:is_battle() and "battle" or "frontend")
local session = mode .. ":" .. tostring({})
local sequence = 0
local output_failed = false
local last_hover = "No readable hovered component captured."

local function quote(value)
    local text = tostring(value or "")
    text = text:gsub('[%z\1-\31\\"]', function(c)
        if c == '"' then return '\\"' end
        if c == '\\' then return '\\\\' end
        return string.format('\\u%04x', string.byte(c))
    end)
    return '"' .. text .. '"'
end

local function emit(kind, text)
    if output_failed then return end
    sequence = sequence + 1
    local record = '{"version":0,"session":' .. quote(session)
        .. ',"sequence":' .. sequence .. ',"context":' .. quote(mode)
        .. ',"generation":0,"kind":' .. quote(kind)
        .. ',"text":' .. quote(text) .. ',"priority":"normal"}\n'
    local ok, err = pcall(function()
        local file, reason = io.open("jaws_probe.jsonl", "a")
        if not file then error(reason or "file open failed") end
        local written, write_error = file:write(record)
        local closed, close_error = file:close()
        if not written or not closed then error(write_error or close_error or "file write failed") end
    end)
    if not ok then
        output_failed = true
        -- Fail closed locally: do not interrupt gameplay or spam errors.
        pcall(function() ModLog("JAWS probe output unavailable: " .. tostring(err)) end)
    end
end

core:add_listener("jaws_probe_hover", "ComponentMouseOn", true, function(context)
    -- Cache strings, never a UI pointer that may become invalid after panel changes.
    local ok, text = pcall(function()
        local component = UIComponent(context.component)
        local label = component:GetStateText() or ""
        local tooltip = component:GetTooltipText() or ""
        return tostring(context.string or "unknown") .. ": " .. label .. " " .. tooltip
    end)
    if ok then last_hover = text end
end, true)

core:add_listener("jaws_probe_panel_reset", "PanelClosedCampaign", true, function()
    last_hover = "Panel closed; hover a component again."
end, true)

core:add_listener("jaws_probe_shortcut", "ShortcutTriggered", function(context)
    return context.string == "script_F2" or context.string == "script_F3"
        or context.string == "script_F4"
end, function(context)
    if context.string == "script_F2" then
        emit("details", "Keyboard event received in " .. mode .. ".")
    elseif context.string == "script_F3" then
        emit("details", "Last hover sample (diagnostic, may be stale): " .. last_hover)
    else
        local ok, count = pcall(function() return core:get_ui_root():ChildCount() end)
        emit("details", ok and ("UI root child count: " .. tostring(count)) or "UI root unavailable.")
    end
end, true)

if mode == "campaign" then
    core:add_listener("jaws_probe_first_tick", "FirstTickAfterWorldCreated", true, function()
        emit("hello", "Campaign first tick received.")
    end, false)
end
emit("hello", "JAWS diagnostic loaded in " .. mode .. ".")
