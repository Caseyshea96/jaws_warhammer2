# Autonomous automation session — 2026-10-28

The owner authorized build/deploy/launch/test iteration and then prioritized
automation over feature expansion. Use Steam's existing TW Mod Manager default,
one valid accessibility pack and DirectX 11. Do not use Skip Launcher. Existing
Missing references were left inactive; only the newly installed pack was enabled.

## Evidence and corrections

- 0.6.1 user run: all 17 campaign-reader entry indexes appear in speech trace;
  New Campaign has an observed native result; Escape returned to 22 main-menu
  entries. Continue never dispatched. Its expected/actual tooltip mismatch is
  identical after the plain logger flattens CR/LF. Named campaign fields match
  the prior flattened capture. Main return has 87 nodes, with hidden Tooltip at
  child4 and browser at child5.
- 0.6.2: preserves raw confirmation strings while comparing campaign text in
  the diagnostic representation; supports that observed main return. 276 Lua
  scenarios passed. Actual Steam/TWMM launch reached the main menu with correct
  version and NVDA Controller Client code 0. Three injected F2 attempts produced
  zero native shortcut events after focus recovery and a confirmed game mouse
  response. Two injected Escapes did not visibly skip the intro. Alt+F4 closed
  the idle game. The input-delivery cause remains unproven.
- 0.6.3: introduced a temporary opt-in, data-only native frontend test channel.
  304 scenarios and client fixture checks passed. The shipped installer omitted
  Automation.ps1 despite its presence in the ZIP. New payload checks reproduce
  the omission. No live automation action was counted as passing.
- 0.6.4: fixes install/remove allowlists and tests every installed runtime hash,
  helper tamper rejection and changed-helper preservation. Installed helper
  verified; launch/mod startup and speech succeeded, but no complete endpoint
  status appeared. The lease was revoked before shutdown.
- 0.6.5: removed an unnecessary file-method type check and added lease-gate
  diagnostics. Startup still stopped before those checks; native log contained
  only header/runtime markers. Lease revoked and game closed before updating.
- 0.6.6: derives the channel directory from the successfully opened native log,
  removing a second environment lookup. 305 Lua scenarios and installer checks
  passed, including unavailable-later-environment regression. Live startup
  then failed inside the original logger while reporting a lease failure.
- 0.6.7: flattened protected native-read closures; 306 fixtures passed. The
  startup failure persisted. Do not describe the closure hypothesis as proven.
- 0.6.8: isolated optional startup with xpcall so the keyboard reader and NVDA
  startup survive an automation error. Trace points to logging a rejected
  lease. No endpoint status or acknowledged action was observed.
- No-Discord input test, October 28 around 9:13–9:17 PM Eastern: owner closed
  Discord, absence verified in the real desktop process list. Steam/TWMM/DX11
  launch reached main menu with 0.6.8 startup speech accepted by NVDA. Space
  and Return did not skip the intro; F2 and F3 produced no ShortcutTriggered
  log entries, including after a neutral client-area focus click. Alternate
  CUA interface reports held key presses unavailable on Windows. This is an
  input-delivery blocker; removing Discord did not resolve it. Evidence:
  chat workspace work/live-no-discord-input/. Game closed using Alt+F4.
- 0.6.9: adds bounded transport-only file-read metadata and a simple string
  logger, preserving the original UI logger. 306 fixtures, pack round-trip,
  and shipped-ZIP installation/uninstall preservation checks passed. Installed
  with backup work/automation-probe-preinstall-377ab7f5db864d55b2b15444f19acdd1.
  Live mod startup succeeds, with userdata file handle, successful read, string
  data, and all 54 expected lease bytes. The parser then rejects the complete
  lease as read-or-format; no endpoint is created. This localizes the next
  investigation to framing/parsing. Evidence: work/live-0.6.9-parser-failure/.
  Lease revoked; idle game closed through Alt+F4.
- 0.6.10: replaces transport framing with direct bounded byte parsing,
  separates file read from parsing, validates digits/owner bytes explicitly,
  and reports specific framing failure reasons. Adds LF/CRLF acceptance and
  malformed/incomplete framing checks; 315 Lua scenarios, build/round-trip and
  shipped installer tests passed. Live lease parsing now passes. Initialization
  reaches the next gate, but get_tm does not yield an available frontend
  callback. Evidence: work/live-0.6.10-timer-unavailable/. Lease was revoked.
- 0.6.11: adds the shipped timer_manager:new() singleton constructor fallback
  and records lookup/constructor types. 316 Lua scenarios, pack round-trip,
  speech tracing and installer checks passed. Deployment before midnight was
  not executed: automatic approval review hit a usage limit (not a safety
  finding). At the October 29 12:44 AM continuation, approval and desktop access
  worked again. Installed with backup
  work/automation-probe-preinstall-a146aa3456544f7ba88732d73ed9f4b6; owned companion
  PID 3928. Live lookup and constructor both return boolean false; Timers is
  nil. This is a concrete runtime incompatibility in the shipped timer manager,
  not a missing lease. Evidence: work/live-0.6.11-missing-native-timers/.
  Lease revoked and idle game closed before the next correction.
- 0.6.12 source replaces the unusable model timer manager with frontend
  real_timer single shots plus RealTimeTrigger. It rearms only while active,
  unregisters its own timer/listener on revocation, and disables on registration
  or rearm failure without replaying consumed native input. Source evidence:
  the original WH2 mod author's published frontend timer example, saved in
  work/frontend-real-timer-example.lua. 319 Lua scenarios, pack round-trip,
  speech and installer checks passed. Installed with backup
  work/automation-probe-preinstall-b03498a1bc184ca5a4cd4c60d66dfb92; companion
  PID 17200. At the actual main menu the endpoint became ready, and the first
  Next request completed: screen main, 22 controls, New Campaign selected.
  The second (Previous) request was not written: Windows PowerShell 5.1 passed
  a null backup argument to File.Replace as an invalid empty path. The script
  stopped; no activation was requested. Evidence: work/live-0.6.12-native-channel/.
  The channel was revoked and the idle game closed.
- Another live finding: exact lease Unix expiry 1793251316 was reported by Lua
  as 1793251328. This matches single-float rounding at modern epoch magnitudes.
  Do not test activation using this rounded clock. Source 0.6.13 keeps epoch
  values as decimal text and derives small exact confirmation seconds from
  os.date UTC calendar fields. It tests five-second rejection despite an
  unchanged rounded os.time, exact modern lease/deadline text, and UTC midnight.
  It also uses NullString.Value for File.Replace. The atomic replacement test
  passes on the actual Windows PowerShell 5.1 host. 322 Lua scenarios pass.
  Desktop build/round-trip, atomic replacement on PowerShell 5.1 and shipped
  installer checks pass. Installed with backup
  work/automation-probe-preinstall-ece3b0c162d74c36a8cd128479eeee13; companion
  PID 23072. Actual live checks now pass: all 22 main-menu controls and both
  wrap directions; exact lease/deadline text; confirmation rejected after a
  five-second wait (nine seconds end-to-end including client startup) with zero
  clicks; New Campaign opened Select Campaign with native observed_result;
  all 17 campaign entries and wrap; Continue opened the actual Select Lord
  screen. The last campaign-reader script stopped on its overly strict label
  expectation (actual label is 'Continue, button'); the saved acknowledgements
  prove all 17 unique entries. Continue was tested only after inspecting the
  correct selected key/label. Exactly two positive native dispatches occurred.
  All 54 speech requests in companion PID 23072 returned NVDA code 0; full
  audible completion was not assessed during rapid automated navigation.
  The sandbox
  denied the atomic test's temporary file move; this is an execution-context
  restriction, not a failing desktop atomic replacement.

## Current stop point — October 29, after the 5:45 AM continuation

### 5:45 AM continuation — 0.6.14 discovery/browser passed

Source/build 0.6.14 adds a separate bounded breadth-first read-only Lord setup
discovery path. It reads at most 48 queued paths per request from fresh roots,
logs compact JSONL independently of the unchanged legacy scanner/logger, and
provides captured text through F2/F3. The opt-in client gains Discover; no new
activation target is allowed. F4 is explicitly blocked in discovery. Limits,
malformed returns, hidden ancestors and UI recreation have fixture coverage.
332 Lua scenarios, speech trace, atomic writes on PowerShell 5.1, pack
round-trip and shipped installer/preservation checks pass. A test expectation
initially counted unrelated root siblings instead of the scoped panel; the
corrected synthetic test verifies all 412 scoped nodes in a 417-node tree.

0.6.14 is installed with backup
work/automation-probe-preinstall-a384c9c310ca4c38b0299dd3d9312638; owned companion
PID 6900 for the first run. Live native New Campaign/Continue reached Select
Lord. Five bounded pages examined 205 paths, captured 131 visible nodes and
34 text entries. The visible queue completed without limits/errors in 44,160
bytes. All 34 reader entries matched the raw capture; both wrap directions
passed. F4 on captured Start Campaign text was blocked with no additional
clicks, visually staying on Select Lord. Exactly two positive native clicks
occurred (New Campaign, Continue). Legacy log: 1,478,391 bytes, six complete
captures, zero native errors/bounding. NVDA: 52 requests/returns, all code 0;
audible completion was not assessed. Evidence: work/live-0.6.14-lord-discovery/.

First-run lease was revoked and status confirmed disabled. Alt+F4 closed its
window but left process 6040 running with no window after a bounded wait. Only
that verified Warhammer2 executable/PID was terminated; owned companion 6900
was stopped. NVDA was left untouched. Graceful shutdown remains unresolved.

The final unchanged-build pass also passed: the normal Next/F2 handler fetched
all five pages and traversed all 34 entries with both wrap directions and zero
Discover requests. Evidence: work/live-0.6.14-f2-paging/. It had 46 NVDA
requests/returns, all code 0; exactly two positive menu clicks and no native
read errors. The added fixture proves the physical shortcut callback finishes
pages with no automation lease, including pages with no new text. The live
driver still uses structured native requests; injected keys remain unresolved.
No source/payload change was made after the validated ZIP; the extra regression
changes only the test harness.

Cleanup is complete. Lease/request removed; owned game process 22644 and
companion 14516 stopped. In final cleanup, captures for both Steam and game
timed out and the native revocation acknowledgement remained stale; do not
claim a native disabled acknowledgement for this second run. Process identity
was checked using executable path plus creation-time ticks (PowerShell parses
the recorded ISO date into DateTime). The verified process was stopped after
the closure wait. Native revocation/foreground/shutdown reliability remains a
separate gate. No campaign was started. NVDA and unrelated apps were untouched.

Version 0.6.14 remains installed. ZIP SHA-256:
a584a859f32cb569d5dce6334ad112b46c7ed94079036031d2931f21e475a86f.
Package and report are in outputs/warhammer2-windows-0.6.14-nvda-automation-preview.zip
and outputs/0.6.14-lord-setup-test.md. The completed one-time continuations are
removed; no new recurrence was requested.

The browser is a captured snapshot. It does not automatically refresh after
manual in-panel lord/settings changes. Next improve field grouping (selected
lord/race/faction, effects and named difficulty values) and refresh semantics
before adding any selection activation. All new Lord setup actions stay read
only. The prior 0.6.13 checkpoint below is historical.

### Prior 0.6.13 checkpoint (historical)

Version 0.6.13 is installed; its pack hash matches the manifest. Game closed,
owned test companion PID 23072 stopped, test lease/request removed, native
status confirmed disabled. NVDA and unrelated apps were left untouched.
The completed 12:44 AM one-off is removed. The 5:45 AM one-off remains active
and was updated to resume from this verified checkpoint.

Evidence: chat workspace work/live-0.6.13-native-channel/ (menu/campaign steps,
expiry test, native/bridge/speech logs, captures.json, summary.json, receipts,
activation responses and disabled status). User-facing package and test report
are in outputs/warhammer2-windows-0.6.13-nvda-automation-preview.zip and
outputs/0.6.13-automation-test.md. ZIP SHA-256:
45c7f8ba637ca031bd87ba4faba99981be9fe994d4cd35e26dd6eebb8d7c9f80.

The Select Lord result was visually verified (Tyrion, High Elves, Eataine), but
its native classifier is still unknown. The final scan reported 200 nodes at
the existing traversal limit. The 2 MiB diagnostic budget was also exhausted:
only 107 rows of that final capture are logged; no capture.COMPLETE appears.
This is explicitly partial discovery data, never an activation template.
All eight preceding main/campaign captures completed (86 or 167 nodes).
Starting a campaign and all new lord-screen actions remain blocked.

Desktop logs/processes must be read outside the execution sandbox: sandbox
reads can show stale file snapshots and omit the real game process. Use the
authorized desktop execution context and verify timestamps/version each run.

The owner scheduled one-time continuations in this chat for October 29 at
12:44 AM and 5:45 AM America/New_York. Both heartbeat schedules are saved with
COUNT=1. Do not duplicate them. Inspect the current state before resuming.

The Computer Use tool once reported a physical-Escape stop. The owner explicitly
said they did not press Escape. Do not attribute that stop to the owner; the
cause is unverified. Work resumed under the existing authorization. Avoid
injecting Escape during this investigation. No unsupported stop-shortcut
remapping, Windows input hook, memory offsets or custom pointer injection was used.

## Test channel interpretation

The opt-in lease expires in at most 30 minutes. Requests bind owner, game session,
sequence, generation, revision, selected key and five-second expiry. The shipped
frontend timer callback runs the same navigation/activation handlers used by real
shortcuts. No fake ShortcutTriggered event is emitted. Source is recorded as
`automation` or `keyboard`; this route does not prove injected keyboard delivery.

Callbacks catch errors and rearm single shots only while active. Sequences
are consumed before action. Duplicate/uncertain inputs
are not retried. Native identities, exact observed layouts, raw fingerprints,
visible ancestors, active target and double confirmation remain enforced.
Keyboard and driver confirmations cannot be mixed. Unknown setup screens and
Start Campaign remain blocked. The normal read-only diagnostic is retained.

See FRONTEND_AUTOMATION.md and installed Automation.ps1. Read status before
issuing commands. Observe the actual main menu first; core UI readiness alone
does not prove the opening video ended. Do not claim success from build,
acknowledgement, native returned click or speech API acceptance alone.

## Remaining session work

1. Group and label the captured Lord setup fields more clearly: selected lord,
   race, faction, effects and named campaign/battle difficulty values.
2. Add reliable snapshot refresh for manual selection/settings changes;
   preserve the proven scanner and keep Start Campaign/lord changes blocked.
3. Reuse the now-proven native channel to test actual results. Do not repeat
   transport repairs or full regression runs without a new change/failure.
4. Keep injected keyboard delivery, intro skipping, Mod Manager accessibility,
   full audible speech, return/lifecycle, gameplay and co-op as separate gates.
5. Revoke the lease and close owned test processes after every session.

## October 29 follow-up: named Lord reader investigation

0.6.15 passed 343 fixtures and package/installer checks but failed the first live
Lord Next request. Only the scoped panel's first node was logged, then the
automation trace reported graphics_preview.lua line 327 (the preserved logger):
`attempt to index a number value`. It is not a live reader pass. The exact
native failure mechanism is unproven. The lease was disabled and owned game/
companion stopped; no campaign was started. Failed evidence is in workspace
work/live-0.6.15-lord-discovery and the candidate ZIP is retained.

0.6.16 isolates semantic presentation after native page traversal and restores
the live-proven 0.6.14 page body except captured ID/state metadata. Watchers are
separate from the original context/page function. All 343 scenarios, package
round-trip, speech, atomic-write and installer checks pass. It is installed;
second live validation is in progress. Do not treat this candidate as passed
until fresh results are recorded. Current owned process records are workspace
work/live-0.6.16-lord-discovery/owned-game.json and work/owned-companion-0616.json.

## Final follow-up checkpoint: rollback restored

Both named reader candidates failed live. 0.6.16 completed its first 48-path
page (39 visible nodes, zero native read errors), assembled six entries and
announced Select Lord, then reported the same preserved-logger line 327 error.
No complete catalog, wrap or refresh pass is claimed. The exact cause remains
unproven. See LORD_READER_CANDIDATE_TEST.md for evidence and interpretation.

**Installed/runtime source/package version/generic pack are restored to 0.6.14.**
Manifest and pack hash match. Test leases/requests are absent, owned game and
companions are closed. Do not deploy 0.6.15 or 0.6.16 as accepted builds. Their
sources, 343-scenario harness and ZIPs remain in workspace work/0.6.16-candidate-source,
work/graphics_preview_0615_failed.lua and outputs/failed-candidates. The normal
source harness is restored to its prior 332-scenario state. The new observed
Lord fixture remains read-only, never an activation template.

Next isolate field watching separately from pure presentation with bounded
native stage/type diagnostics. Preserve the proven 0.6.14 reader and activation
gates. Neither native automation nor these speech returns prove desktop-injected
keys, intro skipping or full audible completion. Both one-time continuation
schedules already completed and were removed earlier; do not recreate them.

## Narrow isolation candidate 0.6.17 — live pass pending

After verifying the rollback, development continued with a separate captured-
data presentation candidate. 0.6.17 removes all new native field watchers and
post-page reconstruction. It labels the existing 34 captured entries at speech
time using exact captured keys/IDs and retained state. No string.match is used.
Discover after a complete capture explicitly invalidates and rereads the scope.
Automatic freshness after manual changes is intentionally deferred.

The original 332 scenarios plus three captured-label/explicit-refresh/host-
library cases pass (335 total), along with required package/installer checks.
It is installed for a controlled live isolation pass. Current owned companion
record: work/owned-companion-0617.json; test evidence work/live-0.6.17-lord-discovery.
Do not infer a live pass until final results are appended.

## Final owner-requested stopping checkpoint (after 0.6.17)

The owner said: "Run this test and find a stopping point." The final 0.6.17
attempt reached actual Select Lord, acknowledged 22 reader Next commands and
then failed at the first race attribute (attempted entry 23). Four pages had
examined 192 paths / 118 visible rows, with 25 captured entries and 13 queued
paths left. Same reported logger line 327 error; exact cause remains unproven.
No complete catalog, wrap, refresh or new F4 acceptance pass is claimed. Removing
native field watchers alone did not resolve it. See FINAL_LORD_READER_TEST.md.

**STOPPED. 0.6.14 is restored in the installation, source, packaging version and
generic pack.** All 13 installed runtime hashes match. Game/test companion are
closed and lease/request absent (workspace work/final-stopping-checkpoint.json).
Candidate 0.6.17 source/335-scenario harness are in work/0.6.17-candidate-source;
ZIPs under outputs/failed-candidates. Standard source harness is back to 332.
No new automatic continuation was scheduled. Await the owner's resume request.

Next isolate captured metadata and race-attribute prefix formatting with bounded
native stage/type diagnostics; do not assume field watchers or the original
logger caused the issue. Preserve 0.6.14, saves and activation gates. Do not
repeat old real_timer/epoch fixes or claim injected keys/intro skipping passed.

## 0.6.18 — Lord reader passed; string.find root cause confirmed (October 29)

0.6.18 passed the full live Lord reader test (34 labelled entries, paging,
wrap, explicit refresh, Start Campaign blocked, exactly two native clicks,
graceful shutdown). A separate probe launch confirmed that WH2's plain
`string.find` returns nil for a matching prefix and then makes `string.sub`
return numbers — the cause of every 0.6.15–0.6.17 failure. Never call
`string.find` in the runtime. 0.6.18 is installed and is the accepted build.
Details: LORD_READER_0_6_18_TEST.md. Live scripts: tools/live/.

## 0.6.21 — automatic Lord setup refresh (October 29)

Watched named fields restart discovery after a manual change ("Lord setup
changed."), verified live by switching Tyrion → Teclis → Tyrion with test mouse
clicks. 0.6.19 exposed that any mouse selection disabled the reader (hidden
`tooltip_campaign_select_lord` root layer); 0.6.20 logged the reason; 0.6.21
accepts tooltip layers. 0.6.21 is installed and accepted. Details:
LORD_REFRESH_0_6_21_TEST.md.

## 0.6.23 — keyboard lord selection (October 29)

Owner unblocked lord selection (Start Campaign stays blocked). Lord portraits
are "Lord choice" entries; a double-confirmed F4 sends one click after a full
freshness/identity check, and the next browse confirms the result in speech.
Live: Teclis and Tyrion selected and confirmed, re-select refused, incomplete
capture refused. 0.6.23 is installed and accepted. Details:
LORD_SELECT_0_6_23_TEST.md.
