# Campaign reader 0.6.31–0.6.32 — October 29, 2026

Picked up Codex's 0.6.31 checkpoint (read-only campaign diagnostic, built in a
parallel Codex session on top of 0.6.28) and completed its live test.

## 0.6.31 live (Codex candidate, unchanged)

One Tyrion campaign started through the confirmed Start Campaign. The module
waited through loading → flyover → HUD stabilising, then read the HUD: 59
items, 1 issue — the "How They Play" description exceeded the 1000-character
text bound, which marked the capture "limited" and skipped the cursor
self-test. Explicit Capture request (refresh) worked (run 2, same 59).
Speech worked in campaign but used "…, text, 1 of 59." with game markup, and
item 1 was the hover tooltip under the resting mouse. (0.6.30 for comparison:
read during the flyover, 6 entries, 70 issue increments.)

## 0.6.32 changes

- Campaign text bound 4000 characters (long panel descriptions are normal).
- Root hover `Tooltip` excluded ("hover-tooltip").
- One item per element: tooltips "Name||Description" label a value
  ("Treasury, 6000, This is the total amount …"); tooltip-only buttons use the
  name with the description after the position.
- NVDA order: name, role, value, N of M, description; roles from IDs
  (button_, tab_, toggle_); no "text" role, no trailing period. F4: "Not
  supported yet." Announcements "Reading the campaign map." / "Campaign map,
  53 items."
- Test skip pack also empties `movies/warhammer2/hef/hef_intro.ca_vp8` (the
  in-engine flyover still plays). Campaign start → leaves menus in ~7 s.
- Harness: 370 frontend + 33 campaign scenarios.

## 0.6.32 live

Complete capture: 53 items, 0 issues, phase ready; cursor self-test passed
(53 entries, both wraps); hover tooltip excluded; speech "Menu, button, 1 of
53". No saves written; flag/request removed; game closed gracefully.

Reconstructed item list includes: Menu/Advisor/Help Pages buttons; Events,
Lords & Heroes, Provinces, Known Factions, Missions & Quests tabs; Diplomacy,
Technology, Intrigue at the Court, Rites; "Current turn number, 1";
"Influence, 0"; How They Play / Eataine; advisor text; "Treasury, 6000";
rituals; Missions: The Lore of Learning.

## Not done / next

- Income reads as "(", "1901", ")"; End Turn reads its tooltip text; some bare
  numbers lack labels — group/label these.
- Browsing in campaign uses physical F2/F3 only (arrows pan the camera; the
  companion's menu keys are frontend-only). Not verified with physical keys.
- Campaign activation, map actions, gameplay and co-op remain blocked.

Evidence: `work/live-0.6.31-campaign`, `work/live-0.6.32-campaign`.
