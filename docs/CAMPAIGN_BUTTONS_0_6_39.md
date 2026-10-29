# Campaign HUD buttons 0.6.38–0.6.39 — October 29, 2026

Owner allowed activating campaign HUD buttons. Still no map or army orders.

- Enter (companion key while HUD reading is on) or F4 activates the current
  item only if its ID marks it as a button (`button_*`, the advisor portrait)
  or a tab (`tab_*`). Text, headings and toggles: "Not supported yet."
- Before the click: the capture must still match the HUD (root/layout
  identity and count), the element is re-resolved from a fresh root by its
  captured path and ancestor IDs, its leaf ID must match, and it must be
  interactive and not inactive/locked/disabled ("<name> is unavailable.").
  A changed target is never clicked: "The screen changed. Reading it again."
- End Turn and any Quit/Exit/Load button ask first ("End turn? Press Enter
  again to confirm."); moving cancels; ~10 s window.
- One native click call site in the campaign module (static check asserts
  exactly one). The developer request channel stays capture-only.
- After a click, the automatic re-read announces the result ("Screen
  updated." + first new item).
- 0.6.39: per-element child limit 100 → 256 (the help panel lists 224
  topics); players read three pages per second (re-read ≈ 3 s), developer
  mode keeps one.
- Harness: 39 campaign scenarios (buttons, tabs, text, toggle, heading,
  unavailable, End Turn confirm/cancel, replaced target).

## Live

0.6.38: H → "Help Pages, button, 3 of 50"; Enter → "Help Pages activated." —
the game's help panel opened (screenshot); the auto re-read said "Screen
updated." "Next, button, 7 of 53" but was limited (224-entry list > 100).
0.6.39: same steps → complete re-read, 61 items, "Next, button, 7 of 61".
The tutorial locks Diplomacy/Technology/etc. while its advice is showing.
No saves written. Evidence: `work/live-0.6.38-campaign-buttons`,
`work/live-0.6.39-campaign-buttons`.

Not verified: End Turn live (deliberately not pressed), physical keys.

## 0.6.40: dialogs, live advisor text, End Turn attempt (live)

- After an automatic re-read, the reader starts at the new panel's heading or
  text rather than its first button. Live: dismissing How They Play →
  "Screen updated." "Mission Issued!, heading, 34 of 57".
- Advisor (`Text`) and notification (`dy_notification`) lines are re-checked
  every second and spoken when they change ("Advisor: …"), like a live
  region. Covered by the harness; the advisor line did not change during the
  live runs.
- The developer three-capture cap now applies only to explicit client
  requests; automatic re-reads do not count.
- End Turn, live: with the tutorial on, the game keeps End Turn and Skip
  inactive until tutorial objectives are done — the reader said "End turn is
  unavailable." and sent nothing. Without the tutorial (intro check box
  cleared by a test mouse click), after dismissing How They Play and Mission
  Issued!, End Turn asked for confirmation and the click was sent three times
  ("End turn activated."). The first press made the game select the unmoved
  lord (announced: "Screen updated." "Tyrion Legendary Lord, 12 of 92 …").
  The turn still did not advance (treasury unchanged), most likely because of
  the pending "Lord not moved" notification or a dialog not yet identified.
  Unresolved; no saves written.
- Harness: 40 campaign scenarios.
Evidence: `work/live-0.6.40-endturn`, `work/live-0.6.40-endturn-notutorial`.

## 0.6.41: unlabelled buttons named; End Turn reaches turn 2 (live)

Why the turn did not advance: WH2 keeps End Turn waiting while advice or
notifications are pending, and the advisor's Close button (and similar check
marks) has no text or tooltip, so the reader never listed it — a keyboard
user could not dismiss advice.

- Unlabelled active `button_*` elements are now listed with a name from the
  ID ("Close advice, button" under the advice interface; "Subpanel",
  "Notification" …). Test-only IDs and inactive buttons stay hidden.
- Live, without the tutorial (intro check box cleared; note the first click
  on an unfocused game window only focuses it): dismissed How They Play and
  Mission Issued! (test mouse clicks); C → "Close advice, button" → Enter →
  "Close advice activated." "Screen updated."; End Turn's tooltip became
  "Resolve or skip this notification to end turn"; S → "Skip, button, Skip
  current notification" → Enter, three times (the reader announced each new
  notification live: "Settlement upgrade available", "Research available",
  "End turn"); then End Turn → confirm → "End turn activated." The AI turns
  ran; treasury 6000 → 7901, turn counter 2; "Screen updated." "High
  Elves, 7 of 51" (new advice).
- The game wrote its own autosave at turn 2
  (`Eataine_Auto-save1557312775.save`, 5.6 MB) into the previously empty
  save folder — left in place for the owner to keep or delete.
- Harness: 41 campaign scenarios.
Evidence: `work/live-0.6.41-endturn`, `work/live-0.6.41-endturn-2`.

## 0.6.42: first turn played entirely by keyboard (live)

- Unlabelled `button_*` elements are listed only in clickable states
  (active/hover/selected/down); NewState containers ("Set") are dropped.
- Main-menu template: with saves present the game enables Continue Campaign
  and Load Campaign; their state/interactivity may now differ (identities and
  labels exact). The test autosave had made New Campaign refuse ("Could not
  verify this screen") — the safety check working; now handled.
- `tools/live/Press-Item.ps1` (letter until item, Enter N times).
- Live (intro check box cleared by mouse; everything else by keys): A → Accept
  (How They Play), A → Accept (Mission Issued!), C → Close advice, S → Skip
  ×3 (notifications announced live), E → End turn, confirm → "End turn
  activated." → "Screen updated." … "Current turn number, 2". Harness: 371
  frontend + 42 campaign scenarios. A second autosave was written.
Evidence: `work/live-0.6.42-keyboard-turn-3`.

## Open: settlements work started; campaign start stalled (0.6.42, live)

Goal (owner choice): settlements — open the Provinces tab (`tab_regions`),
choose a province row to select its settlement, read the settlement panel,
build/recruit through its buttons. Province rows are probably not `button_*`
IDs, so activation will need to cover list rows (inspect their IDs first).

This attempt (tutorial left on) never reached the HUD: the campaign module
logged loading-screen → cinematic-visible at 17:16:57, its status stopped
updating at 17:17:41, and the game showed the same flyover frame for 7+
minutes, even after a title-bar click to focus it. Earlier tutorial runs did
pass the flyover. Unknown whether the game froze, paused for input, or the
real_timer stopped. Evidence: `work/live-0.6.42-provinces`. Next session:
reproduce once; if it recurs, compare with work/live-0.6.37 (passed).
