-- Read-only frontend diagnostic. Never activates UI or sends game shortcuts.
-- Do not overwrite frontend evidence when campaign/battle creates a Lua context.
if core:is_campaign() or core:is_battle() then return end
local sequence, runs, armed = 0, 0, false
local session = 'diagnostic:' .. tostring({}) .. ':' .. tostring(os.clock())
local log_path, bridge_path
local log_failed = false
local function quote(v)
    return '"' .. tostring(v):gsub('[%z\1-\31\\"]', function(c)
        return string.format('\\u%04x', string.byte(c))
    end) .. '"'
end
local function append(path, line)
    local f = io.open(path, 'a')
    if not f then if path == log_path then log_failed = true end; return end
    local written = f:write(line .. '\n'); local closed = f:close()
    if path == log_path and (not written or closed == nil) then log_failed = true end
end
local function log(stage, value)
    if log_path then append(log_path, stage .. '\t' .. type(value) .. '\t' .. tostring(value):sub(1,1000):gsub('[\r\n]', ' ')) end
end
local function speak(text)
    sequence = sequence + 1
    if bridge_path then append(bridge_path, '{"version":1,"session":' .. quote(session)
        .. ',"sequence":' .. sequence .. ',"context":"frontend","generation":0,"kind":"speech","text":' .. quote(text) .. '}') end
end
local bases = {}
if os.getenv and os.getenv('LOCALAPPDATA') then bases[1] = os.getenv('LOCALAPPDATA') .. '/JawsWarhammer2/' end
bases[#bases + 1] = ''
for _, base in ipairs(bases) do
    local path = base .. 'native-ui-diagnostic.log'
    local f = io.open(path, 'w')
    if f then
        f:write('WH2 native UI diagnostic 0.3.0-diagnostic\n'); f:close()
        log_path = path; bridge_path = base .. (base == '' and 'jaws_access.jsonl' or 'bridge.jsonl')
        local bridge = io.open(bridge_path, 'w'); if bridge then bridge:close() end
        break
    end
end
local function observe(name, fn)
    log(name .. '.START', true)
    local value
    local ok, err = pcall(function() value = fn() end)
    if ok then log(name .. '.RESULT', value) else log(name .. '.ERROR', err) end
    return ok, value
end
local function id_adapter(node) local v = node:Id(); return v end
local function count_adapter(node) local v = node:ChildCount(); return v end
local function id_tail(node) return node:Id() end
local function count_tail(node) return node:ChildCount() end
local function sample(label, node, children)
    log(label .. '.object', node)
    observe(label .. '.Id.inline', function() local v = node:Id(); return v end)
    observe(label .. '.Id.adapter', function() local v = id_adapter(node); return v end)
    observe(label .. '.Id.tail', function() local v = id_tail(node); return v end)
    local ok, count = observe(label .. '.ChildCount.inline', function() local v = node:ChildCount(); return v end)
    observe(label .. '.ChildCount.adapter', function() local v = count_adapter(node); return v end)
    observe(label .. '.ChildCount.tail', function() local v = count_tail(node); return v end)
    observe(label .. '.ChildCount.nested', function()
        local value
        local success, err = pcall(function() value = node:ChildCount() end)
        if not success then error(err) end
        return value
    end)
    observe(label .. '.Visible', function() local v = node:Visible(true); return v end)
    observe(label .. '.IsInteractive', function() local v = node:IsInteractive(); return v end)
    observe(label .. '.GetStateText', function() local v = node:GetStateText(); return v end)
    observe(label .. '.CurrentState', function() local v = node:CurrentState(); return v end)
    observe(label .. '.Address', function() local v = node:Address(); return v end)
    if children and ok and type(count) == 'number' and count >= 0 and count < math.huge and count == math.floor(count) then
        for i = 0, math.min(count, 8) - 1 do
            local prefix = label .. '.child' .. i
            local found, address = observe(prefix .. '.Find', function() local v = node:Find(i); return v end)
            if found and address then
                local converted, child = observe(prefix .. '.Convert', function() local v = UIComponent(address); return v end)
                if converted and child then sample(prefix, child, false) end
            end
        end
    else log(label .. '.children.skipped', 'not requested or invalid count') end
end
local function capture(source, component)
    if runs >= 6 then return end
    runs = runs + 1
    log('capture', runs); log('source', source)
    local ok, ready = observe('core.is_ui_created', function() local v = core:is_ui_created(); return v end)
    if ok and ready == true then
        local got, node = observe('core.get_ui_root', function() local v = core:get_ui_root(); return v end)
        if got and node then sample('root', node, true) end
    else log('root.skipped', 'UI not ready') end
    if component then
        local ok_node, node = observe('event.Convert', function() local v = UIComponent(component); return v end)
        if ok_node and node then sample('event', node, false) end
    end
    log('capture.COMPLETE', runs)
    if log_failed or not log_path then speak('Diagnostic file could not be saved. Check the game folder and AppData permissions.'); return end
    speak('Read-only UI diagnostic capture ' .. runs .. ' saved. Send native-ui-diagnostic.log. No game action was sent.')
end
if not core:is_campaign() and not core:is_battle() then
    core:add_ui_created_callback(function() log('lifecycle.created', true) end)
    core:add_ui_destroyed_callback(function() armed = false; log('lifecycle.destroyed', true) end)
    core:add_listener('jaws_diagnostic_key', 'ShortcutTriggered', function(c) return c.string == 'script_F2' end,
        function() capture('shortcut'); armed = runs < 6 end, true)
    core:add_listener('jaws_diagnostic_hover', 'ComponentMouseOn', function() return armed end,
        function(c) armed = false; capture('mouse_event', c.component) end, true)
    speak('JAWS read-only diagnostic 0.3.0. In the main menu press F2, then move the mouse over one menu button. No activation keys are enabled.')
else speak('This diagnostic only inspects the frontend. Return to the main menu.') end
