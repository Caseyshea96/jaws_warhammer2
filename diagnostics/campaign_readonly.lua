-- Opt-in HUD/dialog discovery. This module never queries the model or sends game commands.
if not core:is_campaign() or core:is_battle() then return end
local base=os.getenv('LOCALAPPDATA')
if type(base)~='string' or base=='' then return end
base=base .. '/JawsWarhammer2/'
local function utc() return os.date('!%Y-%m-%dT%H:%M:%SZ') end
local function stamp(value)
    return type(value)=='string' and value:match('^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$')~=nil
end
local function read_file(name,limit)
    local f=io.open(base .. name,'r'); if not f then return nil end
    local value=f:read(limit); f:close(); return value
end
local function read_flag()
    local raw=read_file('campaign-discovery.tsv',256)
    if type(raw)~='string' then return nil end
    local owner,expires,mode=raw:match('^WH2CAM1\t([a-f0-9]+)\t([^\t\r\n]+)\t([a-z]+)\n$')
    local now=utc()
    if not owner or #owner~=32 or not stamp(expires) or not stamp(now) or now>expires
        or (mode~='capture' and mode~='verify') then return nil end
    return raw,owner,expires,mode
end
local initial,owner,expiry,mode=read_flag()
if not initial then return end
local session='campaign:' .. owner .. ':' .. tostring({})
local version='0.6.31'
local sequence,generation,bytes,run,attempts=0,1,0,0,0
local phase,result,last_request='initialising','ready',''
local queue,head,visited,page,entries,index={},1,0,0,{},0
local limited,errors,finished=false,0,false
local root_identity,layout_identity,stable_identity,root_count
local waiting_ticks,stable_ticks,ticks=0,0,0
local timer_name='warhammer_campaign_readonly_tick'
local polling=false
local seen_requests={}
local request_count=0
local last_request_raw,last_readiness
local reported_limits={}
local publish_status,request_capture
local function quoted(value)
    return '"' .. tostring(value):gsub('[%z\1-\31\\"]',function(c)
        return string.format('\\u%04x',string.byte(c))
    end) .. '"'
end
local function bounded(value,maximum)
    if #value<=maximum then return value end
    return value:sub(1,maximum):gsub('[\192-\255][\128-\191]*$','')
end
local function emit(line)
    if bytes+#line+2>2097152 then error('Campaign discovery log budget reached') end
    local f=io.open(base .. 'native-ui-campaign-discovery.jsonl',bytes==0 and 'w' or 'a')
    if not f then error('Campaign discovery log unavailable') end
    local written=f:write(line .. '\n'); local closed=f:close()
    if not written or closed==nil then error('Campaign discovery log write failed') end
    bytes=bytes+#line+2
end
local function speak(text)
    sequence=sequence+1
    local f=io.open(base .. 'bridge.jsonl','a'); if not f then return end
    f:write('{"version":1,"session":' .. quoted(session) .. ',"sequence":' .. sequence
        .. ',"generation":' .. generation .. ',"context":"campaign","kind":"speech","text":' .. quoted(text) .. '}\n')
    f:close()
end
local function read(fn)
    local value
    local ok,err=pcall(function() value=fn() end)
    return ok,value,err
end
local function identity(node)
    local ok,address=read(function() local v=node:Address(); return v end)
    if ok and (type(address)=='userdata' or type(address)=='string') then return tostring(address) end
end
local function lease_active() return core:is_campaign() and read_flag()==initial end
local function clean(value)
    return value:gsub('%[%[.-%]%]',' '):gsub('<[^>]*>',' '):gsub('[%z\1-\31]',' ')
        :gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$','')
end
local function issue(path,method,ok,value,err,reason)
    errors=errors+1; limited=true
    emit('{"kind":"read-issue","run":' .. run .. ',"generation":' .. generation .. ',"page":' .. page
        .. ',"path":' .. quoted(path) .. ',"method":' .. quoted(method) .. ',"ok":' .. tostring(ok)
        .. ',"expected_type":' .. quoted(method=='ChildCount' and 'number' or 'string')
        .. ',"value_type":' .. quoted(type(value)) .. ',"reason":' .. quoted(reason or 'return-type')
        .. ',"error":' .. quoted(type(err)=='string' and bounded(err,300) or '') .. '}')
end
local function limit(reason,path,value)
    limited=true
    if reported_limits[reason] then return end
    reported_limits[reason]=true
    emit('{"kind":"limit","run":' .. run .. ',"page":' .. page .. ',"reason":' .. quoted(reason)
        .. ',"path":' .. quoted(path) .. ',"value":' .. value .. '}')
end
local function text(value) return type(value)=='string' and bounded(value,1000) or '' end
-- Reading IDs/visibility of root children reveals no hidden text. The game's
-- campaign UI library places its HUD under "layout"; the last live capture
-- showed this hidden while cinematic_bars was visible.
local function hud_context()
    if not core:is_ui_created() then return nil,'ui-not-created' end
    local ok,root=read(function() local v=core:get_ui_root(); return v end)
    if not ok or not root then return nil,'root-unavailable' end
    local _,id=read(function() local v=root:Id(); return v end)
    local _,visible=read(function() local v=root:Visible(true); return v end)
    local _,count=read(function() local v=root:ChildCount(); return v end)
    if id~='root' or visible~=true or type(count)~='number' or count<0 or count>100 or count%1~=0 then return nil,'root-shape' end
    local layout,layout_visible,bars,loading=nil,false,false,false
    for i=0,count-1 do
        local found,address=read(function() local v=root:Find(i); return v end)
        if not found or not address then return nil,'root-child-missing' end
        local converted,node=read(function() local v=UIComponent(address); return v end)
        if not converted or not node then return nil,'root-child-conversion' end
        local _,child_id=read(function() local v=node:Id(); return v end)
        local _,shown=read(function() local v=node:Visible(true); return v end)
        if type(child_id)~='string' or type(shown)~='boolean' then return nil,'root-child-type' end
        if child_id=='layout' then
            if layout then return nil,'duplicate-layout' end
            layout=node; layout_visible=shown
        elseif child_id=='cinematic_bars' and shown then bars=true
        elseif (child_id=='campaign' or child_id=='custom_loading_screen') and shown then loading=true end
    end
    if loading then return nil,'loading-screen' end
    if bars then return nil,'cinematic-visible' end
    if not layout or not layout_visible then return nil,'hud-hidden' end
    local root_address,layout_address=identity(root),identity(layout)
    if not root_address or not layout_address then return nil,'identity-unavailable' end
    return {root=root,root_address=root_address,layout_address=layout_address,count=count}
end
local function resolve(root,path,ids)
    local node=root
    for depth,child_index in ipairs(path) do
        local ok,visible=read(function() local v=node:Visible(true); return v end)
        if not ok or visible~=true then return nil,ok and 'hidden' or 'visibility-error' end
        local found,address=read(function() local v=node:Find(child_index); return v end)
        if not found or not address then return nil,'missing' end
        local converted,child=read(function() local v=UIComponent(address); return v end)
        if not converted or not child then return nil,'conversion' end
        node=child
        if ids[depth] then
            local _,id=read(function() local v=node:Id(); return v end)
            if id~=ids[depth] then return nil,'changed' end
        end
    end
    local ok,visible=read(function() local v=node:Visible(true); return v end)
    if not ok or visible~=true then return nil,ok and 'hidden' or 'visibility-error' end
    return node
end
local function cancel(reason)
    generation=generation+1; phase='cancelled'; result=reason
    finished=false; entries={}; queue={}; index=0
    emit('{"kind":"cancelled","run":' .. run .. ',"generation":' .. generation .. ',"reason":' .. quoted(reason) .. '}')
end
local function move_cursor(step)
    if index==0 then index=step>0 and 1 or #entries else index=((index-1+step)%#entries)+1 end
    return entries[index]
end
local function browse(step,quiet)
    if not lease_active() or not finished then return false end
    local context=hud_context()
    if not context or context.root_address~=root_identity or context.layout_address~=layout_identity or context.count~=root_count then cancel('hud-changed');return false end
    if #entries==0 then if not quiet then speak('No readable campaign text.') end;return false end
    local item=move_cursor(step)
    if not quiet then speak(item.name .. ', text, ' .. index .. ' of ' .. #entries .. '.') end
    return item.key
end
local function verify_reader()
    if mode~='verify' or limited or #entries==0 then return end
    index=0
    -- Cursor traversal is pure; normal browse gates are exercised at both wraps.
    for expected=1,#entries do assert(move_cursor(1).key==entries[expected].key,'Reader order changed') end
    assert(browse(1,true)==entries[1].key,'Next wrap failed')
    assert(browse(-1,true)==entries[#entries].key,'Previous wrap failed')
    emit('{"kind":"reader-verification","run":' .. run .. ',"passed":true,"entries":' .. #entries .. ',"source":"native-self-test","physical_keys_verified":false}')
    index=0
end
local excluded={['3d_ui_parent']='world-space',['character_map_path_icons']='world-space',
    ['watermark_square']='visual-only',['black_fade']='visual-only',['cinematic_bars']='visual-only'}
local function page_read()
    local context=hud_context()
    if not context or context.root_address~=root_identity or context.layout_address~=layout_identity or context.count~=root_count then cancel('hud-changed');return end
    local root=context.root
    page=page+1; local examined=0
    while examined<48 and head<=#queue and visited<1536 do
        local item=queue[head];head=head+1;examined=examined+1;visited=visited+1
        local node,reason=resolve(root,item.path,item.ids)
        if node then
            local id_ok,id,id_error=read(function() local v=node:Id();return v end)
            if not id_ok or type(id)~='string' then issue(item.label,'Id',id_ok,id,id_error);id='' end
            if #item.path==1 and excluded[id] then
                emit('{"kind":"excluded","run":' .. run .. ',"page":' .. page .. ',"path":' .. quoted(item.label) .. ',"id":' .. quoted(id) .. ',"reason":' .. quoted(excluded[id]) .. '}')
            else
                local getters={GetStateText=function() local v=node:GetStateText();return v end,
                    GetTooltipText=function() local v=node:GetTooltipText();return v end,
                    CurrentState=function() local v=node:CurrentState();return v end,
                    ChildCount=function() local v=node:ChildCount();return v end}
                local values,types={Id=id},{Id=type(id)}
                for _,method in ipairs({'GetStateText','GetTooltipText','CurrentState','ChildCount'}) do
                    local ok,value,err=read(getters[method]);values[method]=value;types[method]=type(value)
                    local wanted=method=='ChildCount' and 'number' or 'string'
                    if not ok or type(value)~=wanted then issue(item.label,method,ok,value,err)
                    elseif type(value)=='string' and #value>1000 then issue(item.label,method,ok,value,nil,'text-limit') end
                end
                local label,tip,state=text(values.GetStateText),text(values.GetTooltipText),text(values.CurrentState)
                local count=values.ChildCount
                if type(count)~='number' then count=0
                elseif count~=count or count<0 or count%1~=0 then issue(item.label,'ChildCount',true,count,nil,'invalid-count');count=0 end
                emit('{"kind":"node","run":' .. run .. ',"page":' .. page .. ',"path":' .. quoted(item.label) .. ',"id":' .. quoted(id)
                    .. ',"text":' .. quoted(label) .. ',"tooltip":' .. quoted(tip) .. ',"state":' .. quoted(state) .. ',"children":' .. count
                    .. ',"text_type":' .. quoted(types.GetStateText) .. ',"tooltip_type":' .. quoted(types.GetTooltipText)
                    .. ',"state_type":' .. quoted(types.CurrentState) .. ',"children_type":' .. quoted(types.ChildCount) .. '}')
                local function entry(suffix,name)
                    if name=='' then return end
                    if #entries>=512 then limit('entry-budget',item.label,#entries);return end
                    entries[#entries+1]={key='campaign:' .. item.label .. ':' .. suffix,name=name}
                end
                local name,tooltip=clean(label),clean(tip)
                entry('text',name);if tooltip~=name then entry('tooltip',tooltip) end
                if #item.path>=16 and count>0 then limit('depth-budget',item.label,#item.path)
                else
                    if count>100 then limit('child-budget',item.label,count) end
                    for child_index=0,math.min(count,100)-1 do
                        if #queue>=2048 then limit('queue-budget',item.label,#queue);break end
                        local path,ids={},{}
                        for depth,value in ipairs(item.path) do path[depth]=value;ids[depth]=item.ids[depth] end
                        if #path>0 then ids[#path]=id end
                        path[#path+1]=child_index
                        queue[#queue+1]={path=path,ids=ids,label=item.label .. '.child' .. child_index}
                    end
                end
            end
        else
            if reason~='hidden' then errors=errors+1;limited=true end
            emit('{"kind":"skip","run":' .. run .. ',"page":' .. page .. ',"path":' .. quoted(item.label) .. ',"reason":' .. quoted(reason) .. '}')
        end
    end
    finished=head>#queue or visited>=1536
    if visited>=1536 and head<=#queue then limit('node-budget','tree',visited) end
    emit('{"kind":"page","run":' .. run .. ',"page":' .. page .. ',"examined":' .. examined .. ',"total":' .. visited
        .. ',"entries":' .. #entries .. ',"errors":' .. errors .. ',"done":' .. tostring(finished)
        .. ',"complete":' .. tostring(finished and not limited) .. ',"limited":' .. tostring(limited) .. '}')
    if finished then
        phase=limited and 'limited' or 'ready';result='capture-complete';verify_reader()
        speak('Campaign. ' .. #entries .. ' items.' .. (limited and ' Some screen content is unavailable.' or ''))
        browse(1,false)
    end
end
request_capture=function(source)
    if attempts>=3 then result='capture-limit';return false end
    attempts=attempts+1;generation=generation+1;phase='waiting';result='accepted'
    entries={};queue={};index=0;head=1;visited=0;page=0;errors=0;limited=false;finished=false
    waiting_ticks=0;stable_ticks=0;stable_identity=nil;last_readiness=nil;reported_limits={}
    emit('{"kind":"capture-request","generation":' .. generation .. ',"attempt":' .. attempts .. ',"source":' .. quoted(source) .. '}')
    return true
end
local function waiting_step()
    waiting_ticks=waiting_ticks+1
    local context,reason=hud_context()
    if context then
        local signature=context.root_address .. '|' .. context.layout_address .. '|' .. context.count
        stable_ticks=signature==stable_identity and stable_ticks+1 or 1;stable_identity=signature;reason='hud-stabilising'
        if stable_ticks>=2 then
            run=run+1;root_identity=context.root_address;layout_identity=context.layout_address;root_count=context.count
            queue={{path={},ids={},label='tree'}};phase='scanning';result='scanning'
            emit('{"kind":"begin","version":' .. quoted(version) .. ',"session":' .. quoted(session) .. ',"run":' .. run
                .. ',"generation":' .. generation .. ',"read_only":true,"scope":"hud-and-dialogs-excluding-world-space","page_budget":48,"node_budget":1536}')
            speak('Campaign. Reading screen.');return
        end
    else stable_ticks=0;stable_identity=nil end
    if reason~=last_readiness then
        emit('{"kind":"readiness","generation":' .. generation .. ',"reason":' .. quoted(reason) .. '}');last_readiness=reason
    end
    if waiting_ticks>=180 then phase='waiting-timeout';result='hud-timeout';emit('{"kind":"timeout","generation":' .. generation .. ',"reason":"hud-not-ready"}') end
end
publish_status=function()
    local item=entries[index]
    local line='{"protocol":"WH2CAMSTATUS1","version":' .. quoted(version) .. ',"owner":' .. quoted(owner)
        .. ',"session":' .. quoted(session) .. ',"generation":' .. generation .. ',"phase":' .. quoted(phase)
        .. ',"request":' .. quoted(last_request) .. ',"result":' .. quoted(result) .. ',"attempts":' .. attempts
        .. ',"run":' .. run .. ',"count":' .. #entries .. ',"index":' .. index .. ',"errors":' .. errors
        .. ',"complete":' .. tostring(finished and not limited) .. ',"expires":' .. quoted(expiry)
        .. ',"selected_key":' .. quoted(item and item.key or '') .. ',"label":' .. quoted(item and bounded(item.name,800) or '') .. '}\n'
    local f=io.open(base .. 'campaign-discovery-status.json','w');if not f then error('Campaign status unavailable') end
    local written=f:write(line);local closed=f:close();if not written or closed==nil then error('Campaign status write failed') end
end
local function read_request()
    local raw=read_file('campaign-discovery-request.tsv',513)
    if type(raw)~='string' or #raw>512 or raw==last_request_raw then return end
    last_request_raw=raw
    local request_owner,request_session,wanted_generation,token,expires=raw:match('^WH2CAMCAP1\t([a-f0-9]+)\t([^\t\r\n]+)\t(%d+)\t([a-f0-9]+)\t([^\t\r\n]+)\n$')
    if not token or #token~=32 or request_owner~=owner or request_session~=session or seen_requests[token] then return end
    if request_count>=16 then return end
    request_count=request_count+1;seen_requests[token]=true;last_request=token
    if not stamp(expires) or utc()>expires or expires>expiry then result='rejected:expiry'
    elseif wanted_generation~=tostring(generation) then result='rejected:generation'
    else request_capture('read-only-client') end
end
local function stop(reason)
    polling=false;generation=generation+1;phase='cancelled';result=reason;finished=false;entries={};queue={}
    if real_timer then pcall(function() real_timer.unregister(timer_name) end) end
    core:remove_listener(timer_name)
end
local function tick()
    if not polling then return end
    local ok,err=pcall(function()
        ticks=ticks+1
        if not lease_active() or ticks>1800 then stop('lease-ended');publish_status();return end
        read_request()
        if phase=='waiting' then waiting_step() elseif phase=='scanning' then page_read() end
        publish_status()
        if polling then real_timer.register_singleshot(timer_name,1000) end
    end)
    if not ok then
        stop('diagnostic-error');phase='error'
        pcall(function() emit('{"kind":"error","run":' .. run .. ',"detail":' .. quoted(type(err)=='string' and bounded(err,500) or type(err)) .. '}');publish_status() end)
    end
end
core:add_listener('warhammer_campaign_discovery_first_tick','FirstTickAfterWorldCreated',true,function()
    local ok,err=pcall(function()
        if polling then return end
        if not real_timer or type(real_timer.register_singleshot)~='function' or type(real_timer.unregister)~='function' then error('Campaign real_timer unavailable') end
        polling=true
        core:add_listener(timer_name,'RealTimeTrigger',function(c) return c.string==timer_name end,tick,true)
        emit('{"kind":"session","version":' .. quoted(version) .. ',"session":' .. quoted(session) .. ',"read_only":true,"scheduler":"real_timer"}')
        request_capture('first-tick');publish_status();real_timer.register_singleshot(timer_name,1000)
    end)
    if not ok then stop('scheduler-error');phase='error';pcall(function() emit('{"kind":"error","detail":' .. quoted(type(err)=='string' and err or type(err)) .. '}');publish_status() end) end
end,false)
core:add_ui_destroyed_callback(function() if polling then cancel('ui-destroyed');publish_status() end end)
core:add_listener('warhammer_campaign_readonly_keys','ShortcutTriggered',function(c)
    return c.string=='script_F2' or c.string=='script_F3' or c.string=='script_F4'
end,function(c)
    if not lease_active() then return end
    local ok,err=pcall(function()
        if c.string=='script_F4' then speak('Campaign actions are not available.')
        elseif finished then browse(c.string=='script_F2' and 1 or -1,false)
        elseif phase~='waiting' and phase~='scanning' then request_capture('keyboard') end
        publish_status()
    end)
    if not ok then stop('keyboard-error');pcall(publish_status) end
end,true)
