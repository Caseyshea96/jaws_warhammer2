-- Synthetic complete tree for bounded read-only discovery tests.
-- This is not a live capture and must never authorize any native activation.
local layout={}
local function node(path,id,count,text,tip,state,visible)
    layout[path]={Id=id,ChildCount=count,GetStateText=text or '',GetTooltipText=tip or '',
        CurrentState=state or 'NewState',Visible=visible~=false,IsInteractive=true}
end
node('tree','root',5)
node('tree.child0','layout',0)
node('tree.child1','watermark_square',0)
node('tree.child2','sp_grand_campaign',6)
node('tree.child3','footer',0)
node('tree.child4','browser',0,'','','',false)
local panel='tree.child2'
node(panel .. '.child0','dockers',4)
node(panel .. '.child0.child0','header_docker',0)
node(panel .. '.child0.child1','top_docker',1)
node(panel .. '.child0.child1.child0','lord_select_list',100)
node(panel .. '.child0.child2','race',0,'High Elves')
node(panel .. '.child0.child3','lord',0,'Tyrion')
node(panel .. '.child1','title',0,'Select Lord')
node(panel .. '.child2','button_start_campaign',0,'Start Campaign','','active')
node(panel .. '.child3','faction',0,'Eataine')
node(panel .. '.child4','campaign_difficulty',0,'Campaign difficulty: Normal')
node(panel .. '.child5','battle_difficulty',0,'Battle difficulty: Normal')
for index=0,99 do
    local path=panel .. '.child0.child1.child0.child' .. index
    node(path,'portrait',3)
    node(path .. '.child0','caption',0,'Synthetic Lord ' .. index)
    node(path .. '.child1','info',0,'','Synthetic description ' .. index)
    node(path .. '.child2','decoration',0)
end
return layout
