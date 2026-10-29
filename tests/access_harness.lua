-- Exercise a host wrapper that does not forward protected-call return values.
if arg and arg[1] == "host-pcall" then
    local original = pcall
    pcall = function(fn, ...)
        local ok, err = original(fn, ...)
        if not ok then return false, err end
        return true, fn
    end
end
-- Lua 5.1 engine fixtures exercise pilot behavior; these are not in-game tests.
local real_io = io
local real_time = os.time
local test_time = 1000
os.time = function() return test_time end
local records = {}
local keys = {
    "script_F2", "script_F3", "script_F4", "script_shift_F2", "script_shift_F3",
    "script_shift_F4", "script_ctrl_F2", "script_ctrl_F3", "script_ctrl_F4"
}
local function node(id, text, interactive, disabled, visible, children)
    local n = {id=id, text=text, interactive=interactive, disabled=disabled, visible=visible, children=children or {}, clicks=0}
    n.address = newproxy()
    function n:Address() return self.address end
    function n:Id() return self.id end
    function n:GetStateText() return self.text end
    function n:GetTooltipText() return self.tip or "Costs 100 gold" end
    function n:CurrentState() return self.disabled and "inactive" or "active" end
    function n:IsInteractive() return self.interactive end
    function n:Visible() return self.visible end
    function n:ChildCount() return #self.children end
    function n:Find(i) return self.children[i+1] end
    function n:SimulateLClick() self.clicks=self.clicks+1 end
    return n
end
for _, mode in ipairs({"frontend", "campaign", "battle"}) do
    local listeners, commands = {}, {}
    local active_turn, ready = true, true
    local on_created, on_destroyed
    local purchase_text = node("button_txt", mode == "frontend" and "Graphics" or 'Build "café" [[col:red]]\n', true, false, true)
    local purchase = node(mode == "frontend" and "button_graphics" or "button_build", "", true, false, true, {purchase_text})
    purchase.tip = ""
    local disabled = node("disabled", "Unavailable", true, true, true)
    local hidden = node("hidden", "SECRET", true, false, false)
    local label = node("title", "Province", false, false, true)
    local holder_spacer = node("spacer", "", false, false, true)
    local holder = node("holder", "", false, false, true, {holder_spacer, purchase, disabled, hidden, label})
    local options_frame = node("options_frame", "", false, false, true, {holder})
    local menu = node("menu", "", false, false, true,
        {node("menu_spacer_1", "", false, false, true), node("menu_spacer_2", "", false, false, true), options_frame})
    local fe_banner = node("fe_banner", "", false, false, true, {menu})
    local banner_clip = node("banner_clip", "", false, false, true, {fe_banner})
    local main = node("main", "", true, false, true,
        {node("main_spacer", "", false, false, true), banner_clip})
    local movie = node("movie", "", true, false, true)
    -- Unexpected host return types must not abort the whole tree scan.
    function movie:ChildCount() return function() end end
    function movie:NumStates() return function() end end
    local layout = node("layout", "", true, false, true, {movie})
    local duplicate_text = node("button_txt", "Graphics", true, false, true)
    local duplicate_graphics = node("button_graphics", "", true, false, true, {duplicate_text})
    duplicate_graphics.tip = ""
    local ui = node("root", "", false, false, true,
        {layout, node("root_spacer", "", false, false, true), main, duplicate_graphics})
    -- Observed preview symptom: root text may have an unexpected native type.
    -- This must not prevent traversal into otherwise readable child controls.
    function ui:GetStateText() return newproxy() end
    core = {
        is_campaign=function() return mode=="campaign" end,
        is_battle=function() return mode=="battle" end,
        get_ui_root=function() assert(ready, "root read while UI unavailable"); return ui end,
        is_ui_created=function() return ready end,
        add_ui_created_callback=function(_,fn) on_created=fn end,
        add_ui_destroyed_callback=function(_,fn) on_destroyed=fn end,
        add_listener=function(self,name,event,cond,cb,persist) listeners[name]={event,cond,cb,persist} end
    }
    UIComponent=function(x) assert(x,"missing UI pointer"); return x end
    ModLog=function() end
    effect={trigger_shortcut=function(key) commands[#commands+1]=key end}
    cm={is_local_players_turn=function() return active_turn end,
        get_local_faction=function() return {treasury=function() return 1234 end} end,
        get_local_faction_name=function() return "test_faction" end}
    local function collection(items) return {count=function() return #items end,item=function(self,i) return items[i] end} end
    local own_alliance
    local function unit(id,name,visible)
        return {name=function() return name end,unique_ui_id=function() return id end,
            number_of_men_alive=function() return 80 end,ammo_left=function() return 12 end,
            is_visible_to_alliance=function(self,a) assert(a==own_alliance); return visible end,
            is_routing=function() return false end,is_under_missile_attack=function() return true end,
            is_in_melee=function() return false end}
    end
    local wrong_army={units=function() return collection({unit("wrong","OTHER PLAYER",true)}) end}
    local own_army={units=function() return collection({unit("mine","Spearmen",true)}) end}
    own_alliance={armies=function() return collection({wrong_army, own_army}) end}
    local enemy_alliance={armies=function() return collection({{units=function()
        return collection({unit("enemy","Visible enemy",true),unit("secret","HIDDEN ENEMY",false)}) end}}) end}
    get_bm=function() return {local_alliance=function() return 1 end,local_army=function() return 2 end,
        alliances=function() return collection({own_alliance,enemy_alliance}) end} end
    local fail=false
    io={open=function(path,access)
        if fail then return nil,"denied" end
        return {write=function(self,record) records[#records+1]=record; return self end,
            seek=function() return 50 end,close=function() return true end}
    end}
    local function fire(event,context)
        for name,l in pairs(listeners) do
            if l[1]==event and (l[2]==true or l[2](context)) then
                l[3](context); if not l[4] then listeners[name]=nil end
            end
        end
    end
    local function key(k) fire("ShortcutTriggered",{string=k}) end
    dofile("mod/script/_lib/mod/jaws_access.lua")
    -- UI recreation must invalidate selection and pending confirmation.
    key("script_F2"); key("script_F4")
    ready=false; on_destroyed(); key("script_F4")
    assert(purchase.clicks==0 and records[#records]:find("UI is not ready"))
    ready=true; on_created(); key("script_F4")
    assert(purchase.clicks==0)
    -- Same path/text/state, but a replacement native address must not activate.
    key("script_F2"); key("script_F4")
    purchase.address=newproxy()
    key("script_F4"); assert(purchase.clicks==0 and records[#records]:find("Item changed"))
    -- Missing identity cannot silently compare as an empty string.
    purchase.address=nil
    key("script_F2"); key("script_F4"); key("script_F4")
    assert(purchase.clicks==0)
    purchase.address=newproxy()
    on_created()
    local count_method = ui.ChildCount
    ui.ChildCount = function() return function() end end
    key("script_F2")
    assert(records[#records]:find("Scanned 1 UI nodes"))
    assert(records[#records]:find("ChildCount returned function"))
    key("script_F4")
    assert(records[#records]:find("Use F2 or F3") and not records[#records]:find("Pilot could not"))
    ui.ChildCount = count_method
    local before=#records
    key("end_turn"); assert(#records==before)
    key("script_F2"); assert(records[#records]:find('1 of 3'))
    assert(not records[#records]:find('SECRET'))
    key("script_F4"); assert(purchase.clicks==0)
    if mode == "frontend" then
        test_time = test_time - 10
        key("script_F4"); assert(purchase.clicks==0, "clock rollback must require a fresh confirmation")
        test_time = test_time + 5
        key("script_F4"); assert(purchase.clicks==0, "expired confirmation must only re-arm")
        key("script_F2"); key("script_F3"); key("script_F4")
        assert(purchase.clicks==0, "browsing away and back must cancel confirmation")
        key("script_F4"); assert(purchase.clicks==1)
    else
        key("script_F4"); assert(purchase.clicks==0)
        assert(records[#records]:find("not enabled in campaign or battle"))
    end
    on_created(); key("script_F2"); key("script_F4")
    purchase.visible=false
    key("script_F4")
    assert(purchase.clicks==(mode == "frontend" and 1 or 0), "hidden control must not activate")
    assert(records[#records]:find("no longer visible"))
    purchase.visible=true; on_created()
    if mode == "frontend" then
        for _, method in ipairs({"Visible", "IsInteractive", "CurrentState", "GetStateText", "GetTooltipText", "Address"}) do
            local original = purchase[method]
            on_created(); key("script_F2"); key("script_F4")
            purchase[method] = function() error("native read failed") end
            key("script_F4")
            assert(purchase.clicks == 1, method .. " failure must block activation")
            purchase[method] = original
        end
        -- Functions from scalar native reads must never authorize activation.
        for _, method in ipairs({"Visible", "IsInteractive", "CurrentState", "GetStateText", "GetTooltipText", "Address"}) do
            local original = purchase[method]
            purchase[method] = function() return function() end end
            on_created(); key("script_F2"); key("script_F4"); key("script_F4")
            assert(purchase.clicks == 1, method .. " function return must block activation")
            purchase[method] = original
        end
        on_created(); key("script_F2"); key("script_F4")
        holder.visible = false
        key("script_F4")
        assert(purchase.clicks == 1, "hidden ancestor must block activation even if the child reports visible")
        holder.visible = true
        on_created()
        fire("PanelOpenedCampaign", {string="main"})
        key("script_F2"); key("script_F4"); key("script_F4")
        assert(purchase.clicks == 1, "tracked panel must block even an otherwise allowlisted path")
        -- Some reads fail at browse time too: matching fallback values must not authorize a click.
        local original = purchase.GetTooltipText
        purchase.GetTooltipText = function() error("tooltip unavailable") end
        on_created(); key("script_F2"); key("script_F4"); key("script_F4")
        assert(purchase.clicks == 1, "persistent read failure must not pass snapshot equality")
        purchase.GetTooltipText = original
        on_created()
    end
    key("script_F2"); key("script_F4")
    purchase_text.text="Price changed"
    key("script_F4"); assert(purchase.clicks==(mode == "frontend" and 1 or 0), "changed control must not activate")
    key("script_F2"); key("script_F2"); key("script_F4"); key("script_F4")
    assert(disabled.clicks==0)
    key("script_F2"); key("script_F4"); key("script_F4")
    assert(duplicate_graphics.clicks==0, "duplicate Graphics ID outside the captured path must not activate")
    assert(records[#records]:find(mode == "frontend"
        and "restricted to the captured Graphics settings button"
        or "not enabled in campaign or battle"), records[#records])
    fire("PanelOpenedCampaign",{string="dialog"}); key("script_F4")
    assert(purchase.clicks==(mode == "frontend" and 1 or 0), "panel change must clear selection")
    key("script_F2")
    assert(records[#records]:find("active panel is not readable"), "unknown modal must not browse background")
    local dialog_button = node("accept", "Dialog accept", true, false, true)
    ui.children[#ui.children + 1] = node("dialog", "", false, false, true, {dialog_button})
    key("script_F2"); assert(records[#records]:find("1 of 1: Dialog accept"))
    key("script_F4"); key("script_F4"); assert(dialog_button.clicks==0)
    assert(records[#records]:find(mode == "frontend"
        and "restricted to the captured Graphics settings button"
        or "not enabled in campaign or battle"))
    fire("PanelClosedCampaign",{string="dialog"}); table.remove(ui.children)
    key("script_ctrl_F2"); key("script_F2") -- text category
    assert(records[#records]:find('Readable text'))
    key("script_ctrl_F2") -- shortcuts remain readable but cannot be activated yet
    local command_count = #commands
    key("script_F2"); key("script_F4"); key("script_F4")
    assert(#commands==command_count)
    if mode=="campaign" then
        key("script_F3") -- last action when index reset: End turn
        active_turn=false
        key("script_F4"); key("script_F4")
        assert(#commands==command_count)
        assert(records[#records]:find("not enabled in campaign or battle"))
        fire("FirstTickAfterWorldCreated",{})
        assert(records[#records]:find("Treasury 1234"))
    elseif mode=="battle" then
        key("script_ctrl_F2"); key("script_F2")
        assert(records[#records]:find("Spearmen"))
        assert(not records[#records]:find("OTHER PLAYER"))
        key("script_ctrl_F2"); key("script_F2")
        assert(records[#records]:find("Visible enemy"))
        assert(not records[#records]:find("HIDDEN ENEMY"))
        local count=#commands; key("script_F4"); assert(#commands==count)
    end
    fire("ComponentMouseOn",{component=purchase})
    key("script_ctrl_F3"); key("script_ctrl_F4")
    fail=true
    key("script_ctrl_F4"); before=#records; key("script_ctrl_F4"); assert(#records==before)
end
io=real_io
os.time=real_time
for _,r in ipairs(records) do io.write(r) end
