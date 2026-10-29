# Automatic Lord setup refresh 0.6.19–0.6.21 — October 29, 2026

0.6.21 refreshes the Lord setup reader automatically after a manual change and
no longer stops working when the mouse touches the screen. Live-tested.

## What changed

- **Watched fields (0.6.19).** Captured entries for selected lord, race,
  faction, campaign and battle difficulty keep their index path. Each F2/F3
  re-reads only those (at most five short path lookups). If one changed,
  vanished or failed to read, discovery restarts and the next announcement
  starts at entry 1 with "Lord setup changed." No `string.find` is used.
- **Rejection diagnostics (0.6.20).** `lord_context` logs why it refused the
  screen (`lord.context_reject`, once per distinct reason).
- **Tooltip layers (0.6.21).** Selecting a lord with the mouse leaves a hidden
  root layer `tooltip_campaign_select_lord`, and a resting mouse shows the root
  `Tooltip`. The context check only allowed hidden `browser`/`Tooltip`, so any
  mouse selection silently disabled the reader (found live in 0.6.19, diagnosed
  in 0.6.20). Now `Tooltip` and `tooltip_*` layers are accepted shown or hidden
  on this read-only path; `browser` must stay hidden; anything else is still
  rejected. Up to 8 root children are allowed.
- Harness: 343 scenarios (changed lord, hidden watched field on F3, unchanged
  fields not stale, rejection logged once, tooltip layers present).

## Live result (0.6.21)

| Check | Result |
| --- | --- |
| Offline | 343 scenarios, speech trace, PS 5.1 atomic writes, pack round-trip, installer checks |
| Regression | Main menu → Select Lord; 34 labelled entries over 5 pages, wrap, explicit refresh, Start Campaign blocked, two native clicks |
| Manual change | Mouse click on the Teclis portrait (test stand-in for a user); next Next: "Lord setup changed. Lord setup, 1 of 4: Select Lord"; log `stale` field Tyrion |
| Fresh content | 32 entries, complete, 0 errors: Selected lord: Teclis, Faction: Order of Loremasters, Teclis's faction/lord effects |
| Reverse | Click Tyrion, then Previous (F3): "Lord setup changed. … 1 of 5"; `stale` field Teclis |
| Tooltip | Reader kept working with Tyrion's hover tooltip on screen |
| Native clicks by the mod | Exactly two (New Campaign, Continue); portrait clicks were test mouse input |
| Errors | No `ERROR`/`REPORT_FAILED` lines |
| Speech | 88 NVDA returns for the session companion, all code 0; audible completion not assessed |
| Shutdown | Native disabled acknowledgement; game closed gracefully |

Selecting Teclis also shows the game's notice "This Lord's campaign does not
contain any introductory content…", whose confirm button overlaps Start
Campaign. Test scripts must never click there. With 0.6.21 the reader worked
while it was displayed (Teclis capture above).

Not covered live: a difficulty dropdown change (covered by fixtures only), and
changes to unwatched text (explicit Discover still rereads everything).

Evidence: `work/live-0.6.19-lord-refresh` (first attempt, context rejected),
`work/live-0.6.20-lord-refresh` (rejection reason), `work/live-0.6.21-lord-refresh`
(pass, screenshots). Package `outputs/warhammer2-windows-0.6.21-nvda-automation-preview.zip`.
