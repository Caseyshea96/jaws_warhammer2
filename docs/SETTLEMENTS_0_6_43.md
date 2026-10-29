# Settlements by keyboard 0.6.43 — October 29, 2026

Owner's choice after the first playable turn: settlements (army movement
later). Still no map or army orders.

## What changed

- **Province rows** (`row_entry_<province>` in the Provinces tab) are one
  item each, NVDA style: "Straits of Lothern, list item, 520, Contested
  province, Public Order: Neutral, Building upgrades available, 70 of 83".
  The row's parts (`region_name`, `income`, `mon`, `icon_public_order`,
  `upgradable`) are folded into it. Enter clicks the row: the game zooms to
  the province and opens its settlement panel.
- **Buildings** (the element inside each `building_slot_N`, and the upgrade
  chain in `construction_popup` → `slot_parent`) are buttons named from the
  game's own text: `effect.get_localised_string('building_culture_variants_name_'
  .. key)` (the call the game's UI library uses), falling back to the key.
  Empty slots are "Construction slot". Value = settlement name; states:
  built / locked / not owned / "Population surplus cost N[, not enough]" /
  "Building upgrades available"; units the building recruits are read last
  ("Units: Spearmen, Archers"). Settlement names (`dy_province`), list titles
  and the settlement panel title are headings; sort buttons are buttons.
- **Build asks first**: an available upgrade in the popup says "Build Lothern
  (Elven Village)? Press Enter again to confirm."; locked ones say "… is
  unavailable." Abandon / disband / raze / demolish / dismantle buttons also
  ask first (the popup has "Click to abandon this settlement").
- **After every click the reader re-reads once** (2 s later), so changes
  deeper than the panel watch (the Provinces list) are announced. If nothing
  changed it stays quiet on the same item; if something closed it says
  "Screen updated." and stays put. New items are found by element IDs and
  names, not child positions, so a panel added at the root no longer makes
  every item "new"; the reader starts at the first new heading, then text.
- Activation still checks HUD identity, path + ancestor IDs, leaf ID and
  state (now also refusing `not_owned`); one `SimulateLClick` call site.
- Harness: 45 campaign scenarios (+3: rows and settlement panel, popup with
  build confirmation / locked / abandon, missing game text).

## Live (0.6.43, intro box unchecked, everything after Start Campaign by keys)

P → "Provinces, tab" → Enter → "Provinces activated." "Screen updated."
"Provinces, heading, 46 of 83". Down/letters read all 11 rows (above).
S → Straits of Lothern → Enter → the game zoomed and opened the settlement
panel; "Screen updated." "Lothern, heading". Slots: "Lothern (Elven Hamlet),
button, Lothern, Building upgrades available", "Straits of Lothern, button,
Lothern", "Militia Camp, button, Lothern", "Construction slot, button,
Lothern, locked" (×2), then Tower of Lysean / Glittering Tower buildings.
Enter on Lothern (Elven Hamlet) opened its upgrade chain: "Lothern (Elven
Hamlet), button, built, …, Units: Spearmen, Archers"; "Lothern (Elven
Village), button, Population surplus cost 1"; Town / City / Spired Citadel
"locked, … not enough". Enter → "Build Lothern (Elven Village)? Press Enter
again to confirm." → Enter → "Lothern (Elven Village) activated." The game
started the upgrade: treasury 6000 → 4000, growth target 600 → 200, the slot
now reads "Lothern (Elven Village), button, Lothern, Construction turns
left". Four native clicks in total (tab, row, building, build). No turn
ended, no saves written. Evidence: `work/live-0.6.43-settlements-2`
(discovery logs, screenshots). Discovery of the IDs: `work/live-0.6.42-provinces-2`.

The 0.6.42 campaign-start stall did not recur: both runs passed the flyover
to the HUD (~100 s). The intro check box was already unchecked on Select
Lord in both runs, so no click was needed.

## Known gaps (next)

- Reading order is breadth-first: the three settlement headings come before
  all buildings (each building names its settlement), the Other Provinces sort
  buttons sit between the Lothern row and the other rows, and the minimap's
  settlement icons ("Settlement: Lothern Owner: Eataine") come before rows.
- After opening the upgrade popup the reader starts at its Abandon button
  (safe: it asks first); after building it starts at the new growth value.
  Better: start at the popup's first building / the changed slot.
- Money cost is only in the game's hover tooltip; only the population
  surplus cost is read. "Construction turns left" lacks the number.
- Recruiting not tested live: Recruit Lord / Recruit Hero are ordinary
  buttons in the HUD (already activatable); their panels are unread.
- A list opened by the mouse deeper than three levels is not announced
  automatically (Shift+F3 re-reads); keyboard clicks re-read.
- Physical keys still unverified (injected keys reach only the companion).

## 0.6.44–0.6.45 (in progress, installed, not yet accepted)

- 0.6.44: popup/build focus prefers heading → building/row → text; "under
  construction, N turns left"; each settlement's buildings follow its heading;
  minimap icons last; buttons with "recruit" in the ID ask first. Live: the
  reader's timer event was lost mid-scan after selecting a province (silent,
  no error) — the same cause as the 0.6.42 "flyover stall".
- 0.6.45: a watchdog timer re-arms the reader when ticks stop; Shift+F3 also
  re-arms. Harness 47. Live: Provinces → row → settlement panel announced;
  new building order confirmed. Not yet heard: focus after opening the
  upgrade popup, build focus, turns-left number, Recruit Hero panel.
  Evidence: work/live-0.6.44-settlements, work/live-0.6.45-settlements.
  Accepted rollback stays 0.6.43.

### Blocker found (0.6.45 live, October 29 evening)

The building upgrade popup (`construction_popup`) is hover-bound: the game
closes it as soon as the mouse pointer is not over the building or popup.
The mod's click opens it, but it closes at once unless the pointer happens
to be there. In the 0.6.43 run the pointer was by chance over the popup
area (a map hover tooltip at that spot is visible in its screenshot), which
is why building worked; in three 0.6.45 attempts it did not open by keyboard.
A real test mouse click on the slot opened it; moving the pointer away
closed it (screenshots in `work/live-0.6.45-settlements-3`). In one session
a ChatGPT/Codex always-on-top, click-through overlay (0,0–467,1080) was also
on screen and real clicks did nothing; without it they worked.
Options: the companion moves the pointer onto the building when it is
activated (needs the element's screen position: Position()/Bounds() plus the
game window's client rectangle); or find another construction path.
