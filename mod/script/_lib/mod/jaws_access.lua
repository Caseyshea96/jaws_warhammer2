-- JAWS co-op pilot. Lua 5.1. Uses normal UI inputs, never model mutations or unit controllers.
local mode = core:is_campaign() and "campaign" or (core:is_battle() and "battle" or "frontend")
local sequence, generation = 0, 0
local session = mode .. ":" .. tostring({}) .. ":" .. tostring(os.clock()) .. ":" .. tostring(os.time and os.time() or "")
local category, index, entries, scope, parents = 1, 0, {}, {}, {}
local pending, pending_until = nil, 0
local hover, last_message = "No hovered text yet.", "Accessibility pilot ready."
local panels = {}
local output_path, output_failed = nil, false
local names = {"Controls", "Readable text", "Game actions"}
if mode == "battle" then names[4] = "Local army reports"; names[5] = "Visible enemy reports" end

local scan_issue, scan_nodes = nil, 0
local function clear_pending()
    pending, pending_until = nil, 0
end
local function activation_time()
    if os.time then return os.time() end
    return os.clock()
end
-- Assign native results directly inside the protected callback, without an
-- intermediate reader return or dependence on pcall forwarding return values.
-- This is a candidate fix for the invalid types observed in live 0.5.1.
local function read_native(obj, method, argument)
    local value
    local ok, err = pcall(function()
        if method == "Id" then value = obj:Id()
        elseif method == "Address" then value = obj:Address()
        elseif method == "ChildCount" then value = obj:ChildCount()
        elseif method == "CurrentState" then value = obj:CurrentState()
        elseif method == "GetStateText" then value = obj:GetStateText()
        elseif method == "GetTooltipText" then value = obj:GetTooltipText()
        elseif method == "IsInteractive" then value = obj:IsInteractive()
        elseif method == "NumStates" then value = obj:NumStates()
        elseif method == "Visible" then value = obj:Visible(argument)
        elseif method == "name" then value = obj:name()
        elseif method == "ammo_left" then value = obj:ammo_left()
        elseif method == "is_in_melee" then value = obj:is_in_melee()
        elseif method == "is_routing" then value = obj:is_routing()
        elseif method == "is_under_missile_attack" then value = obj:is_under_missile_attack()
        elseif method == "number_of_men_alive" then value = obj:number_of_men_alive()
        elseif method == "type" then value = obj:type()
        elseif method == "unique_ui_id" then value = obj:unique_ui_id()
        elseif method == "is_visible_to_alliance" then value = obj:is_visible_to_alliance(argument)
        else error("Unsupported reader: " .. tostring(method)) end
    end)
    return ok, value, err
end
local function call(obj, method, fallback, argument)
    local ok, value, err = read_native(obj, method, argument)
    local valid = ok and value ~= nil
    if valid and method == "Address" then
        local kind = type(value)
        valid = kind == "userdata" or (kind == "string" and value ~= "")
            or (kind == "number" and value == value and value > 0)
    elseif valid and type(fallback) == "number" then
        valid = type(value) == "number" and value == value
    elseif valid and type(fallback) == "boolean" then valid = type(value) == "boolean"
    elseif valid then valid = type(value) == "string" or type(value) == "number" end
    if valid then return value end
    local issue = method .. " returned " .. type(value) .. (not ok and ("; " .. tostring(err)) or "")
    if not scan_issue then scan_issue = issue
    elseif #scan_issue < 1000 and not scan_issue:find(issue, 1, true) then scan_issue = scan_issue .. "; " .. issue end
    return fallback
end
local function clean(value)
    if type(value) ~= "string" then return "" end
    return value:gsub("%[%[.-%]%]", " "):gsub("<[^>]*>", " ")
        :gsub("[%z\1-\31]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
local function bounded_child_count(node, maximum)
    local count = call(node, "ChildCount", 0)
    if count < 0 or count % 1 ~= 0 then return 0 end
    if count > maximum then return maximum end
    return count
end
local function quote(value)
    return '"' .. tostring(value):gsub('[%z\1-\31\\"]', function(c)
        if c == '"' then return '\\"' end
        if c == '\\' then return '\\\\' end
        return string.format('\\u%04x', string.byte(c))
    end) .. '"'
end
local function write(kind, text)
    if output_failed then return end
    sequence = sequence + 1
    -- Keep records finite without cutting a UTF-8 string in the middle of a codepoint.
    if #text > 6000 then text = text:sub(1, 5900):gsub("[\192-\255][\128-\191]*$", "") .. " [truncated]" end
    local record = '{"version":1,"session":' .. quote(session) .. ',"sequence":' .. sequence
        .. ',"context":' .. quote(mode) .. ',"generation":' .. generation
        .. ',"kind":' .. quote(kind) .. ',"text":' .. quote(text) .. '}\n'
    local ok, err = pcall(function()
        if not output_path then
            local paths = {}
            if os.getenv then
                local base = os.getenv("LOCALAPPDATA")
                if base then paths[#paths + 1] = base .. "/JawsWarhammer2/bridge.jsonl" end
            end
            paths[#paths + 1] = "jaws_access.jsonl"
            for _, path in ipairs(paths) do
                local file = io.open(path, "w")
                if file then
                    local written = file:write(record)
                    local closed = file:close()
                    if written and closed then output_path = path; return end
                end
            end
            error("No writable speech output path")
        end
        local file, reason = io.open(output_path, "a")
        if not file then error(reason or "open failed") end
        -- Bound the local transport file. The reader detects a changed first record.
        local size = file:seek("end")
        if size and size > 2097152 then file:close(); file = assert(io.open(output_path, "w")) end
        local written, why = file:write(record)
        local closed = file:close()
        if not written or not closed then error(why or "write failed") end
    end)
    if not ok then
        output_failed = true
        pcall(function() ModLog("JAWS pilot output error: " .. tostring(err)) end)
    end
end
local function say(text, kind)
    text = clean(text)
    if text == "" then text = "No readable text available." end
    if kind ~= "repeat" then last_message = text end
    write(kind or "speech", text)
end
local function root()
    if not core:is_ui_created() then error("The game UI is not ready. Try again after the menu appears") end
    local node = core:get_ui_root()
    if not node then error("No game UI root is available") end
    return node
end
local function resolve(path)
    local node = root()
    if node:Visible(true) ~= true then error("Control is no longer visible") end
    for _, step in ipairs(path) do
        node = UIComponent(node:Find(step.index))
        if node:Id() ~= step.id then error("UI layout changed") end
        if node:Visible(true) ~= true then error("Control is no longer visible") end
    end
    if not node:Visible(true) then error("Control is no longer visible") end
    return node
end
local function copy_path(path, i, id)
    local result = {}
    for k, v in ipairs(path) do result[k] = v end
    result[#result + 1] = {index = i, id = id}
    return result
end
local function path_key(path)
    local s = ""
    for _, v in ipairs(path) do s = s .. "/" .. v.index .. ":" .. v.id end
    return s
end
local function within(key, prefix)
    return key == prefix or key:sub(1, #prefix + 1) == prefix .. "/"
end
local function find_panel(id)
    local visited = 0
    local function walk(node, path, depth)
        visited = visited + 1
        if visited > 3000 or depth > 25 or not call(node, "Visible", false, true) then return nil end
        if call(node, "Id", "") == id then return path end
        for i = 0, bounded_child_count(node, 1000) - 1 do
            local child
            local ok = pcall(function() child = UIComponent(node:Find(i)) end)
            if ok and child then
                local found = walk(child, copy_path(path, i, tostring(call(child, "Id", ""))), depth + 1)
                if found then return found end
            end
        end
    end
    return walk(root(), {}, 0)
end
local function check_panel()
    if #panels == 0 then return end
    local path = find_panel(panels[#panels])
    if not path then error("The active panel is not readable yet. Try again, or use the game's Escape key to go back") end
    local prefix = path_key(path)
    if not within(path_key(scope), prefix) then scope = path; parents = {}; clear_pending() end
end
local function describe(node)
    local text = clean(call(node, "GetStateText", ""))
    local tip = clean(call(node, "GetTooltipText", ""))
    local id = tostring(call(node, "Id", "unnamed"))
    if text == "" and tip == "" then
        local function descendant_label(parent, depth)
            if depth <= 0 then return "" end
            for i = 0, bounded_child_count(parent, 12) - 1 do
                local child
                local ok = pcall(function() child = UIComponent(parent:Find(i)) end)
                if ok and child and call(child, "Visible", false, true) then
                    local child_text = clean(call(child, "GetStateText", ""))
                    if child_text ~= "" then return child_text end
                    local child_tip = clean(call(child, "GetTooltipText", ""))
                    if child_tip ~= "" then return child_tip end
                    local nested = descendant_label(child, depth - 1)
                    if nested ~= "" then return nested end
                end
            end
            return ""
        end
        text = descendant_label(node, 2)
    end
    local label = text ~= "" and text or (tip ~= "" and tip or id:gsub("_", " "))
    local state = tostring(call(node, "CurrentState", ""))
    -- WH2 documents SetDisabled but not an IsDisabled getter.
    -- Never enable controls or change their state to make them clickable.
    local disabled = not call(node, "IsInteractive", false)
    local lower = state:lower()
    if lower:find("inactive", 1, true) or lower:find("disabled", 1, true)
        or lower:find("unavailable", 1, true) then disabled = true end
    return label, tip, state, disabled
end
local function actionable(node)
    if not call(node, "IsInteractive", false) then return false end
    local id = tostring(call(node, "Id", "")):lower()
    -- Interactive layout/movie containers occur in the real frontend tree.
    -- Keep walking them, but do not offer them as activation targets.
    if id == "layout" or id == "movie" or id == "main" or id == "root" then return false end
    if id == "button_txt" or id == "title" or id == "version_number" or id:match("^icon_") then return false end
    if id:find("button", 1, true) or id:match("^btn_") then return true end
    if call(node, "ChildCount", 0) == 0 then
        return clean(call(node, "GetStateText", "")) ~= ""
            or clean(call(node, "GetTooltipText", "")) ~= ""
    end
    return call(node, "NumStates", 0) > 1
end
local function scan()
    local result, visited = {}, 0
    scan_issue, scan_nodes = nil, 0
    check_panel()
    local base = resolve(scope)
    local function walk(node, path, depth)
        if visited >= 3000 or #result >= 400 or depth > 25 then return end
        visited = visited + 1
        if not call(node, "Visible", false, true) then return end
        -- Traverse before label extraction/classification, as in the working diagnostic.
        local count = bounded_child_count(node, 1000)
        for i = 0, count - 1 do
            local child
            local ok = pcall(function() child = UIComponent(node:Find(i)) end)
            if ok and child then walk(child, copy_path(path, i, tostring(call(child, "Id", ""))), depth + 1) end
        end
        local label, tip, state, disabled = describe(node)
        local interactive = call(node, "IsInteractive", false)
        local raw = clean(call(node, "GetStateText", ""))
        if #path > #scope and ((category == 1 and actionable(node)) or (category == 2 and raw ~= "")) then
            result[#result + 1] = {kind = "ui", id = tostring(call(node, "Id", "")),
                path = path, key = path_key(path), label = label,
                tip = tip, state = state, disabled = disabled, interactive = interactive,
                address = tostring(call(node, "Address", ""))}
        end
    end
    walk(base, scope, 0)
    scan_nodes = visited
    return result
end
local function shortcuts()
    local list = {
        {"Next selected army or unit", "select_next"}, {"Previous selected army or unit", "select_prev"},
        {"Cancel order or halt selected units", "current_selection_order_cancel"},
        {"Escape or close current dialog", "escape_menu"}
    }
    if mode == "frontend" then list = {{"Escape or close current dialog", "escape_menu"}} end
    local extra = {}
    if mode == "campaign" then
        extra = {{"Province overview", "show_overview"}, {"Garrison", "show_garrison"},
            {"Building browser", "show_building_browser"}, {"Recruit units", "show_recruitment_units"},
            {"Recruit agents", "show_recruitment_agents"}, {"Research", "show_technologies"},
            {"Diplomacy", "show_diplomacy"}, {"Objectives", "show_objectives"},
            {"Finances", "show_finance"}, {"Zoom to selection", "home_zoom"}, {"End turn", "end_turn"}}
    elseif mode == "battle" then
        extra = {{"Select all units", "select_all"}, {"Select melee", "select_all_melee"},
            {"Select ranged", "select_all_ranged"}, {"Select cavalry", "select_all_cavalry"},
            {"Select artillery", "select_all_artillery"}, {"Step selected units forward", "battle_land_step_forward"},
            {"Step selected units backward", "battle_land_step_backwards"},
            {"Move selected units left", "battle_land_strafe_left"}, {"Move selected units right", "battle_land_strafe_right"},
            {"Rotate left", "battle_both_rotate_left"}, {"Rotate right", "battle_both_rotate_right"},
            {"Toggle melee mode", "battle_land_melee"}, {"Toggle run", "battle_land_toggle_run"},
            {"Widen formation", "battle_land_increase_file"}, {"Deepen formation", "battle_land_increase_rank"},
            {"Zoom to selected unit", "unit_zoom"}}
        for i = 1, 6 do extra[#extra + 1] = {"Use ability " .. i .. "; may require a target", "battle_land_special_ability_" .. i} end
    end
    for _, pair in ipairs(extra) do list[#list + 1] = pair end
    local result = {}
    for _, pair in ipairs(list) do result[#result + 1] = {kind = "shortcut", key = pair[2], label = pair[1]} end
    return result
end
local function battle_units(enemy)
    local bm = get_bm()
    local alliances = bm:alliances()
    local local_index, army_index = bm:local_alliance(), bm:local_army()
    local own = alliances:item(local_index)
    local result = {}
    for a = 1, alliances:count() do
        if (enemy and a ~= local_index) or (not enemy and a == local_index) then
            local armies = alliances:item(a):armies()
            for ar = 1, armies:count() do
                if enemy or ar == army_index then
                    local units = armies:item(ar):units()
                    for u = 1, units:count() do
                        local unit = units:item(u)
                        if not enemy or call(unit, "is_visible_to_alliance", false, own) then
                            local name = clean(call(unit, "name", ""))
                            if name == "" then name = tostring(call(unit, "type", "unit")):gsub("_", " ") end
                            local key = tostring(call(unit, "unique_ui_id", a .. ":" .. ar .. ":" .. u))
                            local text = name .. ", soldiers " .. tostring(call(unit, "number_of_men_alive", "unknown"))
                                .. ", ammunition " .. tostring(call(unit, "ammo_left", "unknown"))
                            if call(unit, "is_routing", false) then text = text .. ", routing" end
                            if call(unit, "is_under_missile_attack", false) then text = text .. ", under missile attack" end
                            if call(unit, "is_in_melee", false) then text = text .. ", in melee" end
                            result[#result + 1] = {kind = "report", key = key, label = text}
                        end
                    end
                end
            end
        end
    end
    return result
end
local function refresh()
    if category <= 2 then entries = scan()
    elseif category == 3 then entries = shortcuts()
    else entries = battle_units(category == 5) end
end
local function speak_entry(entry)
    local suffix = entry.disabled and ", disabled" or ""
    if entry.state and entry.state ~= "" then suffix = suffix .. ", " .. entry.state end
    say(names[category] .. ", " .. index .. " of " .. #entries .. ": " .. entry.label .. suffix, "focus")
end
local function navigate(delta)
    local key = entries[index] and entries[index].key
    refresh()
    local old = 0
    for i, entry in ipairs(entries) do if entry.key == key then old = i; break end end
    clear_pending()
    if #entries == 0 then index = 0; say("No entries in " .. names[category] .. ". Scanned " .. scan_nodes .. " UI nodes. " .. (scan_issue or "No UI read errors.") .. ". Use the game's Escape key to go back."); return end
    if old == 0 then index = delta > 0 and 1 or #entries else index = ((old - 1 + delta) % #entries) + 1 end
    speak_entry(entries[index])
end
local function current()
    local entry = entries[index]
    if not entry then error("Use F2 or F3 to choose an item first") end
    if entry.kind == "ui" then
        check_panel()
        if #panels > 0 then
            local panelPath = find_panel(panels[#panels])
            local prefix = panelPath and path_key(panelPath) or "missing panel"
            if not within(entry.key, prefix) then error("Focus is outside the active panel. Browse again") end
        end
        local node = resolve(entry.path)
        if not call(node, "Visible", false, true) then
            clear_pending(); error("Item is no longer visible. Browse again before using it")
        end
        local label, tip, state, disabled = describe(node)
        if entry.address == "" then error("Control identity unavailable. Activation is blocked until it can be verified") end
        if label ~= entry.label or tip ~= entry.tip or state ~= entry.state or disabled ~= entry.disabled
            or tostring(call(node, "Address", "")) ~= entry.address then
            clear_pending(); error("Item changed. Browse again before using it")
        end
        return entry, node
    end
    return entry
end
local function validate_activation(node)
    -- Required reads must fail closed, rather than use browsing fallbacks.
    local values = {}
    for _, method in ipairs({"Visible", "IsInteractive", "CurrentState", "GetStateText", "GetTooltipText", "Address"}) do
        local ok, value = read_native(node, method, true)
        if not ok or value == nil then error("Cannot verify " .. method .. ". Browse again before activating") end
        if method == "Visible" or method == "IsInteractive" then
            if value ~= true then error("Control is hidden, inactive, or unreadable") end
        elseif method == "Address" then
            if type(value) ~= "userdata" and type(value) ~= "string" and type(value) ~= "number" then
                error("Cannot verify control identity")
            end
        elseif type(value) ~= "string" then error("Cannot verify " .. method) end
        values[method] = value
    end
    -- Only the active state observed on the captured Graphics button is eligible.
    if values.CurrentState ~= "active" then error("Control is not in the verified active state") end
end
local function activation_allowed(entry)
    if mode ~= "frontend" then
        return false, "Activation is not enabled in campaign or battle at this development stage."
    end
    if #panels > 0 then
        return false, "Activation is restricted to the captured Graphics settings button with no tracked panel open."
    end
    -- Fail closed against duplicate component IDs on another frontend screen.
    -- This is the exact zero-based path and ancestry captured twice from WH2 1.12.1.
    local graphics_path = {
        {index = 2, id = "main"}, {index = 1, id = "banner_clip"},
        {index = 0, id = "fe_banner"}, {index = 0, id = "menu"},
        {index = 2, id = "options_frame"}, {index = 0, id = "holder"},
        {index = 1, id = "button_graphics"}
    }
    if entry.kind == "ui" and entry.id == "button_graphics" and entry.label == "Graphics"
        and #entry.path == #graphics_path then
        for i, step in ipairs(graphics_path) do
            if entry.path[i].index ~= step.index or entry.path[i].id ~= step.id then
                return false, "Activation is restricted to the captured Graphics settings button in this development stage."
            end
        end
        return true
    end
    return false, "Activation is restricted to the captured Graphics settings button in this development stage."
end
local function activate()
    if not entries[index] then say("Use F2 or F3 to choose an item first."); return end
    local entry, node = current()
    if entry.kind == "report" then say("Report only. Use game actions or unit cards to select units. Map targets are not keyboard accessible in this build."); return end
    if entry.kind == "ui" and (entry.disabled or not call(node, "IsInteractive", false)) then
        say("This item cannot be activated."); return
    end
    local allowed, reason = activation_allowed(entry)
    if not allowed then clear_pending(); say(reason); return end
    validate_activation(node)
    local token = entry.key .. ":" .. generation
    local now = activation_time()
    if pending ~= token or now > pending_until or now < pending_until - 4 then
        pending = entry.key .. ":" .. generation
        pending_until = now + 4
        say("Press F4 again within four seconds to activate " .. entry.label .. ". Any navigation cancels."); return
    end
    clear_pending()
    node:SimulateLClick()
    entries, index = {}, 0
    say("Input sent: " .. entry.label .. ". Read the panel or summary to verify the result.", "result")
end
local function summary()
    if mode == "campaign" then
        local faction = cm:get_local_faction(true)
        say("Campaign. " .. (cm:is_local_players_turn() and "Your turn. " or "Another faction's turn. ")
            .. "Treasury " .. tostring(faction:treasury()) .. ". " .. names[category] .. ". " .. hover)
    elseif mode == "battle" then
        local units = battle_units(false)
        local warnings = {}
        for _, unit in ipairs(units) do
            if unit.label:find("routing", 1, true) or unit.label:find("under missile", 1, true) then
                warnings[#warnings + 1] = unit.label
            end
        end
        say("Battle. " .. #units .. " units in local army report. Shared units may require the normal unit cards. "
            .. (#warnings > 0 and table.concat(warnings, "; ") or "No routing or missile alerts in this report."))
    else say("Main menu. " .. names[category] .. ". F2 next, F3 previous. Graphics is the only staged activation target and requires F4 twice. Control F2 changes category.") end
end
local function reset(text)
    generation = generation + 1
    scope, parents, entries, index = {}, {}, {}, 0
    clear_pending()
    hover = ""
    say(text, "context")
end
local actions = {
    script_F2 = function() navigate(1) end,
    script_F3 = function() navigate(-1) end,
    script_F4 = activate,
    script_shift_F2 = function()
        local entry = current()
        say(entry.label .. ". " .. (entry.tip or "") .. ". " .. (entry.state or ""))
    end,
    script_shift_F3 = function()
        local entry, node = current()
        if entry.kind ~= "ui" or call(node, "ChildCount", 0) == 0 then say("No child controls."); return end
        parents[#parents + 1] = scope; scope = entry.path; entries = {}; index = 0; clear_pending()
        navigate(1)
    end,
    script_shift_F4 = function()
        clear_pending()
        if #parents > 0 then scope = table.remove(parents); entries = {}; index = 0; navigate(1)
        else say("Back action is not enabled in this development stage. Use the game's Escape key.") end
    end,
    script_ctrl_F2 = function()
        category = (category % #names) + 1; scope = {}; parents = {}; entries = {}; index = 0; clear_pending()
        say(names[category] .. ". Press F2 to browse.")
    end,
    script_ctrl_F3 = summary,
    script_ctrl_F4 = function() write("speech", last_message) end
}
local function protect(fn)
    local ok, err = pcall(fn)
    if not ok then
        clear_pending()
        -- UI references are often transient. Return to root on the next browse.
        scope, parents, entries, index = {}, {}, {}, 0
        say("Pilot could not complete that request: " .. tostring(err), "error")
    end
end
core:add_ui_created_callback(function()
    panels = {}
    reset("Game UI recreated. Browse again before activating a control.")
end)
core:add_ui_destroyed_callback(function()
    panels = {}
    reset("Game UI closed. Waiting for the next screen.")
end)
core:add_listener("jaws_access_shortcuts", "ShortcutTriggered", function(context)
    return actions[context.string] ~= nil
end, function(context)
    protect(function()
        if not core:is_ui_created() then error("The game UI is not ready. Try again after the menu appears") end
        actions[context.string]()
    end)
end, true)
core:add_listener("jaws_access_hover", "ComponentMouseOn", true, function(context)
    pcall(function()
        local node = UIComponent(context.component)
        if not node:Visible(true) then return end
        local label, tip = describe(node)
        local text = label .. (tip ~= "" and tip ~= label and (". " .. tip) or "")
        if text ~= hover then hover = text; write("hover", text) end
    end)
end, true)
for _, event in ipairs({"PanelOpenedCampaign", "PanelClosedCampaign"}) do
    local name = event
    core:add_listener("jaws_access_" .. name, name, true, function(context)
        if name == "PanelOpenedCampaign" then
            panels[#panels + 1] = tostring(context.string)
        else
            for i = #panels, 1, -1 do
                if panels[i] == tostring(context.string) then table.remove(panels, i); break end
            end
        end
        reset((name == "PanelOpenedCampaign" and "Panel opened: " or "Panel closed: ") .. tostring(context.string))
    end, true)
end
if mode == "campaign" then
    core:add_listener("jaws_access_first_tick", "FirstTickAfterWorldCreated", true, function()
        protect(function() reset("Campaign ready."); summary() end)
    end, false)
    core:add_listener("jaws_access_turn", "FactionTurnStart", true, function(context)
        protect(function()
            if context:faction():name() == cm:get_local_faction_name(true) then reset("Your turn.") end
        end)
    end, true)
end
if mode == "frontend" then
    say("Accessibility development preview 0.5.2 loaded in the frontend. F2 next, F3 previous. Only Graphics is staged for double-F4 activation; every other action is blocked.", "hello")
else
    say("Accessibility development pilot loaded in " .. mode .. ". This context is read only; F2 and F3 browse and all activation is blocked.", "hello")
end
