# Lord selection 0.6.22–0.6.23 — October 29, 2026

The owner unblocked keyboard lord selection on Select Lord. Starting a
campaign, settings changes, gameplay and co-op remain blocked. 0.6.23 selects
lords through the reader with a double-confirmed F4 and confirms the result
in speech. Live-tested.

## Behaviour

- Lord portraits (children of `lord_select_list › list › list_clip › list_box`
  with state `active`/`selected`, interactive, not `race_spacer`/`show_all_dlc`)
  are captured as entries: "Lord choice: Teclis", the current one with ", selected".
  The capture grows from 34 to 53 entries (19 visible portraits).
- F4 on a lord choice arms ("Select lord Teclis. Press F4 again within four
  seconds."); a second F4 within four seconds sends one native click. Browsing
  between presses cancels; expiry, a changed watched field, an incomplete or
  limited capture, a changed root/panel/generation, or a changed ancestor ID
  chain/leaf ID/state blocks with "No game action was sent."
- F4 on the selected lord: "… is already the selected lord." F4 on any other
  Lord setup entry, including Start Campaign: "read only".
- After the click the capture is cleared; the next browse re-reads and says
  "Confirmed: Teclis is now the selected lord." (or "Selection not confirmed:
  the selected lord is …") and logs `activation.observed_result lord-match:…`.
- Automation uses the same handler: two separately accepted Activate requests.
- One native click call site remains (`send_click`), shared by all targets.

## Tests

- Harness: 350 scenarios — selection with observed match, ignored click
  (mismatch spoken), already selected, read-only entries, cancel by browsing,
  expiry, changed identity, stale watched field, incomplete capture,
  automation double confirm, Start Campaign blocked. Breaking the ancestor-ID
  check or the complete-capture check makes the harness fail.
- Expected live catalog regenerated (53 entries): recorded live, every old
  entry unchanged, every new entry a lord choice for a visible portrait.

## Live result (0.6.23)

| Check | Result |
| --- | --- |
| Regression | 53 entries over 5 pages with expected labels, wrap, explicit refresh, Start Campaign blocked, two menu clicks |
| Select Teclis | One click; screen shows Teclis / Order of Loremasters; "Confirmed: Teclis is now the selected lord."; `lord-match:Teclis` |
| Re-select | Refused, no click |
| Select Tyrion | One click; confirmed; `lord-match:Tyrion` |
| Incomplete capture guard | Seen live: F4 during page 2 of 5 refused with "Finish reading the lord setup…", nothing sent |
| Totals | 6 native clicks (New Campaign, Continue, 4 lord selections); no ERROR lines; 349 NVDA returns, all code 0 (audible completion not assessed) |
| Shutdown | Native disabled acknowledgement; game closed gracefully |

0.6.22 was the first live candidate: selection worked (Teclis selected,
`lord-match`), but there was no spoken confirmation; 0.6.23 adds it. Test
script bugs found during the run (PowerShell 5.1 single-item unrolling, empty
argument dropped by `-File`, missing capture completion before choosing) were
client-side and are fixed in `tools/live/Test-LordSelect.ps1`.

## Open

- Choosing a lord mid-capture requires finishing the capture first (safe but
  slow for a user); consider completing remaining pages inside the F4 handler.
- Lords hidden behind "Show all" DLC filtering are not offered.
- Selecting a lord without introductory content shows a game notice whose
  confirm button overlaps Start Campaign; it is not read or actionable yet.

Evidence: `work/live-0.6.22-lord-select`, `work/live-0.6.23-lord-select`.
Package: `outputs/warhammer2-windows-0.6.23-nvda-automation-preview.zip`.
