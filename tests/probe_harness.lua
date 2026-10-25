-- Engine mocks test Lua behavior, not actual game API availability.
local real_io = io
local emitted = {}
for _, mode in ipairs({"frontend", "campaign", "battle"}) do
    local listeners = {}
    local open_count = 0
    local errors = 0
    local fail = false
    core = {
        is_campaign = function() return mode == "campaign" end,
        is_battle = function() return mode == "battle" end,
        add_listener = function(self, name, event, condition, callback, persists)
            listeners[name] = {event, condition, callback, persists}
        end,
        get_ui_root = function() return {ChildCount = function() return 7 end} end
    }
    UIComponent = function(component)
        assert(component == "valid", "stale pointer")
        return {
            GetStateText = function() return 'Label "quoted"\\\n\t\0 café' end,
            GetTooltipText = function() return "Tooltip" end
        }
    end
    ModLog = function() errors = errors + 1 end
    io = {open = function(path, access)
        open_count = open_count + 1
        assert(path == "jaws_probe.jsonl" and access == "a")
        if fail then return nil, "denied" end
        return {
            write = function(self, record) emitted[#emitted + 1] = record; return self end,
            close = function() return true end
        }
    end}
    local function fire(event, context)
        for name, listener in pairs(listeners) do
            if listener[1] == event and (listener[2] == true or listener[2](context)) then
                listener[3](context)
                if not listener[4] then listeners[name] = nil end
            end
        end
    end
    dofile("mod/script/_lib/mod/jaws_probe.lua")
    assert(open_count == 1)
    fire("ShortcutTriggered", {string = "end_turn"})
    assert(open_count == 1, "unrelated shortcut must be ignored")
    fire("ComponentMouseOn", {string = "button", component = "valid"})
    fire("ComponentMouseOn", {string = "deleted", component = "invalid"})
    assert(open_count == 1, "hover must not write every event")
    for _, key in ipairs({"script_F2", "script_F3", "script_F4"}) do
        fire("ShortcutTriggered", {string = key})
    end
    assert(open_count == 4)
    fire("FirstTickAfterWorldCreated", {})
    fire("FirstTickAfterWorldCreated", {})
    assert(open_count == (mode == "campaign" and 5 or 4))
    fire("PanelClosedCampaign", {})
    fire("ShortcutTriggered", {string = "script_F3"})
    fail = true
    fire("ShortcutTriggered", {string = "script_F2"})
    local failed_count = open_count
    fire("ShortcutTriggered", {string = "script_F2"})
    assert(open_count == failed_count and errors == 1, "file failure must not repeat")
end
io = real_io
for _, record in ipairs(emitted) do io.write(record) end
