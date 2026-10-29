-- Campaign setup discovery preview, built around the proven diagnostic traversal.
-- Do not overwrite frontend evidence when campaign/battle creates a Lua context.
if core:is_campaign() or core:is_battle() then return end
local sequence, runs = 0, 0
local interaction_revision, activation_outcome, activation_origin = 0, 'blocked', 'keyboard'
local start_automation
local controls, control_index = {}, 0
local control_ids = {
    button_new_campaign = true,
    button_start_campaign = true,
    button_load_campaign = true,
    button_multiplayer_campaign = true,
    button_movie_player = true,
    button_quest_battle = true,
    button_practice_battle = true,
    button_multiplayer_battle = true,
    button_quick_battle = true,
    button_leaderboards = true,
    button_replays = true,
    button_lab_battle = true,
    button_graphics = true,
    button_audio = true,
    [' button_audio'] = true,
    button_controls = true,
    button_ui = true,
    button_gamma = true,
    button_credits = true,
    button_support = true,
    button_tw_academy = true,
    button_tw_blog = true,
    button_quit = true
}
local session = 'graphics-preview:' .. tostring({}) .. ':' .. tostring(os.clock())
local log_path, bridge_path
local log_failed, log_bytes = false, 0
local generation, captured, browse_snapshot, latest_snapshot = 0, false, nil, nil
local pending, scan_active, scan_valid = nil, false, false
local scan_nodes, scan_parts, scan_reads = {}, {}, {}
local snapshot_node_count = 0
local lord_discovery
local announce_prefix = ''
local lord_awaiting -- lord name sent by the last selection, until observed
local screen_kind, awaiting_result = 'unknown', nil
local function cancel() pending = nil end
local function invalidate()
    interaction_revision = interaction_revision + 1
    cancel(); controls, control_index = {}, 0
    lord_discovery=nil; announce_prefix=''
    captured, browse_snapshot = false, nil
    screen_kind = 'unknown'
end
local verified_layout = {
    ["tree"] = {["ChildCount"] = "number:5", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:root", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:layout", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:watermark_square", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2"] = {["ChildCount"] = "number:4", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:main", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:v1.12.1  Build 20428.3256712 (modded)", ["GetTooltipText"] = "string:", ["Id"] = "string:version_number", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:banner_clip", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:fe_banner", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0"] = {["ChildCount"] = "number:4", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:menu", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:min", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:campaigns_frame", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0"] = {["ChildCount"] = "number:6", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:holder", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_header_campaigns", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Campaigns", ["GetTooltipText"] = "string:", ["Id"] = "string:title", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:icon_new_content_alert", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child0.child0.child0.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_new_campaign", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child1.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:New Campaign", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child1.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:icon_new_campaign_alert", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child0.child0.child0.child0.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_start_campaign", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:Continue Campaign", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child3"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_load_campaign", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child3.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:Load Campaign", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child4"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_multiplayer_campaign", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child4.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Multiplayer Campaign", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child5"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_movie_player", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child0.child0.child5.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Movie Viewer", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:min", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:battles_frame", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0"] = {["ChildCount"] = "number:8", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:holder", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_header_battles", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Battles", ["GetTooltipText"] = "string:", ["Id"] = "string:title", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:icon_new_content_alert", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_quest_battle", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Quest Battle", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_practice_battle", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Custom Battle", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child3"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_multiplayer_battle", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child3.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Multiplayer Battle", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child4"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_quick_battle", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child4.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Quick Battle", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child5"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_leaderboards", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child5.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Leaderboards", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child6"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_replays", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child6.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:Replays", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child7"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_lab_battle", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child7.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:The Laboratory", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child7.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:icon_new_content_alert", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child1.child0.child7.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:icon_new_content_alert", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child0.child0.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:min", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:options_frame", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0"] = {["ChildCount"] = "number:8", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:holder", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_header_options", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Options", ["GetTooltipText"] = "string:", ["Id"] = "string:title", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_graphics", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Graphics", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string: button_audio", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Sound", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child3"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_controls", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child3.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Controls", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child4"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_ui", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child4.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Game Settings", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child5"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_gamma", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child5.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Brightness and Gamma", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child6"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_credits", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child6.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Credits", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child7"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_support", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child2.child0.child7.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Support", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child3"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:min", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:dlc_frame", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child3.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_header_dlc", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child3.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Downloadable Content", ["GetTooltipText"] = "string:", ["Id"] = "string:title", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0.child3.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:default", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:content_menu", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child0.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:dlc_button_parent", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Previous theme", ["Id"] = "string:button_prev_theme", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child1.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Next theme", ["Id"] = "string:button_next_theme", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child1.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:The Silence & The Fury", ["GetTooltipText"] = "string:", ["Id"] = "string:dlc_label", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:false"},
    ["tree.child2.child2"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:logo_holder", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:logo", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:mask", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:wipe", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child3"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:inagame_messaging", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child3"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:sp_frame", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:menu_bar", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Total War Academy", ["Id"] = "string:button_tw_academy", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Patch Notes", ["Id"] = "string:button_tw_blog", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BL", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:inactive", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Return to main menu", ["Id"] = "string:button_home", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BR", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Quit", ["Id"] = "string:button_quit", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child4"] = {["ChildCount"] = "number:7", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:browser", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
}

-- Actual 0.6.1 Escape return: a hidden Tooltip occupies child4 and the
-- hidden browser moves to child5. Main-menu input paths remain at child2.
local verified_main_tooltip_layout = {}
for prefix, expected in pairs(verified_layout) do
    local key = prefix == 'tree.child4' and 'tree.child5' or prefix
    local row = {}
    for method, value in pairs(expected) do row[method] = value end
    if prefix == 'tree' then row.ChildCount = 'number:6' end
    verified_main_tooltip_layout[key] = row
end
verified_main_tooltip_layout['tree.child4'] = {
    Id='string:Tooltip', Visible='boolean:false', IsInteractive='boolean:false',
    ChildCount='number:2', CurrentState='string:NewState', GetTooltipText='string:'}
-- Its hidden caption is unrelated to the input targets and may name the
-- previously hovered control. Every actionable field/identity stays exact.
local verified_basic_layout = {
    ["tree"] = {["ChildCount"] = "number:5", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:root", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:layout", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:watermark_square", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:options_graphics", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0"] = {["ChildCount"] = "number:12", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:panel_advanced", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1"] = {["ChildCount"] = "number:7", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:basic_options", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:checkbox_windowed", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Run in window", ["GetTooltipText"] = "string:", ["Id"] = "string:label_txt", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:title_plaque", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Graphics", ["GetTooltipText"] = "string:", ["Id"] = "string:title", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child2"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:ok_cancel_buttongroup", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Accept changes", ["Id"] = "string:button_ok", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child2.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Cancel changes", ["Id"] = "string:button_cancel", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child3"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_advanced_options", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child3.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_clip_parent", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child3.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:wh2", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_overlay", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child3.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Advanced", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child4"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_recommended", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child4.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_clip_parent", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child4.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:wh2", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_overlay", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child4.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Recommended", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child5"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:dropdown_resolution", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child5.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:1280x720", ["GetTooltipText"] = "string:", ["Id"] = "string:dy_selected_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child5.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:popup_menu", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child5.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Resolution", ["GetTooltipText"] = "string:", ["Id"] = "string:label_txt", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child6"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:dropdown_quality", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child6.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Low", ["GetTooltipText"] = "string:", ["Id"] = "string:dy_selected_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child6.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:popup_menu", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:false"},
    ["tree.child2.child1.child6.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Quality", ["GetTooltipText"] = "string:", ["Id"] = "string:label_txt", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2"] = {["ChildCount"] = "number:6", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:resolution_popup", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:false"},
    ["tree.child3"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:sp_frame", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:menu_bar", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Total War Academy", ["Id"] = "string:button_tw_academy", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Patch Notes", ["Id"] = "string:button_tw_blog", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BL", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Return to main menu", ["Id"] = "string:button_home", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BR", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Quit", ["Id"] = "string:button_quit", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child4"] = {["ChildCount"] = "number:7", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:browser", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
}

-- Exact named-node fields from the observed Vortex selection. Empty smoke
-- particles are checked separately as noninteractive, text-free leaf nodes.
local verified_campaign_layout = {
    ["tree"] = {["ChildCount"] = "number:5", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:root", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:layout", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:watermark_square", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:campaign_select", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:docker", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:details", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child0"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie_parent", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie_panel", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie_fader", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child0.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:movie_frame", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:text_panel", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:State", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:campaign_description", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child0.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:MainState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:TextView", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:MainState", ["GetStateText"] = "string:At the heart of the Elven homeland the Great Vortex coils, syphoning the excess magic that spills from the Realm of Chaos; but now, after many millennia, it falters. The Vortex is vulnerable and while some seek to control its great power, others see an opportunity, a chance to prosper and vanquish foes in an unstable, war-ravaged world. Choose a Legendary Lord, fight for all that they desire and lead them to glory!", ["GetTooltipText"] = "string:", ["Id"] = "string:Text", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child0.child0.child1"] = {["ChildCount"] = "number:5", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:vslider", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child0.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:header", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:The Eye of the Vortex", ["GetTooltipText"] = "string:", ["Id"] = "string:label_campaign_name", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:State", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:playable_races", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:header", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Playable Races", ["GetTooltipText"] = "string:", ["Id"] = "string:tx_header", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1"] = {["ChildCount"] = "number:12", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:faction_list", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child0"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:High Elves", ["Id"] = "string:wh2_main_hef_eataine", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child0.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Lizardmen", ["Id"] = "string:wh2_main_lzd_hexoatl", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child1.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child1.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child10"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Greenskins", ["Id"] = "string:wh2_dlc15_grn_broken_axe", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child10.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: The Warden & The Paunch  Left-click to go to your client's store page.", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child10.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child10.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child11"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Wood Elves", ["Id"] = "string:wh2_dlc16_wef_sisters_of_twilight", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child11.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: The Twisted & The Twilight  Left-click to go to your client's store page.", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child11.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child11.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child2"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Dark Elves", ["Id"] = "string:wh2_main_def_naggarond", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child2.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child2.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child3"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Skaven", ["Id"] = "string:wh2_main_skv_clan_mors", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child3.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child3.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child3.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child4"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Vampire Coast", ["Id"] = "string:wh2_dlc11_cst_vampire_coast", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child4.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child4.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child4.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child5"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Tomb Kings", ["Id"] = "string:wh2_dlc09_tmb_khemri", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child5.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child5.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child5.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child6"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:The Empire", ["Id"] = "string:wh2_dlc13_emp_the_huntmarshals_expedition", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child6.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: The Hunter & The Beast  Left-click to go to your client's store page.", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child6.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child6.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child7"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Bretonnia", ["Id"] = "string:wh2_dlc14_brt_chevaliers_de_lyonesse", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child7.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child7.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: Repanse[[col:yellow]] (FREE CONTENT)[[/col]]  Left-click to go to your client's store page.", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child7.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child8"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Beastmen Warherds", ["Id"] = "string:wh2_dlc17_bst_taurox", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child8.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: The Silence & The Fury  Left-click to go to your client's store page.", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child8.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child8.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child9"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Dwarfs", ["Id"] = "string:wh2_dlc17_dwf_thorek_ironbrow", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child9.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child1.child9.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Expand your Total War: WARHAMMER II experience with: Thorek Ironbrow[[col:yellow]] (FREE CONTENT)[[/col]]  Left-click to go to your client's store page.", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child0.child1.child1.child1.child9.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:New content available", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child0.child1.child1.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:overlay", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:list_parent", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:hover", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:wh2_main_great_vortex", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:selected_FX", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:glow", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child0.child1"] = {["ChildCount"] = "number:61", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_particle_emitter", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:template_particle", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child1.child0.child1"] = {["ChildCount"] = "number:4", ["CurrentState"] = "string:selected", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_campaign_entry", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:The Eye of the Vortex", ["GetTooltipText"] = "string:", ["Id"] = "string:label_name", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child1.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Additional content available!", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child0.child1.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child1.child0.child1.child3"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child1.child1"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:hover", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:main_warhammer", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child1.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:selected_FX", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child1.child1.child1"] = {["ChildCount"] = "number:4", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_campaign_entry", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child1.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Mortal Empires", ["GetTooltipText"] = "string:", ["Id"] = "string:label_name", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child1.child1.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Additional content available!", ["Id"] = "string:content_alert_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child0.child1.child1.child1.child2"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:new_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child0.child1.child1.child1.child3"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:free_content_icon", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:title_plaque", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:Select Campaign", ["GetTooltipText"] = "string:", ["Id"] = "string:tx_header", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_frame", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_next", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child0.child0"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_clip_parent", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child0.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:wh2", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:smoke_overlay", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:Continue", ["GetTooltipText"] = "string:", ["Id"] = "string:button_txt", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child2.child2.child1"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_purchase", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child2.child2.child2"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:button_download_free", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
    ["tree.child3"] = {["ChildCount"] = "number:3", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:sp_frame", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0"] = {["ChildCount"] = "number:2", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:menu_bar", ["IsInteractive"] = "boolean:false", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Total War Academy", ["Id"] = "string:button_tw_academy", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child0.child1"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Patch Notes", ["Id"] = "string:button_tw_blog", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BL", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child1.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Return to main menu", ["Id"] = "string:button_home", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child2"] = {["ChildCount"] = "number:1", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:frame_BR", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child3.child2.child0"] = {["ChildCount"] = "number:0", ["CurrentState"] = "string:active", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:Quit", ["Id"] = "string:button_quit", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:true"},
    ["tree.child4"] = {["ChildCount"] = "number:7", ["CurrentState"] = "string:NewState", ["GetStateText"] = "string:", ["GetTooltipText"] = "string:", ["Id"] = "string:browser", ["IsInteractive"] = "boolean:true", ["Visible"] = "boolean:false"},
}

local function quote(v)
    return '"' .. tostring(v):gsub('[%z\1-\31\\"]', function(c)
        return string.format('\\u%04x', string.byte(c))
    end) .. '"'
end
local function append(path, line)
    if path == log_path then
        log_bytes = log_bytes + #line + 2 -- conservatively include Windows CRLF
        if log_bytes > 2097152 then log_failed = true; return end
    end
    local f = io.open(path, 'a')
    if not f then if path == log_path then log_failed = true end; return end
    local written = f:write(line .. '\n'); local closed = f:close()
    if path == log_path and (not written or closed == nil) then log_failed = true end
end
-- Keep the proven logger free of scanner/selection bookkeeping. An error in
-- a capture hook must not also break the diagnostic error-reporting path.
local function log(stage, value)
    if log_path then append(log_path, stage .. '\t' .. type(value) .. '\t' .. tostring(value):sub(1,1000):gsub('[\r\n]', ' ')) end
end
local function speak(text)
    sequence = sequence + 1
    if bridge_path then append(bridge_path, '{"version":1,"session":' .. quote(session)
        .. ',"sequence":' .. sequence .. ',"context":"frontend","generation":' .. generation .. ',"kind":"speech","text":' .. quote(text) .. '}') end
end
local bases = {}
if os.getenv and os.getenv('LOCALAPPDATA') then bases[1] = os.getenv('LOCALAPPDATA') .. '/JawsWarhammer2/' end
bases[#bases + 1] = ''
for _, base in ipairs(bases) do
    local path = base .. 'native-ui-graphics-preview.log'
    local f = io.open(path, 'w')
    if f then
        local header = 'WH2 native UI diagnostic 0.6.23-nvda-automation-preview\n'
        f:write(header); f:close(); log_bytes = #header + 1
        log_path = path; bridge_path = base .. (base == '' and 'jaws_access.jsonl' or 'bridge.jsonl')
        local bridge = io.open(bridge_path, 'w'); if bridge then bridge:close() end
        break
    end
end
log('runtime.string_match', type(string.match))
log('runtime.string_find', type(string.find))
-- Every failed 0.6.15-0.6.17 candidate called s:find(p,1,true) on captured
-- text; 0.6.14 never calls string.find. After the first such call in-game,
-- the next s:sub() returned a non-string. Use string.sub prefix checks only.
local function starts_with(s, prefix)
    return type(s) == 'string' and string.sub(s, 1, #prefix) == prefix
end
-- Fallback that formats nothing, for logging after a failed string call.
local function plain_log(stage, text)
    if log_path then append(log_path, stage .. '\tstring\t' .. (type(text) == 'string' and text or ('non-string ' .. type(text)))) end
end
-- Opt-in confirmation probe, off unless string-find-probe.flag sits beside
-- the log. It may break later string calls, so run it in a separate launch.
if log_path then
    local flag = io.open(string.sub(log_path, 1, #log_path - #'native-ui-graphics-preview.log') .. 'string-find-probe.flag', 'r')
    if flag then
        flag:close()
        local ok, found = pcall(string.find, 'lord:tree.a.b', 'lord:tree.', 1, true)
        plain_log('probe.find', (ok and 'ok ' or 'error ') .. type(found) .. ' ' .. (type(found) == 'number' and (found .. '') or ''))
        local sok, piece = pcall(string.sub, 'abc', 1, 1)
        plain_log('probe.sub_function', (sok and 'ok ' or 'error ') .. type(piece))
        local mok, method = pcall(function() return ('abc'):sub(1, 1) end)
        plain_log('probe.sub_method', (mok and 'ok ' or 'error ') .. type(method))
        local tok, text = pcall(function() return tostring('abc') end)
        plain_log('probe.tostring', (tok and 'ok ' or 'error ') .. type(text))
    end
end
local function observe(name, fn)
    log(name .. '.START', true)
    local value
    local ok, err = pcall(function() value = fn() end)
    -- Store a flat observation; interpret it only after native traversal ends.
    if scan_active then scan_reads[name] = {ok = ok, value = value} end
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
    if children and ok and type(count) == 'number' and count == count and count >= 0 and count % 1 == 0 then
        local limit = count
        if limit > 8 then limit = 8 end
        for i = 0, limit - 1 do
            local prefix = label .. '.child' .. i
            local found, address = observe(prefix .. '.Find', function() local v = node:Find(i); return v end)
            if found and address then
                local converted, child = observe(prefix .. '.Convert', function() local v = UIComponent(address); return v end)
                if converted and child then sample(prefix, child, false) end
            end
        end
    else log(label .. '.children.skipped', 'not requested or invalid count') end
end
local function clean(value)
    if type(value) ~= 'string' then return '' end
    return value:gsub('%[%[.-%]%]', ' '):gsub('<[^>]*>', ' ')
        :gsub('[%z\1-\31]', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
end
local graphics_panel = 'tree.child2'
local basic_panel = graphics_panel .. '.child1'
local function captured_value(prefix, method)
    local read = scan_reads[prefix .. '.' .. method]
    if read and read.ok then return read.value end
    return nil
end
local function visible_id(prefix, id)
    return captured_value(prefix, 'Id') == id and captured_value(prefix, 'Visible') == true
end
local function captured_text(prefix, id)
    if not visible_id(prefix, id) then return '' end
    return clean(captured_value(prefix, 'GetStateText'))
end
-- Both native captures differ only in empty smoke-particle visibility and
-- an extra hidden Tooltip root child. Neither is an input target. Everything
-- named remains in the exact activation template and raw fingerprint.
local campaign_entries = 'tree.child2.child0.child1'
local campaign_continue_key = 'tree.child2.child2.child0'
local function campaign_shell_supported()
    local count = captured_value('tree', 'ChildCount')
    if count ~= 5 and count ~= 6 then return false end
    if count == 6 and (captured_value('tree.child5', 'Id') ~= 'Tooltip'
        or captured_value('tree.child5', 'Visible') ~= false
        or captured_value('tree.child5', 'IsInteractive') ~= false) then return false end
    local particle_parent = campaign_entries .. '.child0.child0.child1.child'
    for name, read in pairs(scan_reads) do
        if name:sub(-3) == '.Id' and read.ok then
            local prefix = name:sub(1,-4)
            local index = tonumber(prefix:sub(#particle_parent+1))
            local particle = prefix:sub(1,#particle_parent) == particle_parent and index and index >= 1
            if read.value == '' or particle then
                if read.value ~= '' or prefix:sub(1,#particle_parent) ~= particle_parent or not index
                    or index < 1 or index > 60 or index % 1 ~= 0
                    or captured_value(prefix,'IsInteractive') ~= false
                    or captured_value(prefix,'ChildCount') ~= 0
                    or captured_value(prefix,'GetStateText') ~= ''
                    or captured_value(prefix,'GetTooltipText') ~= ''
                    or captured_value(prefix,'CurrentState') ~= 'NewState'
                    or type(captured_value(prefix,'Visible')) ~= 'boolean' then return false end
            end
        end
    end
    return true
end
local function scope_campaign_controls()
    controls = {}
    screen_kind = 'campaign_overlay'
    if not campaign_shell_supported() then return end
    screen_kind = 'campaign_selection'
    for i, id in ipairs({'wh2_main_great_vortex','main_warhammer'}) do
        local prefix = campaign_entries .. '.child' .. (i-1)
        local button = prefix .. '.child1'
        if visible_id(prefix,id) and visible_id(button,'button_campaign_entry') then
            local name = captured_text(button .. '.child0','label_name')
            local state = captured_value(button,'CurrentState')
            if name ~= '' then controls[#controls+1] = {key=button, name=name .. ', campaign choice',
                state=type(state)=='string' and state or 'state unavailable', read_only=true} end
        end
    end
    if visible_id(campaign_continue_key,'button_next') then
        local name = captured_text(campaign_continue_key .. '.child1','button_txt')
        local state = captured_value(campaign_continue_key,'CurrentState')
        if name ~= '' then controls[#controls+1] = {key=campaign_continue_key, name=name .. ', button',
            state=type(state)=='string' and state or 'state unavailable', read_only=false} end
    end
    local description = 'tree.child2.child0.child0.child1.child0.child0.child0'
    local text = captured_text(description,'Text')
    if text ~= '' then controls[#controls+1] = {key=description,name='Campaign description: ' .. text,state='',read_only=true} end
    local races = 'tree.child2.child0.child0.child1.child1.child1'
    local ids = {'wh2_main_hef_eataine','wh2_main_lzd_hexoatl','wh2_main_def_naggarond','wh2_main_skv_clan_mors',
        'wh2_dlc11_cst_vampire_coast','wh2_dlc09_tmb_khemri','wh2_dlc13_emp_the_huntmarshals_expedition',
        'wh2_dlc14_brt_chevaliers_de_lyonesse','wh2_dlc17_bst_taurox','wh2_dlc17_dwf_thorek_ironbrow',
        'wh2_dlc15_grn_broken_axe','wh2_dlc16_wef_sisters_of_twilight'}
    for i,id in ipairs(ids) do
        local prefix = races .. '.child' .. (i-1)
        if visible_id(prefix,id) then
            local name = clean(captured_value(prefix,'GetTooltipText'))
            if name ~= '' then controls[#controls+1] = {key=prefix,name='Listed race: ' .. name,state='',read_only=true} end
        end
    end
    if visible_id('tree.child3.child1.child0','button_home') then
        local name = clean(captured_value('tree.child3.child1.child0','GetTooltipText'))
        if name ~= '' then controls[#controls+1] = {key='tree.child3.child1.child0',name=name .. ', use Escape',state='',read_only=true} end
    end
end
local advanced_panel = graphics_panel .. '.child0'
local function scope_advanced_controls()
    screen_kind = 'graphics_advanced'
    local specs = {
        {path = '.child0', id = 'button_benchmarks', label_path = '.child2', label_id = 'button_txt', role = 'button'},
        {path = '.child1.child0', id = 'checkbox_unlimited_memory', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child1', id = 'checkbox_v_sync', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child2', id = 'checkbox_vignette', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child3', id = 'checkbox_proximity_fade', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child5', id = 'checkbox_battery_meter', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child6', id = 'checkbox_ssao', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child1.child7', id = 'checkbox_sharpen', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child2.child0', id = 'dropdown_directx', role = 'dropdown'},
        {path = '.child2.child1', id = 'dropdown_aliasing', role = 'dropdown'},
        {path = '.child2.child2', id = 'dropdown_texture_quality', role = 'dropdown'},
        {path = '.child2.child3', id = 'dropdown_filtering', role = 'dropdown'},
        {path = '.child2.child4', id = 'dropdown_shadows', role = 'dropdown'},
        {path = '.child2.child5', id = 'dropdown_water', role = 'dropdown'},
        {path = '.child2.child7', id = 'dropdown_particle_effects', role = 'dropdown'},
        {path = '.child2.child8', id = 'dropdown_grass', role = 'dropdown'},
        {path = '.child2.child9', id = 'dropdown_trees', role = 'dropdown'},
        {path = '.child2.child10', id = 'dropdown_terrain', role = 'dropdown'},
        {path = '.child2.child11', id = 'dropdown_unit_detail', role = 'dropdown'},
        {path = '.child2.child12', id = 'dropdown_building_detail', role = 'dropdown'},
        {path = '.child2.child13', id = 'dropdown_dop', role = 'dropdown'},
        {path = '.child2.child14', id = 'dropdown_unit_size', role = 'dropdown'},
        {path = '.child2.child15', id = 'dropdown_reflections', role = 'dropdown'},
        {path = '.child2.child16', id = 'dropdown_porthole', role = 'dropdown'},
        {path = '.child2.child18', id = 'dropdown_fog', role = 'dropdown'},
        {path = '.child2.child20', id = 'dropdown_hide_bodies', role = 'dropdown'},
        {path = '.child3', id = 'graphics_card', label_path = '.child0', label_id = 'label_txt', value_path = '.child1', value_id = 'button_txt', role = 'information'},
        {path = '.child4', id = 'video_memory', label_path = '.child0', label_id = 'label_txt', value_path = '.child1', value_id = 'button_txt', role = 'information'},
        {path = '.child7.child0', id = 'button_accept', role = 'button'},
        {path = '.child7.child1', id = 'button_close', role = 'button'},
        {path = '.child10', id = 'resolution_scale_parent', label_path = '.child1', label_id = 'label_tx', value_path = '.child2', value_id = 'label_resolution_scale', role = 'slider'},
        {path = '.child11', id = 'ui_scale', label_path = '.child1', label_id = 'label_tx', value_path = '.child2', value_id = 'scale_percentage_tx', role = 'slider'},
        {path = '.child11.child3', id = 'button_apply_ui_scale', label_path = '.child1', label_id = 'button_txt', role = 'button'}
    }
    -- If the entry capture observes an expanded dropdown, do not read the
    -- underlying Advanced controls as though the popup were closed.
    for _, spec in ipairs(specs) do
        if spec.role == 'dropdown' and captured_value(advanced_panel .. spec.path .. '.child1', 'Visible') == true then
            screen_kind = 'graphics_advanced_overlay'; return
        end
    end
    for _, spec in ipairs(specs) do
        local prefix = advanced_panel .. spec.path
        if visible_id(prefix, spec.id) then
            local name
            if spec.role == 'dropdown' then name = captured_text(prefix .. '.child2', 'label_txt')
            elseif spec.label_path then name = captured_text(prefix .. spec.label_path, spec.label_id)
            else name = clean(captured_value(prefix, 'GetTooltipText')) end
            if name ~= '' then
                if spec.role == 'checkbox' then
                    -- Report native state separately; selected/active alone
                    -- has not established the checkbox's checked semantics.
                    name = name .. ', checkbox, checked state unavailable'
                elseif spec.role == 'dropdown' then
                    local value = captured_text(prefix .. '.child0', 'dy_selected_txt')
                    name = name .. ', ' .. (value ~= '' and value or 'value unavailable') .. ', dropdown'
                elseif spec.role == 'slider' or spec.role == 'information' then
                    local value = captured_text(prefix .. spec.value_path, spec.value_id)
                    name = name .. ', ' .. (value ~= '' and value or 'value unavailable') .. ', ' .. spec.role
                else name = name .. ', button' end
                local state = ''
                if spec.role ~= 'information' then
                    local state_prefix = spec.role == 'slider' and prefix .. '.child0' or prefix
                    state = captured_value(state_prefix, 'CurrentState')
                    if type(state) ~= 'string' then state = 'state unavailable' end
                    if captured_value(state_prefix, 'IsInteractive') ~= true then state = state .. ', unavailable' end
                end
                controls[#controls + 1] = {key = prefix, name = name, state = state, read_only = true}
            else log('advanced.label_unavailable', prefix) end
        end
    end
end

local function scope_controls()
    if visible_id(graphics_panel, 'campaign_select') then scope_campaign_controls(); return end
    if visible_id(graphics_panel, 'main') then
        screen_kind = 'main'
        return
    end
    -- Unknown frontend panels must not expose unrelated main-menu/footer buttons.
    controls = {}
    if not visible_id(graphics_panel, 'options_graphics') then screen_kind = 'unknown'; return end
    screen_kind = 'graphics_overlay'
    if visible_id(graphics_panel .. '.child0', 'panel_advanced') then
        -- Discovery is read-only even when the bounded traversal cannot reach
        -- later sibling panels. This reports a visible panel, not modal focus.
        scope_advanced_controls(); return
    end
    if captured_value(graphics_panel .. '.child2', 'Visible') ~= false then return end
    if not visible_id(basic_panel, 'basic_options')
        or captured_value(graphics_panel .. '.child0', 'Visible') ~= false
        or captured_value(graphics_panel .. '.child2', 'Visible') ~= false
        or captured_value(basic_panel .. '.child5.child1', 'Visible') ~= false
        or captured_value(basic_panel .. '.child6.child1', 'Visible') ~= false then return end
    screen_kind = 'graphics'
    local specs = {
        {path = '.child0', id = 'checkbox_windowed', label_path = '.child0', label_id = 'label_txt', role = 'checkbox'},
        {path = '.child2.child0', id = 'button_ok', role = 'button'},
        {path = '.child2.child1', id = 'button_cancel', role = 'button'},
        {path = '.child3', id = 'button_advanced_options', label_path = '.child1', label_id = 'button_txt', role = 'button'},
        {path = '.child4', id = 'button_recommended', label_path = '.child1', label_id = 'button_txt', role = 'button'},
        {path = '.child5', id = 'dropdown_resolution', label_path = '.child2', label_id = 'label_txt', role = 'dropdown'},
        {path = '.child6', id = 'dropdown_quality', label_path = '.child2', label_id = 'label_txt', role = 'dropdown'}
    }
    for _, spec in ipairs(specs) do
        local prefix = basic_panel .. spec.path
        if visible_id(prefix, spec.id) then
            local name
            if spec.label_path then name = captured_text(prefix .. spec.label_path, spec.label_id)
            else name = clean(captured_value(prefix, 'GetTooltipText')) end
            if name ~= '' then
                if spec.role == 'dropdown' then
                    local value = captured_text(prefix .. '.child0', 'dy_selected_txt')
                    name = name .. ', ' .. (value ~= '' and value or 'value unavailable') .. ', dropdown'
                elseif spec.role == 'checkbox' then
                    -- active/inactive is not evidence of a checkbox's checked value.
                    name = name .. ', checkbox, checked state unavailable'
                else name = name .. ', button' end
                local state = captured_value(prefix, 'CurrentState')
                if type(state) ~= 'string' then state = 'state unavailable' end
                if captured_value(prefix, 'IsInteractive') ~= true then state = state .. ', unavailable' end
                controls[#controls + 1] = {key = prefix, name = name, state = state, read_only = spec.id ~= 'button_advanced_options'}
            else log('graphics.label_unavailable', prefix) end
        end
    end
end

local function capture_tree(root)
    local visited = 0
    controls = {}
    local function descendant_label(node, depth)
        if depth <= 0 then return '' end
        local count_ok, count = pcall(function() return node:ChildCount() end)
        if not count_ok or type(count) ~= 'number' or count < 0 or count % 1 ~= 0 then return '' end
        if count > 12 then count = 12 end
        for i = 0, count - 1 do
            local ok, child = pcall(function() return UIComponent(node:Find(i)) end)
            if ok and child then
                local visible_ok, visible = pcall(function() return child:Visible(true) end)
                if visible_ok and visible == true then
                    local text_ok, text = pcall(function() return child:GetStateText() end)
                    text = text_ok and clean(text) or ''
                    if text ~= '' then return text end
                    local tip_ok, tip = pcall(function() return child:GetTooltipText() end)
                    tip = tip_ok and clean(tip) or ''
                    if tip ~= '' then return tip end
                    local nested = descendant_label(child, depth - 1)
                    if nested ~= '' then return nested end
                end
            end
        end
        return ''
    end
    local function walk(node, label, depth)
        if visited >= 200 or depth > 20 then log(label .. '.bounded', 'node or depth limit'); return end
        visited = visited + 1
        log(label .. '.object', node)
        local id_ok, id = observe(label .. '.Id', function() local v = node:Id(); return v end)
        local visible_ok, visible = observe(label .. '.Visible', function() local v = node:Visible(true); return v end)
        local interactive_ok, interactive = observe(label .. '.IsInteractive', function() local v = node:IsInteractive(); return v end)
        local text_ok, state_text = observe(label .. '.GetStateText', function() local v = node:GetStateText(); return v end)
        local tip_ok, tooltip = observe(label .. '.GetTooltipText', function() local v = node:GetTooltipText(); return v end)
        local state_ok, state = observe(label .. '.CurrentState', function() local v = node:CurrentState(); return v end)
        observe(label .. '.Address', function() local v = node:Address(); return v end)
        local count_ok, count = observe(label .. '.ChildCount', function() local v = node:ChildCount(); return v end)
        if not visible_ok or visible ~= true then log(label .. '.children.skipped', 'not visible'); return end
        if not count_ok or type(count) ~= 'number' or count ~= count or count < 0 or count % 1 ~= 0 then
            log(label .. '.children.skipped', 'invalid count'); return
        end
        local limit = count
        if limit > 100 then limit = 100 end
        for i = 0, limit - 1 do
            local child_label = label .. '.child' .. i
            local found, address = observe(child_label .. '.Find', function() local v = node:Find(i); return v end)
            if found and address then
                local converted, child = observe(child_label .. '.Convert', function() local v = UIComponent(address); return v end)
                if converted and child then walk(child, child_label, depth + 1) end
            end
        end
        log(label .. '.classify.START', true)
        local classified, classify_error = pcall(function()
            if id_ok and type(id) == 'string' and control_ids[id] == true
                and interactive_ok and interactive == true then
                local name = text_ok and clean(state_text) or ''
                if name == '' then name = tip_ok and clean(tooltip) or '' end
                if name == '' then name = descendant_label(node, 2) end
                if name == '' then name = id end
                controls[#controls + 1] = {key = label, name = name, state = state_ok and clean(state) or ''}
            end
        end)
        if classified then log(label .. '.classify.RESULT', true)
        else scan_valid = false; log(label .. '.classify.ERROR', classify_error) end
    end
    walk(root, 'tree', 0)
    snapshot_node_count = visited
    log('tree.nodes', visited)
    log('tree.controls', #controls)
end
local function capture(source)
    log('capture.ENTER', source)
    runs = runs + 1
    log('capture.sequence', runs)
    scan_active, scan_valid = true, true
    log('capture.collecting', true)
    scan_nodes, scan_parts, scan_reads = {}, {}, {}
    snapshot_node_count = 0
    log('capture.buffers', true)
    local began_generation = generation
    log('capture', runs); log('source', source)
    local completed, failure = pcall(function()
        local ok, ready = observe('core.is_ui_created', function() local v = core:is_ui_created(); return v end)
        if not ok or ready ~= true then error('Game UI is not ready') end
        local got, node = observe('core.get_ui_root', function() local v = core:get_ui_root(); return v end)
        if not got or not node then error('Game UI root unavailable') end
        sample('root', node, false)
        capture_tree(node)
    end)
    scan_active = false
    -- Interpret the captured values outside both the native observer and logger.
    -- The template is deliberately fixed to the successful 86-node main menu.
    local layout, layout_name, expected_nodes = verified_layout, 'main', 86
    if visible_id(graphics_panel, 'main') and captured_value('tree','ChildCount') == 6
        and captured_value('tree.child4','Id') == 'Tooltip'
        and captured_value('tree.child5','Id') == 'browser' then
        layout, expected_nodes = verified_main_tooltip_layout, 87
    end
    if visible_id(graphics_panel, 'options_graphics') then
        layout, layout_name, expected_nodes = verified_basic_layout, 'graphics_basic', 40
    end
    if visible_id(graphics_panel, 'campaign_select') then
        layout, layout_name = verified_campaign_layout, 'campaign_selection'
        expected_nodes = captured_value('tree','ChildCount') == 6 and 168 or 167
        if not campaign_shell_supported() then scan_valid = false end
        -- Preserve the original logger while making multiline text observable.
        log('campaign.tooltip.escaped', quote(captured_value('tree.child2.child0.child0.child1.child1.child1.child10.child0','GetTooltipText')))
        log('campaign.description.escaped', quote(captured_value('tree.child2.child0.child0.child1.child0.child0.child0','GetStateText')))
    end
    if snapshot_node_count ~= expected_nodes then scan_valid = false end
    for _, read in pairs(scan_reads) do if not read.ok then scan_valid = false end end
    for prefix, expected in pairs(layout) do
        local node = {}
        scan_nodes[prefix] = node
        for method in pairs(expected) do
            local read = scan_reads[prefix .. '.' .. method]
            node[method] = read
            if not read or not read.ok then scan_valid = false end
            if read then
                scan_parts[#scan_parts + 1] = quote(prefix .. '.' .. method) .. ':' .. quote(type(read.value)) .. ':' .. quote(read.value)
            end
        end
        local address = scan_reads[prefix .. '.Address']
        node.Address = address
        if not address or not address.ok then scan_valid = false
        else
            local kind, value = type(address.value), address.value
            if not (kind == 'userdata' or (kind == 'string' and value ~= '')
                or (kind == 'number' and value == value and value > 0)) then scan_valid = false end
            scan_parts[#scan_parts + 1] = quote(prefix .. '.Address') .. ':' .. quote(kind) .. ':' .. quote(value)
        end
    end
    if not completed then log('capture.ERROR', failure); scan_valid = false; controls = {} end
    if generation ~= began_generation then scan_valid = false; controls = {} end
    latest_snapshot = {valid = scan_valid and completed and not log_failed,
        layout = layout_name, nodes = scan_nodes, fingerprint = table.concat(scan_parts, '\n'), generation = began_generation}
    captured = completed and generation == began_generation
    if captured then scope_controls() else screen_kind = 'unknown' end
    latest_snapshot.panel_visibility = {
        captured_value(graphics_panel .. '.child0', 'Visible'),
        captured_value(graphics_panel .. '.child1', 'Visible'),
        captured_value(graphics_panel .. '.child2', 'Visible')}
    if captured and awaiting_result then
        if awaiting_result == 'New Campaign' and screen_kind == 'campaign_selection' then
            log('activation.observed_result', 'New Campaign')
        elseif awaiting_result == 'Continue' and screen_kind == 'campaign_selection' then
            log('activation.result_not_observed', 'Continue:' .. screen_kind)
        elseif awaiting_result == 'New Campaign' or awaiting_result == 'Continue' then
            log('activation.result_requires_mapping', awaiting_result .. ':' .. screen_kind)
        elseif (awaiting_result == 'Graphics' and screen_kind == 'graphics')
            or (awaiting_result == 'Advanced' and screen_kind == 'graphics_advanced') then
            log('activation.observed_result', awaiting_result)
        else log('activation.result_not_observed', awaiting_result .. ':' .. screen_kind) end
        awaiting_result = nil
    end
    latest_snapshot.screen = screen_kind
    log('capture.screen', screen_kind)
    log('capture.scoped_controls', #controls)
    log('capture.activation_eligible', latest_snapshot.valid)
    log('capture.valid', latest_snapshot.valid)
    log('capture.COMPLETE', runs)
    return latest_snapshot
end
-- Presentation of already captured values only. No native calls, retained
-- components, selection changes or activation eligibility are introduced.
local lord_names={
    ['lord:tree.child2.child0.child2.child0.child4:text']={id='dy_faction_leader',label='Selected lord'},
    ['lord:tree.child2.child0.child2.child1.child4.child0:text']={id='dy_race',label='Race'},
    ['lord:tree.child2.child0.child2.child2.child1.child3:text']={id='label_faction_name',label='Faction'},
    ['lord:tree.child2.child0.child2.child2.child3.child2.child0.child0:text']={id='dy_selected_txt',label='Campaign difficulty'},
    ['lord:tree.child2.child0.child2.child2.child3.child2.child1.child0:text']={id='dy_selected_txt',label='Battle difficulty'}
}
local function lord_spoken_name(item)
    local name=item.raw_name or item.name
    local field=lord_names[item.key]
    if field and field.id==item.id then return field.label .. ': ' .. name end
    if item.id=='checkbox_start_prelude' then return 'Campaign introduction: '
        .. (item.raw_state=='selected' and 'selected' or 'state ' .. item.raw_state) .. '. ' .. name end
    if item.id=='bullet' and starts_with(item.key,'lord:tree.child2.child0.child2.child1.child2.child1.') then
        return 'Race attribute: ' .. name
    end
    if starts_with(item.id,'lord_effect') and starts_with(item.key,'lord:tree.child2.child0.child2.child2.child1.child1.') then
        local group
        for _,other in ipairs(controls) do
            if other.raw_state=='faction_traits' then group='Faction effect'
            elseif other.raw_state=='lord_traits' then group='Lord effect' end
            if other==item then break end
        end
        if group and item.raw_state~='faction_traits' and item.raw_state~='lord_traits' then return group .. ': ' .. name end
    end
    return name
end
local function announce_control(step)
    cancel()
    if #controls == 0 then
        if screen_kind == 'campaign_overlay' then speak('An unsupported campaign overlay is present. Use Escape, then browse again.')
        elseif screen_kind == 'graphics_advanced' then speak('Advanced graphics detected, but no mapped controls are readable. Send the native preview log.')
        elseif screen_kind == 'graphics_advanced_overlay' then speak('An Advanced dropdown is expanded. Its options are not mapped yet. Use Escape to return.')
        elseif screen_kind == 'graphics_overlay' then speak('Graphics dialog or expanded control is not supported yet. Use Escape to return.')
        else speak('Unmapped frontend screen. Captured ' .. snapshot_node_count .. ' UI nodes. Send native-ui-graphics-preview.log to map campaign setup. No game action was sent.') end
        return
    end
    if control_index == 0 then control_index = step > 0 and 1 or #controls
    else control_index = ((control_index - 1 + step) % #controls) + 1 end
    local item = controls[control_index]
    if screen_kind=='lord_discovery' then item.raw_name=item.raw_name or item.name; item.name=lord_spoken_name(item) end
    local state = item.state ~= '' and (', ' .. item.state) or ''
    local context = screen_kind == 'lord_discovery' and 'Lord setup' or screen_kind == 'campaign_selection' and 'Campaign selection' or screen_kind == 'graphics_advanced' and 'Advanced graphics' or (screen_kind == 'graphics' and 'Graphics settings' or 'Controls')
    local prefix=announce_prefix; announce_prefix=''
    speak(prefix .. context .. ', ' .. control_index .. ' of ' .. #controls .. ': ' .. item.name .. (item.read_only and ', read only' or '') .. state .. '.')
end
local graphics_key = 'tree.child2.child1.child0.child0.child2.child0.child1'
local graphics_path = {
    {index = 2, id = 'main'}, {index = 1, id = 'banner_clip'},
    {index = 0, id = 'fe_banner'}, {index = 0, id = 'menu'},
    {index = 2, id = 'options_frame'}, {index = 0, id = 'holder'},
    {index = 1, id = 'button_graphics'}
}
local advanced_key = 'tree.child2.child1.child3'
local campaign_key = 'tree.child2.child1.child0.child0.child0.child0.child1'
local targets = {
    CampaignContinue = {name='Continue',key=campaign_continue_key,entry_name='Continue, button',layout='campaign_selection',path={
        {index=2,id='campaign_select'},{index=2,id='button_frame'},{index=0,id='button_next'}}},
    NewCampaign = {name = 'New Campaign', key = campaign_key, entry_name = 'New Campaign', layout = 'main', path = {
        {index = 2, id = 'main'}, {index = 1, id = 'banner_clip'},
        {index = 0, id = 'fe_banner'}, {index = 0, id = 'menu'},
        {index = 0, id = 'campaigns_frame'}, {index = 0, id = 'holder'},
        {index = 1, id = 'button_new_campaign'}}},
    Graphics = {name = 'Graphics', key = graphics_key, entry_name = 'Graphics', layout = 'main', path = graphics_path},
    Advanced = {name = 'Advanced', key = advanced_key, entry_name = 'Advanced, button', layout = 'graphics_basic', path = {
        {index = 2, id = 'options_graphics'}, {index = 1, id = 'basic_options'},
        {index = 3, id = 'button_advanced_options'}}}
}
local function same_layout(snapshot)
    if not snapshot or not snapshot.valid then log('layout.INVALID', 'Snapshot incomplete or unreadable'); return false end
    local layout = snapshot.layout == 'main' and snapshot.nodes['tree.child5'] and verified_main_tooltip_layout
        or snapshot.layout == 'campaign_selection' and verified_campaign_layout
        or snapshot.layout == 'graphics_basic' and verified_basic_layout or verified_layout
    local count = 0
    for prefix, node in pairs(snapshot.nodes) do
        count = count + 1
        local expected = layout[prefix]
        if not expected then log('layout.unverified_node', prefix); return false end
        for method, value in pairs(expected) do
            local read = node[method]
            -- The tester intentionally enabled windowed mode. Both native
            -- states were observed on this one checkbox; neither state is a
            -- requirement for opening Advanced. All other fields remain exact.
            local window_mode_variant = snapshot.layout == 'graphics_basic'
                and prefix == 'tree.child2.child1.child0' and method == 'CurrentState'
                and read and read.ok and type(read.value) == 'string'
                and (read.value == 'active' or read.value == 'selected')
            local campaign_root_variant = snapshot.layout == 'campaign_selection'
                and prefix == 'tree' and method == 'ChildCount' and read and read.ok
                and (read.value == 5 or read.value == 6)
            -- The fixture was reconstructed from the plain diagnostic log,
            -- which replaces each CR/LF with one space. Compare campaign text
            -- using that same representation, not broader whitespace cleanup.
            -- The confirmation fingerprint and final native leaf comparison
            -- still retain the exact raw strings and detect byte-level changes.
            local diagnostic_text_variant = snapshot.layout == 'campaign_selection'
                and (method == 'GetStateText' or method == 'GetTooltipText')
                and read and read.ok and type(read.value) == 'string'
                and ('string:' .. read.value:gsub('[\r\n]', ' ')) == value
            if not read or not read.ok or (type(read.value) .. ':' .. tostring(read.value) ~= value
                and not window_mode_variant and not campaign_root_variant and not diagnostic_text_variant) then
                log('layout.mismatch', prefix .. '.' .. method .. '; expected ' .. quote(value) .. '; got ' .. quote(read and (type(read.value) .. ':' .. tostring(read.value)) or 'missing'))
                return false
            end
        end
    end
    local expected_count = 0
    for _ in pairs(layout) do expected_count = expected_count + 1 end
    if count ~= expected_count then log('layout.node_count', count .. ' instead of ' .. expected_count); return false end
    return true
end
-- WH2 numbers round contemporary Unix seconds to 128-second buckets. Keep
-- epoch seconds as decimal text and confirmation arithmetic relative to a UTC
-- day, where every second remains exactly representable in a single float.
local function decimal_valid(value)
    if type(value)~='string' or #value==0 or #value>10 then return false end
    if #value>1 and string.byte(value,1)==48 then return false end
    for index=1,#value do
        local byte=string.byte(value,index)
        if byte<48 or byte>57 then return false end
    end
    return true
end
local function decimal_add(value,extra)
    local result,carry='',extra
    for index=#value,1,-1 do
        local digit=string.byte(value,index)-48+carry
        result=string.char(48+digit%10) .. result
        carry=math.floor(digit/10)
    end
    while carry>0 do
        result=string.char(48+carry%10) .. result; carry=math.floor(carry/10)
    end
    return result
end
local function decimal_multiply(value,factor)
    local result,carry='',0
    for index=#value,1,-1 do
        local digit=(string.byte(value,index)-48)*factor+carry
        result=string.char(48+digit%10) .. result
        carry=math.floor(digit/10)
    end
    while carry>0 do
        result=string.char(48+carry%10) .. result; carry=math.floor(carry/10)
    end
    return result
end
local function decimal_less(left,right)
    if #left~=#right then return #left<#right end
    return left<right
end
local cached_utc_day,cached_utc_serial,clock_anchor_day
local function utc_clock()
    local text=os.date('!%Y-%m-%d-%H-%M-%S') -- no rounded numeric timestamp argument
    if type(text)~='string' or #text~=19 then error('Confirmation UTC clock unavailable') end
    for _,index in ipairs({5,8,11,14,17}) do
        if string.byte(text,index)~=45 then error('Invalid UTC clock format') end
    end
    local function part(first,last)
        local value=0
        for index=first,last do
            local byte=string.byte(text,index)
            if byte<48 or byte>57 then error('Invalid UTC clock digit') end
            value=value*10+byte-48
        end
        return value
    end
    local year,month,day=part(1,4),part(6,7),part(9,10)
    local hour,minute,second=part(12,13),part(15,16),part(18,19)
    if year<1970 or month<1 or month>12 or hour>23 or minute>59 or second>59 then error('Invalid UTC clock value') end
    local leap=year%4==0 and (year%100~=0 or year%400==0)
    local lengths={31,leap and 29 or 28,31,30,31,30,31,31,30,31,30,31}
    if day<1 or day>lengths[month] then error('Invalid UTC calendar day') end
    local day_key=string.sub(text,1,10)
    if day_key~=cached_utc_day then
        local previous=year-1
        local days=(year-1970)*365+math.floor(previous/4)-math.floor(previous/100)+math.floor(previous/400)-477
        for index=1,month-1 do days=days+lengths[index] end
        cached_utc_day,cached_utc_serial=day_key,days+day-1
    end
    if not clock_anchor_day then clock_anchor_day=cached_utc_serial end
    local seconds=hour*3600+minute*60+second
    local relative=(cached_utc_serial-clock_anchor_day)*86400+seconds
    if relative<0 or relative>=16777216 then error('Confirmation clock precision unavailable') end
    local epoch=decimal_multiply(string.format('%d',cached_utc_serial),86400)
    epoch=decimal_add(epoch,seconds)
    return relative,epoch
end
local function clock_value()
    local value=utc_clock(); return value
end
local function unix_value()
    local _,value=utc_clock(); return value
end
local function resolve_target(snapshot, target)
    if core:is_campaign() or core:is_battle() or not core:is_ui_created() then error('Frontend UI is not ready') end
    local ok, node = observe('activation.root', function() local v = core:get_ui_root(); return v end)
    if not ok or not node then error('Fresh UI root unavailable') end
    local label = 'tree'
    local function check_ancestor(expected_id)
        local reads = snapshot.nodes[label]
        if not reads then error('UI path unavailable') end
        local id_ok, id = observe('activation.' .. label .. '.Id', function() local v = node:Id(); return v end)
        local visible_ok, visible = observe('activation.' .. label .. '.Visible', function() local v = node:Visible(true); return v end)
        local address_ok, address = observe('activation.' .. label .. '.Address', function() local v = node:Address(); return v end)
        if not id_ok or id ~= expected_id or not visible_ok or visible ~= true
            or not address_ok or tostring(address) ~= tostring(reads.Address.value) then error('UI identity or visibility changed') end
    end
    check_ancestor('root')
    for _, step in ipairs(target.path) do
        local found, address = observe('activation.' .. label .. '.Find', function() local v = node:Find(step.index); return v end)
        if not found or not address then error('UI path changed') end
        local converted, child = observe('activation.' .. label .. '.Convert', function() local v = UIComponent(address); return v end)
        if not converted or not child then error('UI conversion failed') end
        node = child
        label = label .. '.child' .. step.index
        check_ancestor(step.id)
    end
    local reads = snapshot.nodes[target.key]
    local interactive_ok, interactive = observe('activation.leaf.IsInteractive', function() local v = node:IsInteractive(); return v end)
    local state_ok, state = observe('activation.leaf.CurrentState', function() local v = node:CurrentState(); return v end)
    local text_ok, text = observe('activation.leaf.GetStateText', function() local v = node:GetStateText(); return v end)
    local tip_ok, tip = observe('activation.leaf.GetTooltipText', function() local v = node:GetTooltipText(); return v end)
    if not interactive_ok or interactive ~= true or not state_ok or state ~= 'active'
        or not text_ok or type(text) ~= 'string' or text ~= reads.GetStateText.value
        or not tip_ok or type(tip) ~= 'string' or tip ~= reads.GetTooltipText.value then error(target.name .. ' state or label changed') end
    if generation ~= snapshot.generation then error('UI recreated during validation') end
    return node
end
-- The only native click in the mod. Drops every selection and confirmation
-- before sending the single documented input.
local function send_click(node, name)
    invalidate()
    awaiting_result = name
    log('activation.dispatch', name)
    if log_failed then error('Diagnostic log unavailable before dispatch') end
    activation_outcome = 'input-sent'
    node:SimulateLClick()
    log('activation.returned', true)
end
local function activate_control()
    if screen_kind == 'graphics_advanced' or screen_kind == 'graphics_advanced_overlay' then cancel(); speak('Advanced controls are read only. Use Escape to return.'); return end
    if screen_kind == 'campaign_overlay' then cancel(); speak('Campaign overlay actions are not supported. Use Escape to return.'); return end
    local item = controls[control_index]
    if screen_kind == 'campaign_selection' and (not item or item.key ~= campaign_continue_key) then cancel(); speak('Campaign choices and information are read only. Only Continue can open the next setup screen.'); return end
    if not captured or not item then cancel(); speak('Use F2 or F3 to choose New Campaign, Graphics or Advanced first.'); return end
    local target
    if screen_kind == 'campaign_selection' then target = targets.CampaignContinue
    elseif screen_kind == 'main' then target = item.key == campaign_key and targets.NewCampaign or targets.Graphics
    elseif screen_kind == 'graphics' and item.key == advanced_key then target = targets.Advanced
    else cancel(); speak('Graphics settings are read only; only Advanced can open. Use Escape to return.'); return end
    if item.key ~= target.key or item.name ~= target.entry_name or item.state ~= 'active' then
        cancel(); speak('Only New Campaign, Continue, Graphics or Advanced can open. No game action was sent.'); return
    end
    local original = browse_snapshot
    if not original or original.layout ~= target.layout or not same_layout(original) then cancel(); speak('Activation blocked: this is not the verified screen, or a native read failed.'); return end
    local selected_index, selected_generation = control_index, generation
    local fresh = capture('F4 revalidation')
    if fresh.layout ~= target.layout or not same_layout(fresh) or fresh.generation ~= selected_generation
        or fresh.fingerprint ~= original.fingerprint then
        invalidate(); speak('UI changed or could not be verified. Browse again before activating.'); return
    end
    local current = controls[selected_index]
    if not current or current.key ~= item.key or current.name ~= item.name or current.state ~= item.state then
        invalidate(); speak('Selected control changed. Browse again.'); return
    end
    control_index = selected_index
    local node = resolve_target(fresh, target)
    local now = clock_value()
    if pending and (now < pending.armed_at or now > pending.deadline) then
        cancel(); speak('Confirmation expired or the clock changed. Press F4 to start again.'); return
    end
    if not pending then
        pending = {target = target.key, armed_at = now, deadline = now + 4, fingerprint = fresh.fingerprint, generation = generation, origin = activation_origin}
        activation_outcome = 'armed'
        log('activation.armed', now)
        speak(target.name .. '. Press F4 again within four seconds.'); return
    end
    if pending.target ~= target.key or pending.generation ~= generation or pending.fingerprint ~= fresh.fingerprint then
        invalidate(); speak('Confirmation cancelled because the UI changed.'); return
    end
    if log_failed then invalidate(); speak('Diagnostic log is full or unavailable. Restart the preview.'); return end
    send_click(node, target.name)
    speak('Input sent to ' .. target.name .. '. The resulting screen is not confirmed. Press F2 to inspect, or use Escape to return.')
end
local function screen_still_current()
    -- Unknown setup screens can change descendants without replacing the panel.
    -- Recapture on an explicit browse key; never infer a campaign screen identity.
    if screen_kind == 'unknown' or screen_kind == 'campaign_overlay' then return false end
    if not browse_snapshot or not core:is_ui_created() then return false end
    local root_reads = browse_snapshot.nodes.tree
    local panel_reads = browse_snapshot.nodes['tree.child2']
    if not root_reads or not panel_reads or not root_reads.Address or not panel_reads.Address
        or not panel_reads.Id or not panel_reads.Visible then return false end
    local ok, node = observe('navigation.probe.root', function() local v = core:get_ui_root(); return v end)
    if not ok or not node then return false end
    local address_ok, root_address = observe('navigation.probe.root.Address', function() local v = node:Address(); return v end)
    if not address_ok or tostring(root_address) ~= tostring(root_reads.Address.value) then return false end
    local found, address = observe('navigation.probe.Find', function() local v = node:Find(2); return v end)
    if not found or not address then return false end
    local converted, panel = observe('navigation.probe.Convert', function() local v = UIComponent(address); return v end)
    if not converted or not panel then return false end
    local id_ok, id = observe('navigation.probe.Id', function() local v = panel:Id(); return v end)
    local visible_ok, visible = observe('navigation.probe.Visible', function() local v = panel:Visible(true); return v end)
    local panel_ok, panel_address = observe('navigation.probe.Address', function() local v = panel:Address(); return v end)
    if not (id_ok and id == panel_reads.Id.value and visible_ok and visible == true
        and panel_ok and tostring(panel_address) == tostring(panel_reads.Address.value)) then return false end
    if id == 'main' then
        local main_ok, main_same = observe('navigation.main.shell', function()
            local count = node:ChildCount()
            if count ~= root_reads.ChildCount.value then return false end
            local browser_index = browse_snapshot.nodes['tree.child5'] and 5 or 4
            local browser = UIComponent(node:Find(browser_index))
            if browser:Id() ~= 'browser' or browser:Visible(true) ~= false then return false end
            if browser_index == 5 then
                local tooltip = UIComponent(node:Find(4))
                if tooltip:Id() ~= 'Tooltip' or tooltip:Visible(true) ~= false
                    or tooltip:IsInteractive() ~= false then return false end
            end
            return true
        end)
        if not main_ok or main_same ~= true then return false end
    end
    if id == 'campaign_select' then
        local shell_ok, shell_same = observe('navigation.campaign.shell', function()
            local count = node:ChildCount()
            if count ~= root_reads.ChildCount.value then return false end
            if count == 6 then
                local extra = UIComponent(node:Find(5))
                if extra:Id() ~= 'Tooltip' or extra:Visible(true) ~= false or extra:IsInteractive() ~= false then return false end
            end
            local count_panel = panel:ChildCount()
            return count_panel == panel_reads.ChildCount.value
        end)
        if not shell_ok or shell_same ~= true then return false end
        local probes = {
            {path={2,0,1,0,1},key=campaign_entries .. '.child0.child1',method='state'},
            {path={2,0,1,1,1},key=campaign_entries .. '.child1.child1',method='state'},
            {path={2,0,0,1,0,1,0},key='tree.child2.child0.child0.child1.child0.child1.child0',method='text'},
            {path={2,0,0,1,0,0,0},key='tree.child2.child0.child0.child1.child0.child0.child0',method='text'},
            {path={2,2,0},key=campaign_continue_key,method='state'},
            {path={2,2},key='tree.child2.child2',method='count'}}
        for _, spec in ipairs(probes) do
            local same_ok, same = observe('navigation.campaign.' .. spec.key, function()
                local current = node
                for _, index in ipairs(spec.path) do current = UIComponent(current:Find(index)) end
                local previous = browse_snapshot.nodes[spec.key]
                if not previous or current:Id() ~= previous.Id.value or current:Visible(true) ~= true
                    or tostring(current:Address()) ~= tostring(previous.Address.value) then return false end
                local value
                if spec.method == 'state' then value = current:CurrentState(); return value == previous.CurrentState.value
                elseif spec.method == 'text' then value = current:GetStateText(); return value == previous.GetStateText.value
                else value = current:ChildCount(); return value == previous.ChildCount.value end
            end)
            if not same_ok or same ~= true then return false end
        end
    end
    if id == 'options_graphics' then
        for i = 0, 2 do
            local found_child, child_address = observe('navigation.probe.panel.Find' .. i, function() local v = panel:Find(i); return v end)
            if not found_child or not child_address then return false end
            local converted_child, child = observe('navigation.probe.panel.Convert' .. i, function() local v = UIComponent(child_address); return v end)
            if not converted_child or not child then return false end
            local child_ok, child_visible = observe('navigation.probe.panel.Visible' .. i, function() local v = child:Visible(true); return v end)
            if not child_ok or type(child_visible) ~= 'boolean' or child_visible ~= browse_snapshot.panel_visibility[i + 1] then return false end
        end
    end
    return true
end
-- Separate, read-only breadth-first discovery. It never contributes an
-- activation snapshot, and leaves the proven depth-first scanner unchanged.
local lord_file_started,lord_file_bytes,lord_run=false,0,0
local function lord_read(fn)
    local value
    local ok,err=pcall(function() value=fn() end)
    return ok,value,err
end
local function lord_identity(value)
    local kind=type(value)
    if kind=='userdata' or (kind=='string' and value~='') then return tostring(value) end
    return nil
end
-- Log why the Lord context was rejected, once per distinct reason, so a
-- screen the reader refuses (overlay, tooltip, changed layout) is diagnosable.
local lord_last_reject
local function lord_reject(reason)
    if reason~=lord_last_reject then lord_last_reject=reason; plain_log('lord.context_reject',reason) end
    return nil
end
local function lord_context()
    if not core:is_frontend() or not core:is_ui_created() then return nil end
    local ok,root=lord_read(function() local v=core:get_ui_root(); return v end)
    if not ok or not root then return lord_reject('root-unavailable') end
    local _,id=lord_read(function() local v=root:Id(); return v end)
    local _,visible=lord_read(function() local v=root:Visible(true); return v end)
    local _,count=lord_read(function() local v=root:ChildCount(); return v end)
    if id~='root' or visible~=true or type(count)~='number' or count<5 or count>8 then
        return lord_reject('root id=' .. tostring(id) .. ' visible=' .. tostring(visible) .. ' count=' .. tostring(count))
    end
    local browsers=0
    for index=4,count-1 do
        local _,extra_address=lord_read(function() local v=root:Find(index); return v end)
        if not extra_address then return lord_reject('extra ' .. index .. ' missing') end
        local extra_ok,extra=lord_read(function() local v=UIComponent(extra_address); return v end)
        if not extra_ok or not extra then return lord_reject('extra ' .. index .. ' unconvertible') end
        local _,extra_id=lord_read(function() local v=extra:Id(); return v end)
        local _,extra_visible=lord_read(function() local v=extra:Visible(true); return v end)
        -- Hover tooltips are non-interactive text layers; selecting a lord
        -- leaves a hidden tooltip_campaign_select_lord at the root (seen
        -- live in 0.6.20). Accept tooltip layers shown or hidden on this
        -- read-only path; the browser must stay hidden; reject anything else.
        local tooltip=extra_id=='Tooltip' or starts_with(extra_id,'tooltip_')
        if not tooltip and (extra_visible~=false or extra_id~='browser') then
            return lord_reject('extra ' .. index .. ' id=' .. tostring(extra_id) .. ' visible=' .. tostring(extra_visible))
        end
        if extra_id=='browser' then browsers=browsers+1 end
    end
    if browsers~=1 then return lord_reject('browsers=' .. browsers) end
    local _,address=lord_read(function() local v=root:Find(2); return v end)
    if not address then return lord_reject('panel missing') end
    local converted,panel=lord_read(function() local v=UIComponent(address); return v end)
    if not converted or not panel then return lord_reject('panel unconvertible') end
    local _,panel_id=lord_read(function() local v=panel:Id(); return v end)
    local _,panel_visible=lord_read(function() local v=panel:Visible(true); return v end)
    local _,panel_count=lord_read(function() local v=panel:ChildCount(); return v end)
    if panel_id~='sp_grand_campaign' or panel_visible~=true or panel_count~=6 then
        return lord_reject('panel id=' .. tostring(panel_id) .. ' visible=' .. tostring(panel_visible) .. ' count=' .. tostring(panel_count))
    end
    local _,root_address=lord_read(function() local v=root:Address(); return v end)
    local _,panel_address=lord_read(function() local v=panel:Address(); return v end)
    root_address,panel_address=lord_identity(root_address),lord_identity(panel_address)
    if not root_address or not panel_address then return lord_reject('identity unavailable') end
    lord_last_reject=nil
    return {root=root,root_address=root_address,panel_address=panel_address,generation=generation}
end
local function lord_log(line)
    if not log_path then error('Lord discovery output unavailable') end
    local base=string.sub(log_path,1,#log_path-#'native-ui-graphics-preview.log')
    if lord_file_bytes+#line+2>2097152 then error('Lord discovery log budget reached') end
    local f=io.open(base .. 'native-ui-lord-discovery.jsonl',lord_file_started and 'a' or 'w')
    if not f then error('Lord discovery output could not be opened') end
    local written=f:write(line .. '\n'); local closed=f:close()
    if not written or closed==nil then error('Lord discovery output write failed') end
    lord_file_started=true; lord_file_bytes=lord_file_bytes+#line+2
end
local function lord_text(value)
    if type(value)~='string' then return '' end
    if #value>1000 then
        lord_discovery.limited=true
        return string.sub(value,1,1000):gsub('[\192-\255][\128-\191]*$','')
    end
    return value
end
local function lord_begin(context)
    invalidate()
    lord_run=lord_run+1
    lord_discovery={root_address=context.root_address,panel_address=context.panel_address,
        generation=generation,queue={{path={2},label='tree.child2',ids={}}},head=1,
        visited=0,page=0,done=false,limited=false,errors=0}
    screen_kind='lord_discovery'; latest_snapshot=nil
    lord_log('{"kind":"begin","run":' .. lord_run .. ',"generation":' .. generation
        .. ',"panel":"sp_grand_campaign","read_only":true,"page_budget":48,"node_budget":1536}')
    if awaiting_result then log('activation.result_requires_mapping',awaiting_result .. ':lord_discovery'); awaiting_result=nil end
end
local function lord_resolve(root,path)
    local node=root
    for _,index in ipairs(path) do
        local ok,visible=lord_read(function() local v=node:Visible(true); return v end)
        if not ok then return nil,'read-error' end
        if visible~=true then return nil,'hidden' end
        local found,address=lord_read(function() local v=node:Find(index); return v end)
        if not found or not address then return nil,'missing' end
        local converted,child=lord_read(function() local v=UIComponent(address); return v end)
        if not converted or not child then return nil,'read-error' end
        node=child
    end
    local ok,visible=lord_read(function() local v=node:Visible(true); return v end)
    if not ok then return nil,'read-error' end
    if visible~=true then return nil,'hidden' end
    return node
end
local function lord_page(announce)
    local context=lord_context()
    if not context then
        if lord_discovery then invalidate() end
        return 'blocked'
    end
    local d=lord_discovery
    if not d or d.generation~=generation or d.root_address~=context.root_address or d.panel_address~=context.panel_address then
        lord_begin(context); d=lord_discovery
    end
    if not d.done then
        d.page=d.page+1
        local examined=0
        while examined<48 and d.head<=#d.queue and d.visited<1536 do
            local item=d.queue[d.head]; d.head=d.head+1
            examined=examined+1; d.visited=d.visited+1
            -- Resolve the index path again from this request's fresh root.
            -- No native component or address is retained between requests.
            local node,reason=lord_resolve(context.root,item.path)
            if node then
                local values,types={},{}
                local getters={
                    Id=function() local v=node:Id(); return v end,
                    GetStateText=function() local v=node:GetStateText(); return v end,
                    GetTooltipText=function() local v=node:GetTooltipText(); return v end,
                    CurrentState=function() local v=node:CurrentState(); return v end,
                    ChildCount=function() local v=node:ChildCount(); return v end,
                    IsInteractive=function() local v=node:IsInteractive(); return v end}
                for _,method in ipairs({'Id','GetStateText','GetTooltipText','CurrentState','ChildCount','IsInteractive'}) do
                    local ok,value=lord_read(getters[method])
                    types[method]=ok and type(value) or 'error'
                    values[method]=value
                    local wanted=(method=='ChildCount' and 'number') or (method=='IsInteractive' and 'boolean') or 'string'
                    if not ok or type(value)~=wanted then d.errors=d.errors+1; d.limited=true end
                end
                local id,text,tip,state=lord_text(values.Id),lord_text(values.GetStateText),lord_text(values.GetTooltipText),lord_text(values.CurrentState)
                local count=values.ChildCount
                local valid_count=type(count)=='number' and count==count and count>=0 and count%1==0
                if not valid_count then count=0; d.limited=true end
                lord_log('{"kind":"node","run":' .. lord_run .. ',"page":' .. d.page
                    .. ',"path":' .. quote(item.label) .. ',"id":' .. quote(id)
                    .. ',"text":' .. quote(text) .. ',"tooltip":' .. quote(tip) .. ',"state":' .. quote(state)
                    .. ',"visible":true,"children":' .. count .. ',"interactive":' .. tostring(values.IsInteractive==true)
                    .. ',"text_type":' .. quote(types.GetStateText) .. ',"tooltip_type":' .. quote(types.GetTooltipText) .. '}')
                local name=clean(text)
                local tooltip=clean(tip)
                local function entry(suffix,label)
                    if label=='' then return end
                    if #controls>=512 then d.limited=true; return end
                    local key='lord:' .. item.label .. ':' .. suffix
                    local entry_item={key=key,name=label,
                        state=(state=='selected' or state=='inactive') and state or '',read_only=true,id=id,raw_state=state}
                    -- Remember where the few named fields live so a later
                    -- browse can notice a manual lord/difficulty change.
                    local field=lord_names[key]
                    if suffix=='text' and field and field.id==id then
                        local path={}
                        for part,value in ipairs(item.path) do path[part]=value end
                        entry_item.watch_path,entry_item.watch_text=path,label
                        if lord_awaiting and field.label=='Selected lord' then
                            log('activation.observed_result',(label==lord_awaiting and 'lord-match:' or 'lord-mismatch:') .. label)
                            announce_prefix=label==lord_awaiting and ('Confirmed: ' .. label .. ' is now the selected lord. ')
                                or ('Selection not confirmed: the selected lord is ' .. label .. '. ')
                            lord_awaiting=nil
                        end
                    end
                    controls[#controls+1]=entry_item
                end
                entry('text',name)
                if tooltip~=name then entry('tooltip',tooltip) end
                -- Ancestor IDs travel with each queued path so lord portraits
                -- can be recognised and re-verified by their exact ID chain.
                local child_ids={}
                for part,value in ipairs(item.ids or {}) do child_ids[part]=value end
                child_ids[#child_ids+1]=id
                local ids,depth=item.ids or {},#(item.ids or {})
                if depth>=4 and ids[depth]=='list_box' and ids[depth-1]=='list_clip' and ids[depth-2]=='list'
                    and ids[depth-3]=='lord_select_list' and id~='' and id~='race_spacer' and id~='show_all_dlc'
                    and (state=='active' or state=='selected') and values.IsInteractive==true then
                    if #controls>=512 then d.limited=true else
                        local path={}
                        for part,value in ipairs(item.path) do path[part]=value end
                        controls[#controls+1]={key='lord:' .. item.label .. ':choice',name='Lord choice: ' .. id,
                            state=state=='selected' and 'selected' or '',read_only=false,id=id,raw_state=state,
                            lord_choice=true,choice_path=path,choice_ids=ids}
                    end
                end
                if #item.path>=16 and count>0 then d.limited=true
                else
                    if count>100 then d.limited=true end
                    for index=0,math.min(count,100)-1 do
                        if #d.queue>=2048 then d.limited=true; break end
                        local path={}
                        for part,value in ipairs(item.path) do path[part]=value end
                        path[#path+1]=index
                        d.queue[#d.queue+1]={path=path,label=item.label .. '.child' .. index,ids=child_ids}
                    end
                end
            else
                if reason~='hidden' then d.errors=d.errors+1; d.limited=true end
                lord_log('{"kind":"skip","run":' .. lord_run .. ',"page":' .. d.page
                    .. ',"path":' .. quote(item.label) .. ',"reason":' .. quote(reason) .. '}')
            end
        end
        d.done=d.head>#d.queue or d.visited>=1536
        if d.visited>=1536 and d.head<=#d.queue then d.limited=true end
        lord_log('{"kind":"page","run":' .. lord_run .. ',"page":' .. d.page
            .. ',"examined":' .. examined .. ',"total":' .. d.visited .. ',"remaining":' .. math.max(0,#d.queue-d.head+1)
            .. ',"entries":' .. #controls .. ',"errors":' .. d.errors .. ',"done":' .. tostring(d.done)
            .. ',"complete":' .. tostring(d.done and not d.limited) .. ',"limited":' .. tostring(d.limited) .. '}')
    end
    screen_kind='lord_discovery'
    local result=d.done and (d.limited and 'discovery-limited' or 'discovery-complete') or 'discovery-page'
    if announce then speak('Lord setup discovery page ' .. d.page .. '. ' .. d.visited .. ' nodes examined. '
        .. #controls .. ' captured text entries. ' .. (d.done and (d.limited and 'Capture limited.' or 'Discovery complete.') or 'More pages available.') .. ' Read only. No game action was sent.') end
    return result
end
-- Re-read only the watched named fields (at most five short paths). Returns
-- the label of the first field that changed, vanished or failed to read.
local function lord_changed_field(context)
    for _,item in ipairs(controls) do
        if item.watch_path then
            local node=lord_resolve(context.root,item.watch_path)
            if not node then return item.watch_text end
            local ok,text=lord_read(function() local v=node:GetStateText(); return v end)
            if not ok or clean(text)~=item.watch_text then return item.watch_text end
        end
    end
    return nil
end
local function lord_browse(step)
    local context=lord_context()
    if not context then
        if lord_discovery then invalidate() end
        return false
    end
    local d=lord_discovery
    if d and d.generation==generation and d.root_address==context.root_address
        and d.panel_address==context.panel_address then
        local changed=lord_changed_field(context)
        if changed then
            lord_log('{"kind":"stale","run":' .. lord_run .. ',"field":' .. quote(changed) .. '}')
            lord_begin(context); d=lord_discovery
            announce_prefix='Lord setup changed. '; step=1
        end
    end
    local before=#controls
    if not d or d.root_address~=context.root_address or d.panel_address~=context.panel_address
        or d.generation~=generation or #controls==0 or (step>0 and control_index==#controls and not d.done) then
        lord_page(false)
        if before==#controls and lord_discovery and not lord_discovery.done and control_index==#controls then
            speak('Lord setup discovery page ' .. lord_discovery.page .. ' has no new readable entries. Press F2 to continue discovery. Read only.')
            return true
        end
    end
    if #controls==0 then
        speak('Lord setup discovery has no readable text on this page. Press F2 for the next page. Read only.')
    else announce_control(step) end
    return true
end

-- Resolve a captured path from a fresh root, requiring every ancestor to be
-- visible and to have the exact captured ID, and the leaf to have leaf_id.
local function lord_resolve_checked(root,path,ids,leaf_id)
    if #path~=#ids+1 then return nil,'identity' end
    local node=root
    for step,index in ipairs(path) do
        local ok,visible=lord_read(function() local v=node:Visible(true); return v end)
        if not ok or visible~=true then return nil,'hidden' end
        local found,address=lord_read(function() local v=node:Find(index); return v end)
        if not found or not address then return nil,'missing' end
        local converted,child=lord_read(function() local v=UIComponent(address); return v end)
        if not converted or not child then return nil,'read-error' end
        local id_ok,id=lord_read(function() local v=child:Id(); return v end)
        local wanted=step<=#ids and ids[step] or leaf_id
        if not id_ok or id~=wanted then return nil,'identity' end
        node=child
    end
    local ok,visible=lord_read(function() local v=node:Visible(true); return v end)
    if not ok or visible~=true then return nil,'hidden' end
    return node
end
-- Double-confirmed lord selection. Only lord-choice entries from a complete,
-- still-current capture; every other Lord setup entry stays read only.
local function lord_activate()
    local item,d=controls[control_index],lord_discovery
    if item.raw_state=='selected' then cancel(); speak(item.id .. ' is already the selected lord. No game action was sent.'); return end
    if not d or not d.done or d.limited then
        cancel(); speak('Finish reading the lord setup with F2 before choosing a lord. No game action was sent.'); return
    end
    local context=lord_context()
    if not context or d.generation~=generation or context.root_address~=d.root_address or context.panel_address~=d.panel_address then
        invalidate(); speak('Lord setup could not be verified. Browse again. No game action was sent.'); return
    end
    if lord_changed_field(context) then invalidate(); speak('Lord setup changed. Browse again. No game action was sent.'); return end
    local node,reason=lord_resolve_checked(context.root,item.choice_path,item.choice_ids,item.id)
    if not node then invalidate(); speak('Lord choice could not be verified: ' .. reason .. '. No game action was sent.'); return end
    local interactive_ok,interactive=lord_read(function() local v=node:IsInteractive(); return v end)
    local state_ok,state=lord_read(function() local v=node:CurrentState(); return v end)
    if not interactive_ok or interactive~=true or not state_ok or state~='active' then
        invalidate(); speak('Lord choice state changed. Browse again. No game action was sent.'); return
    end
    local now=clock_value()
    if pending and (now<pending.armed_at or now>pending.deadline) then
        cancel(); speak('Confirmation expired or the clock changed. Press F4 to start again.'); return
    end
    if not pending then
        pending={target=item.key,armed_at=now,deadline=now+4,fingerprint=item.id,generation=generation,origin=activation_origin}
        activation_outcome='armed'
        log('activation.armed',now)
        speak('Select lord ' .. item.id .. '. Press F4 again within four seconds.'); return
    end
    if pending.target~=item.key or pending.generation~=generation or pending.fingerprint~=item.id then
        invalidate(); speak('Confirmation cancelled because the selection changed.'); return
    end
    if log_failed then invalidate(); speak('Diagnostic log is full or unavailable. Restart the preview.'); return end
    lord_awaiting=item.id
    send_click(node,'Lord choice: ' .. item.id)
    speak('Input sent to select ' .. item.id .. '. Press F2 to read the updated setup and confirm.')
end

local function lifecycle(name)
    generation = generation + 1
    invalidate()
    log(name, generation)
end
core:add_ui_created_callback(function() lifecycle('lifecycle.created'); if start_automation then start_automation() end end)
core:add_ui_destroyed_callback(function() lifecycle('lifecycle.destroyed') end)
-- These observed campaign-named notifications are supplementary cancellation
-- hooks; the captured frontend layout check is required independently of them.
for _, event in ipairs({'PanelOpenedCampaign', 'PanelClosedCampaign'}) do
    local event_name = event
    core:add_listener('graphics_preview_' .. event_name, event_name, true,
        function() lifecycle(event_name) end, true)
end
-- Record a bounded sample of engine shortcut events independently of whether
-- our navigation filter accepts them. This distinguishes missing/remapped keys
-- from callback errors without guessing about NVDA or keyboard interception.
local shortcut_samples = 0
core:add_listener('graphics_preview_shortcut_trace', 'ShortcutTriggered', true,
    function(c)
        if shortcut_samples >= 64 then return end
        shortcut_samples = shortcut_samples + 1
        local shortcut
        local ok, err = pcall(function() shortcut = c.string end)
        if ok then log('shortcut.seen', type(shortcut) .. ':' .. tostring(shortcut))
        else log('shortcut.ERROR', err) end
    end, true)
-- Both real keyboard input and the opt-in driver call these exact handlers.
-- The driver never synthesizes or reports a ShortcutTriggered event.
local function navigate(shortcut, source)
    interaction_revision = interaction_revision + 1
    log('navigation.source', source)
    log('navigation.received', shortcut)
    log('navigation.cached', type(captured) .. ':' .. tostring(captured))
    log('navigation.runs', type(runs) .. ':' .. tostring(runs))
    local ok, err = pcall(function()
        cancel()
        if (lord_discovery or not captured or screen_kind=='unknown') and lord_browse(shortcut=='script_F2' and 1 or -1) then return end
        if captured and not screen_still_current() then
            log('navigation.screen_changed', true); invalidate()
        end
        if not captured then browse_snapshot = capture('browse') end
        if shortcut == 'script_F2' then announce_control(1) else announce_control(-1) end
    end)
    -- These calls sit outside the pcall above; if a string call broke the
    -- runtime, report it here instead of failing the automation request.
    local reported = pcall(function()
        if not ok then
            invalidate(); log('navigation.ERROR', err)
            speak('Navigation failed: ' .. tostring(err) .. '. Send the native preview log.')
        else log('navigation.COMPLETE', shortcut) end
    end)
    if not reported then plain_log('navigation.REPORT_FAILED', ok and 'after-success' or 'after-error') end
    return ok
end
local function request_activation(source)
    interaction_revision = interaction_revision + 1
    activation_origin, activation_outcome = source, 'blocked'
    local lord_mode=lord_discovery or screen_kind=='lord_discovery'
    if lord_mode then
        local item=controls[control_index]
        if not (item and item.lord_choice) then cancel(); speak('Lord setup discovery is read only. No game action was sent.'); return true,'blocked' end
    end
    log('activation.source', source); log('activation.received', 'script_F4')
    if pending and pending.origin ~= source then
        cancel(); log('activation.confirmation_source_changed', source)
        speak('Confirmation cancelled because the input source changed.'); return false, 'blocked'
    end
    local ok, err = pcall(function() if lord_mode then lord_activate() else activate_control() end end)
    if not ok then
        local after_input = activation_outcome == 'input-sent'
        invalidate(); log('activation.ERROR', err)
        activation_outcome = after_input and 'error-after-input' or 'error'
        speak('Activation could not be verified: ' .. tostring(err))
    end
    return ok, activation_outcome
end
core:add_listener('graphics_preview_navigation', 'ShortcutTriggered',
    function(c)
        local shortcut = c.string
        return shortcut == 'script_F2' or shortcut == 'script_F3'
    end,
    function(c) navigate(c.string, 'keyboard') end, true)
core:add_listener('graphics_preview_activation', 'ShortcutTriggered',
    function(c) return c.string == 'script_F4' end,
    function() request_activation('keyboard') end, true)

-- Development-only local channel. No marker means no timer, request read or
-- native action. Never execute received text or accept arbitrary component IDs.
-- The shipped timer_manager requires a Timers global absent in the live WH2
-- frontend. Use real_timer single shots and the native RealTimeTrigger event.
local auto_base, auto_owner, auto_expiry, auto_timer
local auto_running, auto_seq, auto_result, auto_last_request, auto_last_status = false, 0, 'ready', nil, nil
local auto_name = 'warhammer_accessibility_automation'
local function automation_log(stage,value)
    -- Keep transport diagnostics independent of the original UI logger's
    -- tostring/sub formatting. Metadata is already bounded by this protocol.
    local text='non-string metadata'
    if type(value)=='string' then text=value end
    if log_path then append(log_path,stage .. '\tstring\t' .. text) end
end
local function read_small(path, limit)
    local data, file_kind
    local ok = pcall(function()
        local f = io.open(path,'r')
        file_kind=type(f)
        if not f then return nil end
        data = f:read(limit+1); f:close()
        if type(data) ~= 'string' or #data > limit then data=nil end
    end)
    if not auto_running and path==auto_base .. 'automation-enabled.tsv' then
        automation_log('automation.read_file_type',file_kind or 'unavailable')
        automation_log('automation.read_result',ok and 'success' or 'failure')
        automation_log('automation.read_data_type',type(data))
        if type(data)=='string' then automation_log('automation.read_length','bytes:' .. #data) end
    end
    return ok and data or nil
end
local function fields(line, count)
    if type(line) ~= 'string' then return nil,'not-string' end
    local stop = #line
    if string.byte(line,stop) ~= 10 then return nil,'missing-newline' end
    stop = stop-1
    if string.byte(line,stop) == 13 then stop=stop-1 end
    local values, position = {}, 1
    -- Parse bounded protocol bytes directly. Keep substring reads separate
    -- from delimiter detection and preserve empty fields for strict counting.
    for index=1,stop do
        local byte=string.byte(line,index)
        if byte==10 or byte==13 then return nil,'embedded-newline' end
        if byte==9 then
            local value=string.sub(line,position,index-1)
            values[#values+1]=value
            if #values>=count then return nil,'extra-fields' end
            position=index+1
        end
    end
    local value=string.sub(line,position,stop)
    values[#values+1]=value
    if #values ~= count then return nil,'field-count' end
    return values
end
local function integer(value)
    if type(value) ~= 'string' or #value==0 or #value > 10 then return nil end
    for index=1,#value do
        local byte=string.byte(value,index)
        if byte<48 or byte>57 then return nil end
    end
    local number=0
    for index=1,#value do
        number=number*10+string.byte(value,index)-48
        if number>16777215 then return nil end
    end
    return number
end
local function lease()
    local raw=read_small(auto_base .. 'automation-enabled.tsv',256)
    local value,reason = fields(raw,3)
    if not value then return nil,nil,'format:' .. (reason or 'unknown') end
    if value[1] ~= 'WH2LEASE1' or #value[2] ~= 32 then return nil,nil,'header-or-owner' end
    for index=1,32 do
        local byte=string.byte(value[2],index)
        if not ((byte>=48 and byte<=57) or (byte>=97 and byte<=102)) then return nil,nil,'header-or-owner' end
    end
    local expiry,now=value[3],unix_value()
    if not decimal_valid(expiry) or decimal_less(expiry,now) or decimal_less(decimal_add(now,1800),expiry) then return nil,nil,'expiry' end
    return value[2], expiry
end
local function publish_status()
    local item = controls[control_index]
    local label = item and clean(item.name) or '-'
    if #label > 800 then label = label:sub(1,800):gsub('[\192-\255][\128-\191]*$','') end
    local deadline='0'
    if pending then deadline=decimal_add(unix_value(),math.max(0,pending.deadline-clock_value())) end
    local values = {'WH2STATUS1','0.6.23-nvda-automation-preview',session,tostring(generation),
        tostring(interaction_revision),tostring(auto_seq),auto_result,screen_kind,
        item and item.key or '-',label,tostring(#controls),pending and pending.target or '-',
        deadline,core:is_ui_created() and '1' or '0',
        auto_running and '1' or '0',tostring(auto_expiry or 0)}
    local line = table.concat(values,'\t') .. '\n'
    if line == auto_last_status then return end
    local f = io.open(auto_base .. 'automation-status.tsv','w')
    if not f then error('Automation status unavailable') end
    local written = f:write(line)
    local closed = f:close()
    if not written or closed == nil then error('Automation status write failed') end
    auto_last_status = line
end
local function poll_automation()
    if not auto_running then return end
    -- Catch every exception: timer_manager retries callbacks that escape with
    -- an error. Requests are consumed BEFORE action, never retried after input.
    local ok, err = pcall(function()
        local owner, expiry = lease()
        if not owner or owner ~= auto_owner or expiry ~= auto_expiry then
            auto_running = false; cancel(); interaction_revision = interaction_revision+1
            auto_result = 'disabled'; auto_timer:remove_callback(auto_name); publish_status(); return
        end
        publish_status()
        local raw = read_small(auto_base .. 'automation-request.tsv',4096)
        if not raw or raw == auto_last_request then return end
        auto_last_request = raw
        local request = fields(raw,9)
        if not request or request[1] ~= 'WH2REQ1' then automation_log('automation.rejected','malformed'); return end
        if request[2] ~= auto_owner or request[3] ~= session then automation_log('automation.rejected','owner/session'); return end
        local number, wanted_generation, wanted_revision, expires = integer(request[4]), integer(request[5]), integer(request[6]), request[9]
        if not number or not wanted_generation or not wanted_revision or not decimal_valid(expires) then automation_log('automation.rejected','numbers'); return end
        if number <= auto_seq then return end -- duplicate/replay: retain the prior acknowledgement
        if number ~= auto_seq+1 then automation_log('automation.rejected','out-of-order'); return end
        auto_seq = number -- consumed before any validation or native side effect
        local action, selected, now = request[7], controls[control_index], unix_value()
        local reason
        if decimal_less(expires,now) or decimal_less(decimal_add(now,5),expires) then reason='expired'
        elseif wanted_generation ~= generation then reason='generation'
        elseif wanted_revision ~= interaction_revision then reason='revision'
        elseif request[8] ~= (selected and selected.key or '-') then reason='selection'
        elseif not core:is_frontend() or not core:is_ui_created() then reason='not-ready'
        elseif action ~= 'next' and action ~= 'previous' and action ~= 'activate' and action ~= 'discover' then reason='action' end
        if reason then
            cancel(); interaction_revision=interaction_revision+1; auto_result='rejected:' .. reason
            automation_log('automation.rejected',reason); publish_status(); return
        end
        automation_log('automation.accepted',tostring(number) .. ':' .. action)
        if action == 'next' or action == 'previous' then
            auto_result = navigate(action == 'next' and 'script_F2' or 'script_F3','automation') and 'completed' or 'error'
        elseif action=='discover' then interaction_revision=interaction_revision+1; cancel(); if lord_discovery and lord_discovery.done then invalidate() end; auto_result=lord_page(true)
        else local _, result = request_activation('automation'); auto_result=result end
        publish_status()
    end)
    if not ok then
        cancel(); interaction_revision=interaction_revision+1
        auto_result = activation_outcome == 'input-sent' and 'error-after-input' or 'error'
        pcall(function() automation_log('automation.ERROR',type(err)=='string' and err or ('error type: '..type(err))); publish_status() end)
    end
end
local function frontend_callbacks()
    local api=real_timer
    if not api or type(api.register_singleshot)~='function' or type(api.unregister)~='function' then
        error('Frontend real_timer unavailable')
    end
    local listener_name=auto_name .. '_real_timer'
    local adapter={active=false}
    function adapter:remove_callback()
        self.active=false
        api.unregister(auto_name)
        core:remove_listener(listener_name)
    end
    function adapter:repeat_callback(callback,interval,name)
        if name~=auto_name then error('Unexpected automation timer name') end
        self.active=true
        core:add_listener(listener_name,'RealTimeTrigger',
            function(context) return context.string==auto_name end,
            function()
                if not self.active then return end
                local ok,err=pcall(function()
                    callback()
                    if self.active and auto_running then api.register_singleshot(auto_name,interval) end
                end)
                if not ok then
                    auto_running=false; cancel(); interaction_revision=interaction_revision+1
                    auto_result=activation_outcome=='input-sent' and 'error-after-input' or 'timer-error'
                    pcall(function() self:remove_callback() end)
                    pcall(function()
                        automation_log('automation.timer_error',type(err)=='string' and err or type(err))
                        publish_status()
                    end)
                end
            end,true)
        api.unregister(auto_name)
        api.register_singleshot(auto_name,interval)
    end
    return adapter
end
start_automation = function()
    if auto_running then return end
    -- Reuse the directory that successfully opened the diagnostic. Do not
    -- depend on a second environment lookup in the game's restricted context.
    local suffix = 'native-ui-graphics-preview.log'
    if type(log_path) ~= 'string' or log_path:sub(-#suffix) ~= suffix then return end
    auto_base = log_path:sub(1,#log_path-#suffix)
    automation_log('automation.setup_check', auto_base == '' and 'relative-output-directory' or 'diagnostic-output-directory')
    local owner, expiry, reason
    local lease_ok = pcall(function() owner, expiry, reason = lease() end)
    if not lease_ok then automation_log('automation.setup_check','lease-exception'); return end
    if not owner then automation_log('automation.setup_check',type(reason)=='string' and reason or 'lease-unavailable'); return end
    local ok, err = pcall(function()
        if not core:is_frontend() then error('Frontend timer unavailable outside frontend') end
        automation_log('automation.real_timer_type',type(real_timer))
        auto_timer=frontend_callbacks()
        auto_owner,auto_expiry,auto_seq,auto_result = owner,expiry,0,'ready'
        auto_last_request,auto_last_status,auto_running=nil,nil,true
        auto_timer:repeat_callback(poll_automation,250,auto_name)
        automation_log('automation.enabled','lease active; native handlers; keyboard delivery untested')
        publish_status()
    end)
    if not ok then
        auto_running=false
        pcall(function() if auto_timer then auto_timer:remove_callback(auto_name) end end)
        pcall(function() automation_log('automation.setup_error',type(err)=='string' and err or ('error type: '..type(err))) end)
    end
end
local unguarded_automation_start = start_automation
start_automation = function()
    local function failed(err)
        local trace = 'optional automation initialization failed'
        if debug and type(debug.traceback)=='function' then
            local value = debug.traceback('automation startup',2)
            if type(value)=='string' then trace=value end
        end
        pcall(function() append(log_path,'automation.setup_trace\tstring\t' .. trace) end)
        return err
    end
    -- Optional development transport must never prevent the normal keyboard
    -- reader and startup speech from loading when initialization fails.
    local ok = xpcall(unguarded_automation_start,failed)
    if not ok then
        auto_running=false
        pcall(function() if auto_timer then auto_timer:remove_callback(auto_name) end end)
    end
end
core:add_listener('graphics_preview_automation_init','FrontendScreenTransition',true,
    function() if start_automation then start_automation() end end,true)
start_automation()
speak('NVDA automation preview 0.6.23. F2 next, F3 previous. New Campaign and Continue use double F4. Campaign selection has a spoken browser. Starting a campaign is not enabled.')

