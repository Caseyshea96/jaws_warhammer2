# Campaign HUD reading with standard keys 0.6.34–0.6.35 — October 29, 2026

Owner chose a toggle (like NVDA's browse/focus mode) so the arrows can still
move the camera.

- The campaign reader now runs for players (no developer flag): read-only,
  waits for the HUD after loading/flyover, reads it, says "Campaign map, N
  items." and the first item. No diagnostic status/request files in player
  mode; its log restarts past 1 MiB so long sessions keep working. The
  developer flag keeps Codex's status/request channel and limits.
- Shift+F2 (a game script shortcut, so it reaches the mod directly): "Reading
  HUD." + current item / "Map controls.". While HUD reading is on, the mod
  writes the same reader-state heartbeat as the menus (`1 campaign`) and polls
  keys.tsv every 100 ms, so the companion's Down/Up, Tab, Home/End, letters
  and Enter/Space read HUD items (Enter: "Not supported yet."). While off, the
  companion releases the keys to the game.
- Shift+F3 re-reads the campaign screen. F2/F3 still browse; F4 "Not
  supported yet."
- Developer verify mode turns HUD reading on after its self-test (Shift+F2
  cannot be injected), at a one-second pace that keeps Codex's limits.
- Static check now allows the campaign module to use reader-state.tsv and
  keys.tsv (owner-approved); string.find, clicks, shortcut triggers and model
  queries stay forbidden. Harness: 370 frontend + 35 campaign scenarios.

## Live

0.6.34: reader mode turned on, but only End/Home arrived — in verify mode the
heartbeat was rewritten every 10 s, so the companion saw it as stale (>3 s).
0.6.35 writes it every second. Live: Down×3 → "Advisor, button, 2 of 50",
"Help Pages, button, 3 of 50", "Spell Browser, button, 4 of 50"; End → "The
Lore of Learning, 50 of 50"; Home → "Menu, button, 1 of 50"; T → "Technology,
button, 14 of 50, Advance your faction's capabilities …"; Enter → "Not
supported yet.". 50 items, 0 issues; no saves written; graceful close.

Not verified: Shift+F2/Shift+F3 and arrows on a physical keyboard (injected
keys never reach the game), and whether the camera also moves when a physical
arrow is taken for reading.

Evidence: `work/live-0.6.34-campaign-keys`, `work/live-0.6.35-campaign-keys`.

## 0.6.36–0.6.37: automatic announcements when the screen changes (live)

Like a screen reader announcing a newly opened dialog: once a second the
reader takes a signature of which panels are showing (three levels deep,
capped at 300 elements; hover tooltip and world/visual layers ignored). When
it differs from the captured screen and has stayed the same for two seconds
(so blinking never triggers it), the screen is re-read automatically and the
reader says "Screen updated." and moves to the first new item. A cancelled
capture (HUD changed while browsing) also re-reads automatically.

0.6.36 compared only top-level panels and missed the tutorial's panel swap
(How They Play → Mission Issued!, inside a container). 0.6.37 live: 15 quiet
seconds with no false "Screen updated"; dismissing How They Play (mouse click
on its check mark, a tutorial dismissal) → "Screen updated." "Mission Issued!,
heading, 34 of 57". No saves written. Harness 37 campaign scenarios.
Evidence: `work/live-0.6.36-campaign-refresh`, `work/live-0.6.37-campaign-refresh`.
