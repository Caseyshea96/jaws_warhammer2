# Approved campaign diagnostic test — October 29, 2026

**Result: partial discovery, not a clean pass. Accepted 0.6.28 is restored.**
The owner explicitly approved one Tyrion test campaign in this chat. Exactly
one Start Campaign click was sent, after its mandatory confirmation. The game
reached the campaign opening flyover and later the normal map/HUD. No map,
movement, combat, end-turn or other gameplay command was issued.

| Check | Actual result |
| --- | --- |
| Menu route | New Campaign → Select Campaign → Continue → Select Lord |
| Selected setup | Fresh native capture verified Tyrion, High Elves, Eataine; complete Lord snapshot |
| Start confirmation | Prompt spoken, then exactly one Start Campaign click |
| Total native UI clicks | Three: New Campaign, Continue, Start Campaign |
| Campaign module | Loaded in campaign context and performed bounded UI reads |
| Capture | Three pages of 48, 48 and 46 paths; 142 examined paths, 47 visible node rows, six text entries |
| Read quality | 70 reported read/type issue increments; limited=true, complete=false |
| Log size | 15,769 bytes; no budget exhaustion |
| Native cursor self-test | Not run because capture was limited; full browse/wrap not passed |
| Campaign speech | Three bridge speech records; two NVDA requests/returns, both code 0 |
| Physical keys / audible completion | Not verified |
| Saves | Folder remained empty; saves/advice history backed up before the start |
| Cleanup | Game and owned companion closed; owned diagnostic flag and automation lease removed |
| Final install | 0.6.28, all installed runtime payload hashes match |

## What the live test established

The new module can run after entering campaign context and send campaign text
through the existing NVDA bridge. It did not read the normal HUD successfully.
Its root snapshot contained visible cinematic_bars and advice_interface while
most other panels were hidden. Six entries concerned Technologies/advice.
The later visible HUD instead showed Tyrion at Lothern, treasury 6000, income
1901, How They Play / Eataine and Missions & Quests. Those later labels are
visual observations, not text successfully captured by this diagnostic.

The scan therefore ran during the opening sequence. It exhausted its current
visible queue but recorded 70 issue increments. Those increments can include
failed calls and unexpected return types; the current log does not distinguish
all getter types. They must not be described as 70 uniquely identified engine
failures. Exact getter causes remain unproven. The capture is incomplete and
must never become an activation template.

A preceding session stalled at Select Lord before its next read request was
consumed. It logged zero Start Campaign clicks and was closed. A fresh session
verified the Lord snapshot and completed the approved start. The cause of the
pre-start frame/timer stall remains unproven. It did not consume a second test
campaign; only one campaign was started across these sessions.

## Resume point

1. Add per-getter success/type diagnostics to distinguish missing optional text
   from genuine native read failures. Keep strict identity/visibility checks.
2. Wait for an observed normal-HUD readiness condition after the cinematic,
   or add a bounded explicit read-only recapture request for later UI state.
3. Verify a fresh post-cinematic capture, then native browse/wrap and speech.
   Keep campaign activation, model queries and gameplay commands disabled.

No additional campaign start is implied by the one-campaign approval. Preserve
0.6.28 as the accepted rollback. Candidate 0.6.30 remains in source and packaging;
it is not promoted. The pre-live checks still stand: 370 frontend and 16 campaign
fixtures plus pack/speech/atomic-write/installer checks passed, but did not
predict these live timing/type issues.

## Evidence

- work/live-0.6.30-campaign-approved: pre-start stall, zero-start record and backups.
- work/live-0.6.30-campaign-approved-recovery: actual test, native/UI/speech logs,
  campaign-catalog.json, campaign-audit.json, start-campaign.json and backups.
- Same folder: final-checkpoint.json verifies rollback and stopped processes.
- work/audit-campaign-discovery-0.6.30.py reconstructs the captured catalog and
  checks budgets, native self-test, speech correlation and exactly three clicks.
- Campaign visuals were observed using Computer Use in this chat; no screen-
  coordinate campaign activation was used.

Native disabled acknowledgement was not observed from the retired frontend
channel after campaign entry. Removed markers and verified process shutdown
are the cleanup evidence. Unrelated files, saves, settings and NVDA were left
untouched by cleanup; the game wrote no save file during this test.
