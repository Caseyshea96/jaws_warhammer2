local saved_io,saved_date=io,os.date
local scenarios=0
local nodes,files,listeners,pending,ui_ready,destroyed,dispatches,clock
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
        function item:Address() return self.address end
        function item:Find(index) return nodes[self.path .. '.child' .. index] end
        function item:SimulateLClick() dispatches=dispatches+1;error('Campaign clicks forbidden') end
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
    real_timer={register_singleshot=function(name,delay) assert(name==timer and delay==1000);pending=true end,
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
    start('campaign',flag);assert(next(listeners)==nil,'Invalid/expired flag must not create listeners')
end
start('campaign',valid);begin();finish()
assert(status():find('"complete":true',1,true));assert(status():find('"count":4',1,true))
assert(contents('native-ui-campaign-discovery.jsonl'):find('"physical_keys_verified":false',1,true))
fire('ShortcutTriggered',{string='script_F3'});assert(contents('bridge.jsonl'):find('Item 2, 4 of 4',1,true),contents('bridge.jsonl'))
fire('ShortcutTriggered',{string='script_F4'});assert(dispatches==0)
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
start('campaign',valid,101);begin();finish();assert(status():find('"phase":"limited"',1,true))
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
fire('ShortcutTriggered',{string='script_F4'}); assert(dispatches==0 and contents('bridge.jsonl'):find('Not supported yet.',1,true))
io=saved_io;os.date=saved_date
print('PASS: ' .. scenarios .. ' campaign diagnostic scenarios; HUD readiness, scoped discovery, typed failures, capture protocol, replay/generation/lease guards, limits, cancellation and zero clicks')
