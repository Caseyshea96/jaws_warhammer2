local saved_io,saved_date=io,os.date
local scenarios=0
local nodes,files,listeners,pending,ui_ready,destroyed,dispatches,clock,clicked
local prefix=(os.getenv('LOCALAPPDATA') or '') .. '/JawsWarhammer2/'
local owner=string.rep('a',32)
local valid='WH2CAM1\t' .. owner .. '\t2026-10-29T18:30:00Z\tverify\n'
local timer='warhammer_campaign_readonly_tick'
local function start(context,flag,count)
    scenarios=scenarios+1;nodes={};files={};listeners={};pending=false;ui_ready=true;dispatches=0;clock='2026-10-29T18:00:00Z'
    files[prefix .. 'campaign-discovery.tsv']=flag
    local function node(path,id,children,label,visible)
        local item={path=path,id=id,count=children,label=label or '',visible=visible~=false,address=newproxy(),faults={}}
        local function value(self,method,fallback)
            if self.faults[method]=='throw' then error('Synthetic native failure') end
            if self.faults[method]=='function' then return function() end end
            if self.faults[method]=='nil' then return nil end
            if self.faults[method]=='number' then return 9 end
            return fallback
        end
        function item:Visible() return value(self,'Visible',self.visible) end
        function item:Id() return value(self,'Id',self.id) end
        function item:ChildCount() return value(self,'ChildCount',self.count) end
        function item:GetStateText() return value(self,'GetStateText',self.label) end
        function item:GetTooltipText() return value(self,'GetTooltipText','') end
        function item:CurrentState() return value(self,'CurrentState','active') end
        function item:IsInteractive() return value(self,'IsInteractive',true) end
        function item:Address() return self.address end
        function item:Find(index) return nodes[self.path .. '.child' .. index] end
        function item:SimulateLClick() dispatches=dispatches+1;clicked=self.path end
        nodes[path]=item;return item
    end
    node('tree','root',4)
    node('tree.child0','layout',count or 3)
    for index=0,(count or 3)-1 do node('tree.child0.child' .. index,'control_' .. index,0,'Item ' .. index) end
    node('tree.child1','cinematic_bars',0,'',false)
    node('tree.child2','advice_interface',0,'Advice')
    node('tree.child3','watermark_square',0,'',false)
    core={is_campaign=function() return context=='campaign' end,is_battle=function() return context=='battle' end,
        is_ui_created=function() return ui_ready end,get_ui_root=function() return nodes.tree end,
        add_listener=function(_,name,event,condition,callback,persist) listeners[name]={event,condition,callback,persist} end,
        remove_listener=function(_,name) listeners[name]=nil end,
        add_ui_destroyed_callback=function(_,callback) destroyed=callback end}
    cm=setmetatable({},{__index=function() error('Model-timer/query path must not be used') end})
    real_timer={register_singleshot=function(name,delay) assert(name==timer and (delay==1000 or delay==100));pending=true end,
        unregister=function(name) assert(name==timer);pending=false end}
    UIComponent=function(value) assert(type(value)=='table');return value end
    os.date=function(format) assert(format=='!%Y-%m-%dT%H:%M:%SZ');return clock end
    io={open=function(path,mode)
        if mode=='r' then if not files[path] then return nil end;return {read=function(_,limit) local v=files[path];return type(v)=='string' and v:sub(1,limit) or v end,close=function() return true end} end
        if mode=='w' then files[path]='' end
        return {write=function(self,text) files[path]=(files[path] or '') .. text;return self end,close=function() return true end}
    end}
    dofile('diagnostics/campaign_readonly.lua')
    return node
end
local function fire(event,value)
    local names={};for name in pairs(listeners) do names[#names+1]=name end
    for _,name in ipairs(names) do
        local listener=listeners[name]
        if listener and listener[1]==event and (listener[2]==true or listener[2](value)) then
            if listener[4]==false then listeners[name]=nil end
            listener[3](value)
        end
    end
end
local function begin() fire('FirstTickAfterWorldCreated',{}) end
local function tick(count)
    for n=1,count do
        if not pending then return end
        pending=false;fire('RealTimeTrigger',{string=timer})
    end
end
local function contents(name) return files[prefix .. name] or '' end
local function status() return contents('campaign-discovery-status.json') end
local function finish()
    for n=1,40 do
        tick(1)
        if status():find('"phase":"ready"',1,true) or status():find('"phase":"limited"',1,true) then return end
    end
    error('Capture failed to reach a bounded terminal state: '..status())
end
local function capture_request(token,which_owner,which_session,generation,expires)
    local session=which_session or status():match('"session":"([^"]+)"')
    local wanted=generation or status():match('"generation":(%d+)')
    files[prefix .. 'campaign-discovery-request.tsv']='WH2CAMCAP1\t' .. (which_owner or owner) .. '\t' .. session .. '\t' .. wanted .. '\t' .. token .. '\t' .. (expires or '2026-10-29T18:00:05Z') .. '\n'
end
for _,context in ipairs({'frontend','battle'}) do start(context,valid);assert(next(listeners)==nil and contents('bridge.jsonl')=='') end
for _,flag in ipairs({'','bad',valid:gsub('18:30:00','17:59:59'),valid:gsub('\n$',''),valid:gsub('verify','activate')}) do
    start('campaign',flag);assert(next(listeners)~=nil,'Without a valid flag the player reader starts')
    begin();tick(6);assert(status()=='','Player mode publishes no diagnostic status')
end
start('campaign',valid);begin();finish()
assert(status():find('"complete":true',1,true));assert(status():find('"count":4',1,true))
assert(contents('native-ui-campaign-discovery.jsonl'):find('"physical_keys_verified":false',1,true))
fire('ShortcutTriggered',{string='script_F3'});assert(contents('bridge.jsonl'):find('Item 2, 4 of 4',1,true),contents('bridge.jsonl'))
fire('ShortcutTriggered',{string='script_F4'});assert(dispatches==0)
tick(2);assert(contents('reader-state.tsv'):find('\t1\tcampaign\n',1,true),'Verify mode turns HUD reading on for live key tests')
-- The exact early-scan regression: no text getters while HUD is hidden or bars visible.
start('campaign',valid);nodes['tree.child0'].visible=false;nodes['tree.child1'].visible=true
nodes['tree.child2'].faults.GetStateText='throw';begin();tick(8)
assert(not contents('native-ui-campaign-discovery.jsonl'):find('"kind":"node"',1,true))
assert(contents('bridge.jsonl')=='')
nodes['tree.child0'].visible=true;nodes['tree.child2'].faults.GetStateText=nil;tick(3)
assert(not contents('native-ui-campaign-discovery.jsonl'):find('"kind":"node"',1,true),'Visible cinematic still blocks capture')
nodes['tree.child1'].visible=false;finish();assert(status():find('"complete":true',1,true))
start('campaign',valid);nodes['tree.child0'].visible=false;begin();tick(182)
assert(status():find('"phase":"waiting-timeout"',1,true));assert(not contents('native-ui-campaign-discovery.jsonl'):find('"kind":"node"',1,true))
nodes['tree.child0'].visible=true;capture_request(string.rep('b',32));finish();assert(status():find('"complete":true',1,true))
-- Excluded world-space nodes are labelled, never interrogated for text or children.
local make=start('campaign',valid);nodes.tree.count=5
local world=make('tree.child4','3d_ui_parent',10000,'World text must not be read')
for _,method in ipairs({'GetStateText','GetTooltipText','CurrentState','ChildCount'}) do world.faults[method]='throw' end
begin();finish();assert(status():find('"complete":true',1,true))
assert(contents('native-ui-campaign-discovery.jsonl'):find('"reason":"world-space"',1,true))
assert(not contents('native-ui-campaign-discovery.jsonl'):find('World text must',1,true))
-- Native success and type are independently recorded; no double-counted issue.
for _,fault in ipairs({'nil','function','number','throw'}) do
    start('campaign',valid);nodes['tree.child0.child0'].faults.GetStateText=fault;begin();finish()
    assert(status():find('"errors":1',1,true),status())
    local log=contents('native-ui-campaign-discovery.jsonl')
    assert(log:find('"method":"GetStateText"',1,true))
    assert(log:find('"value_type":"' .. (fault=='throw' and 'nil' or fault) .. '"',1,true))
    assert(log:find('"ok":' .. (fault=='throw' and 'false' or 'true'),1,true))
    assert(not log:find('reader-verification',1,true))
end
start('campaign',valid,80);begin();tick(3);files[prefix .. 'campaign-discovery.tsv']=nil;tick(1)
assert(not pending and status():find('lease-ended',1,true));assert(not listeners[timer])
local before=contents('bridge.jsonl');fire('ShortcutTriggered',{string='script_F2'});assert(contents('bridge.jsonl')==before)
start('campaign',valid,80);begin();tick(3);nodes.tree.address=newproxy();tick(1)
assert(status():find('"phase":"cancelled"',1,true))
start('campaign',valid,80);begin();tick(3);nodes['tree.child0'].address=newproxy();tick(1)
assert(status():find('"phase":"cancelled"',1,true))
start('campaign',valid);nodes['tree.child0.child1'].visible=false;begin();finish()
assert(not contents('native-ui-campaign-discovery.jsonl'):find('Item 1',1,true))
start('campaign',valid,257);begin();finish();assert(status():find('"phase":"limited"',1,true))
start('campaign',valid,80);begin();tick(3);destroyed();tick(1)
assert(status():find('"phase":"cancelled"',1,true));assert(status():find('"count":0',1,true))
start('campaign',valid);ui_ready=false;begin();tick(4);assert(contents('bridge.jsonl')=='')
-- Fresh explicit capture sees changed fields; repeated tokens cannot reread.
start('campaign',valid);begin();finish();nodes['tree.child0.child0'].label='Updated HUD value'
capture_request(string.rep('b',32));finish()
assert(status():find('"attempts":2',1,true));fire('ShortcutTriggered',{string='script_F2'});assert(contents('bridge.jsonl'):find('Updated HUD value',1,true))
local old=status():match('"generation":(%d+)');tick(2)
assert(status():match('"generation":(%d+)')==old,'Same request must not repeat')
capture_request(string.rep('c',32));finish();capture_request(string.rep('d',32));tick(1)
assert(status():find('"result":"capture-limit"',1,true));assert(status():find('"attempts":3',1,true))
for _,bad in ipairs({'owner','session','generation','expired','late-expiry','framing'}) do
    start('campaign',valid);begin();finish()
    if bad=='owner' then capture_request(string.rep('b',32),string.rep('c',32))
    elseif bad=='session' then capture_request(string.rep('b',32),nil,'old-session')
    elseif bad=='generation' then capture_request(string.rep('b',32),nil,nil,'0')
    elseif bad=='expired' then capture_request(string.rep('b',32),nil,nil,nil,'2026-10-29T17:59:59Z')
    elseif bad=='late-expiry' then capture_request(string.rep('b',32),nil,nil,nil,'2026-10-29T18:31:00Z')
    else capture_request(string.rep('b',32));files[prefix .. 'campaign-discovery-request.tsv']=files[prefix .. 'campaign-discovery-request.tsv'] .. 'activate\n' end
    tick(1);assert(status():find('"attempts":1',1,true),'Invalid capture request cannot start a run')
    assert(dispatches==0)
end
start('campaign',valid);real_timer=nil;begin();assert(status():find('"phase":"error"',1,true))
start('campaign',valid);begin();finish();tick(1801);assert(not pending and status():find('lease-ended',1,true),'Independent lifetime bound')
-- 0.6.32: NVDA-style campaign items; values labelled by their tooltips;
-- the hover tooltip layer is left out; long descriptions are not "limited".
local make=start('campaign',valid)
local treasury=nodes['tree.child0.child0']; treasury.id='dy_treasury'; treasury.label='6000'
function treasury:GetTooltipText() return 'Treasury||This is the total amount of money' end
local menu=nodes['tree.child0.child1']; menu.id='button_menu'; menu.label=''
function menu:GetTooltipText() return 'Menu [[col:yellow]] <Esc>[[/col]]' end
local tab=nodes['tree.child0.child2']; tab.id='tab_events'; tab.label=''
function tab:GetTooltipText() return 'Events' end
nodes['tree.child2'].label=string.rep('x',3000)
make('tree.child4','Tooltip',0,'Province: Somewhere'); nodes.tree.count=5
begin();finish()
assert(status():find('"complete":true',1,true) and status():find('"count":4',1,true),status())
for n=1,4 do fire('ShortcutTriggered',{string='script_F2'}) end
local spoken=contents('bridge.jsonl')
assert(spoken:find('Treasury, 6000, 2 of 4, This is the total amount of money',1,true),spoken)
assert(spoken:find('Menu, button, 3 of 4',1,true) and spoken:find('Events, tab, 4 of 4',1,true),spoken)
assert(not spoken:find('Province: Somewhere',1,true) and not spoken:find(', text,',1,true),'Hover tooltip excluded; no "text" role')
assert(contents('native-ui-campaign-discovery.jsonl'):find('"reason":"hover-tooltip"',1,true))
fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==0 and contents('bridge.jsonl'):find('Not supported yet.',1,true),'F4 on text does nothing')
fire('ShortcutTriggered',{string='script_F3'}); fire('ShortcutTriggered',{string='script_F4'})
assert(dispatches==1 and clicked=='tree.child0.child2' and contents('bridge.jsonl'):find('Events activated.',1,true),'Enter/F4 activates the Events tab')
-- 0.6.33: income without brackets, End Turn named, bare counts joined to
-- the item before them, panel titles as headings.
start('campaign',valid,7)
local function set(index,id,label,tip)
    local item=nodes['tree.child0.child' .. index]; item.id=id; item.label=label
    function item:GetTooltipText() return tip or '' end
end
set(0,'tx_(','('); set(1,'dy_income','1901'); set(2,'tx_)',')')
set(3,'button_end_turn','','[[col:red]]Dismiss all advice and related events before ending turn.[[/col]]')
set(4,'dy_title','Missions'); set(5,'child_count','1'); set(6,'counter','2')
begin();finish()
for n=1,8 do fire('ShortcutTriggered',{string='script_F2'}) end
local heard=contents('bridge.jsonl')
assert(heard:find('Income, 1901, ',1,true),heard)
assert(heard:find('End turn, button, ',1,true) and heard:find('Dismiss all advice and related events before ending turn.',1,true),heard)
assert(heard:find('Missions, heading, 1, ',1,true) and heard:find('Unresolved events, 2, ',1,true),heard)
assert(not heard:find('"(, ',1,true) and not heard:find('"text":"(',1,true) and not heard:find('"text":")',1,true),'No bracket items')
assert(status():find('"count":5',1,true),status())
-- 0.6.34: player reader (no flag) and HUD reading mode with companion keys.
start('campaign',nil)
begin()
for n=1,12 do tick(1) end
local heard=contents('bridge.jsonl')
assert(heard:find('Campaign map, 4 items.',1,true),heard)
assert(status()=='' and contents('campaign-discovery-request.tsv')=='','No diagnostic channel for players')
fire('ShortcutTriggered',{string='script_shift_F2'})
assert(contents('reader-state.tsv'):find('\t1\tcampaign\n',1,true),contents('reader-state.tsv'))
assert(contents('bridge.jsonl'):find('Reading HUD.',1,true))
local session=contents('reader-state.tsv'):match('^WH2READER1\t([^\t]+)\t')
local seq=0
local function keys(owner_id,actions)
    local lines={'WH2KEYS1\t' .. owner_id .. '\t' .. session .. '\t1'}
    for _,action in ipairs(actions) do seq=seq+1; lines[#lines+1]=seq .. '\t' .. action end
    files[prefix .. 'keys.tsv']=table.concat(lines,'\n') .. '\n'
    tick(1)
end
local function last_text() return (contents('bridge.jsonl'):match('"text":"([^"]*)"}\n$')) end
keys('companion',{'next'}); local before=last_text()
keys('companion',{'next'}); assert(last_text():find(', 2 of 4',1,true),last_text())
keys('companion',{'last'}); assert(last_text():find(', 4 of 4',1,true),last_text())
keys('companion',{'first'}); assert(last_text():find(', 1 of 4',1,true),last_text())
keys('companion',{'letter:i'}); assert(last_text():find('Item ',1,true)==1,last_text())
keys('companion',{'activate'}); assert(last_text()=='Not supported yet.' and dispatches==0)
keys('companion',{'next'},'other-session')
fire('ShortcutTriggered',{string='script_shift_F2'})
assert(contents('reader-state.tsv'):find('\t0\tcampaign\n',1,true) and last_text()=='Map controls.')
local quiet=contents('bridge.jsonl')
keys('companion',{'next','next'}); assert(contents('bridge.jsonl')==quiet,'Keys are ignored while HUD reading is off')
fire('ShortcutTriggered',{string='script_shift_F3'}); for n=1,10 do tick(1) end
assert(select(2,contents('bridge.jsonl'):gsub('Campaign map, 4 items.',''))==2,'Shift+F3 reads the screen again')
assert(dispatches==0)
-- 0.6.36: a newly shown panel is read automatically, starting at its first
-- new item; a moving hover tooltip never triggers a re-read.
local make=start('campaign',nil)
begin(); for n=1,12 do tick(1) end
assert(contents('bridge.jsonl'):find('Campaign map, 4 items.',1,true))
local panel=make('tree.child4','technology_panel',1,'',true); nodes.tree.count=6
make('tree.child4.child0','tx_title',0,'Technology')
local hover=make('tree.child5','Tooltip',0,'Province: Somewhere',false)
hover.visible=true; tick(4); hover.visible=false; tick(1)
local function updates() return select(2,contents('bridge.jsonl'):gsub('Screen updated%.','')) end
for n=1,12 do tick(1) end
assert(updates()==1,contents('bridge.jsonl'))
assert(contents('bridge.jsonl'):find('Technology, heading, ',1,true),'Starts at the new panel')
local quiet=contents('bridge.jsonl')
hover.visible=true; for n=1,6 do tick(1) end; hover.visible=false; for n=1,6 do tick(1) end
assert(contents('bridge.jsonl')==quiet,'Hover tooltip does not trigger a re-read')
panel.visible=false; for n=1,12 do tick(1) end
assert(updates()==2,'Closing the panel re-reads too')
assert(dispatches==0)
-- 0.6.37: a panel swapped deeper inside the HUD is noticed; blinking is not.
local make=start('campaign',nil)
begin(); for n=1,12 do tick(1) end
local first=nodes['tree.child0.child0']; first.visible=false
local swapped=make('tree.child0.child3','mission_issued',0,'Mission Issued!'); nodes['tree.child0'].count=4
for n=1,14 do tick(1) end
assert(select(2,contents('bridge.jsonl'):gsub('Screen updated%.',''))==1,contents('bridge.jsonl'))
assert(contents('bridge.jsonl'):find('Mission Issued!, ',1,true),'Starts at the swapped-in panel')
local quiet=contents('bridge.jsonl')
for n=1,20 do swapped.visible=(n%2==0); tick(1) end
swapped.visible=true; tick(1)
assert(select(2,contents('bridge.jsonl'):gsub('Screen updated%.',''))<=2,'Blinking does not cause repeated re-reads')
assert(dispatches==0)
-- 0.6.38: HUD buttons and tabs activate after re-verification; End Turn asks;
-- text, toggles, unavailable and changed targets never click.
start('campaign',nil,5)
local function set(index,id,label,tip,state,interactive)
    local item=nodes['tree.child0.child' .. index]; item.id=id; item.label=label or ''
    function item:GetTooltipText() return tip or '' end
    if state then function item:CurrentState() return state end end
    if interactive==false then function item:IsInteractive() return false end else function item:IsInteractive() return true end end
end
set(0,'button_diplomacy','','Diplomacy||Negotiate'); set(1,'button_end_turn','','End turn warning')
set(2,'button_rituals','','Rites||Perform rites','inactive'); set(3,'toggle_interrupt_button','','Interventions'); set(4,'dy_title','Missions')
begin(); for n=1,12 do tick(1) end
local function press(times) for n=1,times do fire('ShortcutTriggered',{string='script_F2'}) end end
local function said() return contents('bridge.jsonl'):match('"text":"([^"]*)"}\n$') end
-- Order: Advice (root text), Diplomacy, End turn, Rites, Interventions, Missions.
fire('ShortcutTriggered',{string='script_F4'}); assert(said()=='Not supported yet.' and dispatches==0,'Text is not actionable')
press(1); fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==1 and clicked=='tree.child0.child0' and said()=='Diplomacy activated.',said())
press(1); fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==1 and said()=='End turn? Press Enter again to confirm.',said())
fire('ShortcutTriggered',{string='script_F3'}); fire('ShortcutTriggered',{string='script_F2'})
fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==1,'Moving away cancelled the confirmation')
fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==2 and clicked=='tree.child0.child1' and said()=='End turn activated.',said())
press(1); fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==2 and said()=='Rites is unavailable.',said())
press(1); fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==2 and said()=='Not supported yet.','Toggles stay read only')
press(1); fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==2,'Headings are not actionable')
-- A replaced target is re-read, never clicked.
start('campaign',nil,2)
set(0,'button_diplomacy','','Diplomacy')
begin(); for n=1,12 do tick(1) end
press(1); nodes['tree.child0.child0'].id='button_other'
fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==0 and said()=='The screen changed. Reading it again.',said())
assert(contents('native-ui-campaign-discovery.jsonl'):find('"kind":"activation-blocked","reason":"identity"',1,true))
-- 0.6.40: a new dialog starts at its title/text; advisor text is announced live.
local make=start('campaign',nil,2)
local advisor=nodes['tree.child0.child0']; advisor.id='Text'; advisor.label='First advice.'
begin(); for n=1,12 do tick(1) end
advisor.label='Second advice.'; tick(1)
assert(contents('bridge.jsonl'):find('Advisor: Second advice.',1,true),contents('bridge.jsonl'))
local quiet=contents('bridge.jsonl'); tick(3); assert(contents('bridge.jsonl')==quiet,'Unchanged text is not repeated')
local dialog=make('tree.child4','mission_dialog',3,'',true); nodes.tree.count=5
make('tree.child4.child0','button_next',0,'Next')
make('tree.child4.child1','dy_title',0,'Mission Issued!')
make('tree.child4.child2','description',0,'Research a technology.')
for n=1,14 do tick(1) end
local after=contents('bridge.jsonl'):match('Screen updated%.".-"text":"([^"]*)"')
assert(after and after:find("Mission Issued!, heading",1,true)==1,contents("bridge.jsonl"):sub(-700))
assert(dispatches==0)
-- 0.6.41: unlabelled buttons get names from their IDs (advisor Close).
local make=start('campaign',nil,1)
local advice=make('tree.child4','advice_interface',1,'',true); nodes.tree.count=5
make('tree.child4.child0','button_close',0,'',true)
make('tree.child0.child0','button_overlay_test',0,'',true)
begin(); for n=1,12 do tick(1) end
for n=1,4 do fire('ShortcutTriggered',{string='script_F2'}) end
local heard=contents('bridge.jsonl')
assert(heard:find('Close advice, button, ',1,true),heard)
assert(not heard:find('Overlay test',1,true),'Test buttons stay hidden')
fire('ShortcutTriggered',{string='script_F3'})
for n=1,4 do if contents('bridge.jsonl'):match('"text":"([^"]*)"}\n$'):find('Close advice',1,true)==1 then break end; fire('ShortcutTriggered',{string='script_F2'}) end
fire('ShortcutTriggered',{string='script_F4'}); assert(clicked=='tree.child4.child0','Close advice can be pressed')
io=saved_io;os.date=saved_date
print('PASS: ' .. scenarios .. ' campaign diagnostic scenarios; HUD readiness, scoped discovery, typed failures, capture protocol, replay/generation/lease guards, limits, cancellation and zero clicks')
