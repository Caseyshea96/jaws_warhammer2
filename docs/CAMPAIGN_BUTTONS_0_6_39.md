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
