local files, listeners, created, destroyed = {}, {}
local ready, bad = true, false
local n = {}
function n:Id() return "root" end
function n:ChildCount() if bad then return function() end end; return 1 end
function n:Find(i) assert(i == 0); return self end
function n:Visible() return true end
function n:IsInteractive() error("unsupported test method") end
function n:GetStateText() return "Menu" end
function n:CurrentState() return "active" end
function n:Address() return newproxy() end
core = {
 is_campaign=function() return false end, is_battle=function() return false end,
 is_ui_created=function() return ready end,
 get_ui_root=function() assert(ready); return n end,
 add_ui_created_callback=function(_,fn) created=fn end,
 add_ui_destroyed_callback=function(_,fn) destroyed=fn end,
 add_listener=function(_,name,event,cond,fn) listeners[event]={cond,fn} end
}
UIComponent=function(v) return v end
io={open=function(path,mode)
 if mode=="w" then files[path]="" end
 return {write=function(_,text) files[path]=(files[path] or "")..text; return true end,close=function() return true end}
end}
effect={trigger_shortcut=function() error("Diagnostic must not send input") end}
function n:SimulateLClick() error("Diagnostic must not click") end
dofile("diagnostics/jaws_access.lua")
local function fire(event,c) local l=listeners[event]; if l and l[1](c) then l[2](c) end end
created()
fire("ShortcutTriggered",{string="script_F4"})
fire("ShortcutTriggered",{string="script_F2"})
fire("ComponentMouseOn",{component=n})
ready=false; destroyed()
fire("ShortcutTriggered",{string="script_F2"})
ready=true; bad=true
fire("ShortcutTriggered",{string="script_F2"})
for i=1,10 do fire("ShortcutTriggered",{string="script_F2"}) end
local text
for path,contents in pairs(files) do if path:find("native%-ui%-diagnostic.log") then text=contents end end
assert(text:find("root.child0.Id.inline.RESULT"))
assert(text:find("root.IsInteractive.ERROR"))
assert(text:find("root.Address.RESULT\tuserdata"))
assert(text:find("root.ChildCount.inline.RESULT\tfunction"))
assert(text:find("root.skipped\tstring\tUI not ready"))
assert(text:find("event.Id.inline.RESULT"))
local _,count=text:gsub("capture.COMPLETE","")
assert(count==6, count)
local original_core = core
core = {is_campaign=function() return true end, is_battle=function() return false end}
local previous = text
dofile("diagnostics/jaws_access.lua")
for path,contents in pairs(files) do if path:find("native%-ui%-diagnostic.log") then assert(contents==previous) end end
core = original_core
print("PASS: bounded read-only captures, lifecycle, event component, raw invalid types, opaque addresses, per-method errors")
