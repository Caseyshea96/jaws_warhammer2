-- Read-only campaign HUD reader. Players get it without a flag; the developer
-- flag adds the status/request channel and its limits. Never queries the
-- model or sends game commands.
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
local diagnostic=initial~=nil
if not diagnostic then owner,expiry,mode='player','9999-12-31T23:59:59Z','player' end
local session='campaign:' .. owner .. ':' .. tostring({})
local version='0.6.35'
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
local verified_reader=false
local auto_reader=false -- verify-mode HUD reading keeps the one-second pace
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
local function lease_active()
    if not diagnostic then return core:is_campaign() end
    return core:is_campaign() and read_flag()==initial
end
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
local function text(value) return type(value)=='string' and bounded(value,4000) or '' end
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
    if not quiet then
        local id=type(item.id)=='string' and item.id or ''
        local role=(string.sub(id,1,7)=='button_' and 'button') or (string.sub(id,1,4)=='tab_' and 'tab')
            or (string.sub(id,1,7)=='toggle_' and 'toggle button') or (id=='3D_advisor_portrait' and 'button')
            or ((id=='dy_title' or id=='tx_title') and 'heading') or nil
        local parts={item.name}
        if role then parts[#parts+1]=role end
        if item.value and item.value~='' then parts[#parts+1]=item.value end
        parts[#parts+1]=index .. ' of ' .. #entries
        if item.description and item.description~='' then parts[#parts+1]=item.description end
        speak(table.concat(parts,', '))
    end
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
    verified_reader=true -- developer verify mode then turns HUD reading on (Shift+F2 cannot be injected)
end
-- Labels for HUD elements whose own text is only a value or whose tooltip is
-- a warning rather than a name (from the 0.6.32 live capture).
local value_labels={dy_income='Income',counter='Unresolved events'}
local name_labels={button_end_turn='End turn',button_skip='Skip',['3D_advisor_portrait']='Repeat advice'}
local punctuation={['(']=true,[')']=true}
local function is_number(value)
    if value=='' then return false end
    for position=1,#value do
        local byte=string.byte(value,position)
        if not (byte>=48 and byte<=57) and byte~=44 and byte~=45 and byte~=43 then return false end
    end
    return true
end
local excluded={['3d_ui_parent']='world-space',['character_map_path_icons']='world-space',
    ['watermark_square']='visual-only',['black_fade']='visual-only',['cinematic_bars']='visual-only',
    ['Tooltip']='hover-tooltip'}
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
                    elseif type(value)=='string' and #value>4000 then issue(item.label,method,ok,value,nil,'text-limit') end
                end
                local label,tip,state=text(values.GetStateText),text(values.GetTooltipText),text(values.CurrentState)
                local count=values.ChildCount
                if type(count)~='number' then count=0
                elseif count~=count or count<0 or count%1~=0 then issue(item.label,'ChildCount',true,count,nil,'invalid-count');count=0 end
                emit('{"kind":"node","run":' .. run .. ',"page":' .. page .. ',"path":' .. quoted(item.label) .. ',"id":' .. quoted(id)
                    .. ',"text":' .. quoted(label) .. ',"tooltip":' .. quoted(tip) .. ',"state":' .. quoted(state) .. ',"children":' .. count
                    .. ',"text_type":' .. quoted(types.GetStateText) .. ',"tooltip_type":' .. quoted(types.GetTooltipText)
                    .. ',"state_type":' .. quoted(types.CurrentState) .. ',"children_type":' .. quoted(types.ChildCount) .. '}')
                local name,tooltip=clean(label),clean(tip)
                -- Tooltips read "Name||Description"; a value with a tooltip is
                -- one item: "Treasury, 6000, This is the total amount ...".
                local tip_name,tip_description=tooltip,''
                for position=1,#tooltip-1 do
                    if string.byte(tooltip,position)==124 and string.byte(tooltip,position+1)==124 then
                        tip_name=clean(string.sub(tooltip,1,position-1)); tip_description=clean(string.sub(tooltip,position+2)); break
                    end
                end
                local entry_name,value,description=name,'',''
                if name~='' and tip_name~='' and tip_name~=name then entry_name,value,description=tip_name,name,tip_description
                elseif name=='' then entry_name,description=tip_name,tip_description end
                if name_labels[id] then
                    -- The tooltip is a warning ("Dismiss all advice ..."): keep it as the description.
                    if entry_name~=name_labels[id] then description=tooltip end
                    entry_name,value=name_labels[id],(name~='' and name~=tooltip) and name or ''
                elseif value_labels[id] and value=='' and name~='' then entry_name,value=value_labels[id],name end
                local previous=entries[#entries]
                if punctuation[entry_name] and value=='' then entry_name=''
                elseif value=='' and description=='' and is_number(entry_name) and previous and (previous.value or '')=='' then
                    -- A bare count belongs to the item before it: "Missions, 1".
                    previous.value=entry_name; entry_name=''
                end
                if entry_name~='' then
                    if #entries>=512 then limit('entry-budget',item.label,#entries)
                    else entries[#entries+1]={key='campaign:' .. item.label .. ':' .. (name~='' and 'text' or 'tooltip'),
                        name=entry_name,value=value,description=description,id=id} end
                end
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
        speak('Campaign map, ' .. #entries .. ' items.' .. (limited and ' Some text could not be read.' or ''))
        browse(1,false)
    end
end
request_capture=function(source)
    if diagnostic and attempts>=3 then result='capture-limit';return false end
    -- Players can re-read for a whole session: start the log over when large.
    if not diagnostic and bytes>1048576 then bytes=0 end
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
            speak('Reading the campaign map.');return
        end
    else stable_ticks=0;stable_identity=nil end
    if reason~=last_readiness then
        emit('{"kind":"readiness","generation":' .. generation .. ',"reason":' .. quoted(reason) .. '}');last_readiness=reason
    end
    if waiting_ticks>=180 then phase='waiting-timeout';result='hud-timeout';emit('{"kind":"timeout","generation":' .. generation .. ',"reason":"hud-not-ready"}') end
end
publish_status=function()
    if not diagnostic then return end
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
    if not diagnostic then return end
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
-- HUD reading mode (Shift+F2), like a screen reader's browse mode: while on,
-- the companion's standard keys (arrows, Home/End, letters, Enter) read HUD
-- items; while off, they stay with the game (arrows move the camera).
local reader_mode=false
local keys_owner,keys_seq,state_line,state_ticks,fast_ticks=nil,0,nil,0,0
local function publish_reader_state(force)
    local line='WH2READER1\t' .. session .. '\t' .. generation .. '\t' .. (reader_mode and '1' or '0') .. '\tcampaign\n'
    state_ticks=state_ticks+1
    -- The companion needs a heartbeat under 3 s old: about every second.
    if not force and line==state_line and state_ticks<((reader_mode and auto_reader) and 1 or 10) then return end
    state_ticks=0
    local f=io.open(base .. 'reader-state.tsv','w'); if not f then return end
    f:write(line); f:close(); state_line=line
end
local function speak_current()
    if not finished then
        if phase~='waiting' and phase~='scanning' then request_capture('keyboard') end
        return
    end
    browse(index==0 and 1 or 0,false)
end
local function key_action(action)
    if action=='next' or action=='previous' then
        if finished then browse(action=='next' and 1 or -1,false) else speak_current() end
    elseif action=='first' or action=='last' then
        if finished then index=0; browse(action=='first' and 1 or -1,false) else speak_current() end
    elseif action=='activate' then speak('Not supported yet.')
    elseif #action==8 and action:sub(1,7)=='letter:' then
        if not finished or #entries==0 then speak_current(); return end
        local letter=action:sub(8,8)
        for offset=1,#entries do
            local candidate=((index-1+offset)%#entries)+1
            if string.lower(entries[candidate].name:sub(1,1))==letter then index=candidate-1; browse(1,false); return end
        end
    end
end
local function poll_keys()
    local raw=read_file('keys.tsv',4097)
    if type(raw)~='string' or #raw>4096 then return end
    local lines={}
    for line in raw:gmatch('([^\n]*)\n') do lines[#lines+1]=line end
    local header_owner,header_session=(lines[1] or ''):match('^WH2KEYS1\t([^\t]+)\t([^\t]+)\t[^\t]+$')
    if not header_owner then return end
    local events,newest={},0
    for position=2,math.min(#lines,33) do
        local number,action=lines[position]:match('^(%d+)\t([a-z:]+)$')
        number=tonumber(number)
        if number then events[#events+1]={seq=number,action=action}; if number>newest then newest=number end end
    end
    if header_owner~=keys_owner then keys_owner,keys_seq=header_owner,newest; return end -- skip any backlog
    if header_session~=session then keys_seq=math.max(keys_seq,newest); return end
    table.sort(events,function(a,b) return a.seq<b.seq end)
    local handled=0
    for _,event in ipairs(events) do
        if event.seq>keys_seq and handled<8 then keys_seq=event.seq; handled=handled+1; key_action(event.action) end
    end
    if newest>keys_seq then keys_seq=newest end
end
local function tick()
    if not polling then return end
    local ok,err=pcall(function()
        -- Capture work keeps its one-second pace; keys are polled every 100 ms
        -- while HUD reading is on.
        fast_ticks=fast_ticks+1
        if not reader_mode or auto_reader or fast_ticks>=10 then
            fast_ticks=0
            ticks=ticks+1
            if not lease_active() or (diagnostic and ticks>1800) then stop('lease-ended');publish_status();return end
            read_request()
            if phase=='waiting' then waiting_step() elseif phase=='scanning' then page_read() end
            publish_status()
        end
        if verified_reader and not reader_mode then
            verified_reader=false; reader_mode=true; auto_reader=true; keys_owner=nil
            emit('{"kind":"reader-mode","on":true,"source":"verify-flag"}'); publish_reader_state(true)
        end
        if reader_mode then poll_keys() end
        publish_reader_state(false)
        if polling then real_timer.register_singleshot(timer_name,(reader_mode and not auto_reader) and 100 or 1000) end
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
        or c.string=='script_shift_F2' or c.string=='script_shift_F3'
end,function(c)
    if not lease_active() then return end
    local ok,err=pcall(function()
        if c.string=='script_shift_F2' then
            reader_mode=not reader_mode; auto_reader=false; keys_owner=nil -- a fresh mode never replays old keys
            publish_reader_state(true)
            speak(reader_mode and 'Reading HUD.' or 'Map controls.')
            if reader_mode then speak_current() end
            if polling then pcall(function() real_timer.unregister(timer_name); real_timer.register_singleshot(timer_name,reader_mode and 100 or 1000) end) end
        elseif c.string=='script_shift_F3' then
            if phase~='waiting' and phase~='scanning' then request_capture('keyboard-refresh') end
        elseif c.string=='script_F4' then speak('Not supported yet.')
        elseif finished then browse(c.string=='script_F2' and 1 or -1,false)
        elseif phase~='waiting' and phase~='scanning' then request_capture('keyboard') end
        publish_status()
    end)
    if not ok then stop('keyboard-error');pcall(publish_status) end
end,true)
