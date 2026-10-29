# Final live test and stopping checkpoint — October 29, 2026

Stopped at the owner's request after completing the final 0.6.17 live attempt.
The candidate did not pass, and the proven 0.6.14 build is restored.

| Check | Result |
| --- | --- |
| Offline checks | 335 Lua scenarios, original scanner/logger preservation, pack round-trip, speech tracing, PowerShell 5.1 atomic writes, installer/tamper/uninstall/preservation checks passed |
| Launch | Steam → configured TW Mod Manager; exactly one valid active accessibility pack; DirectX 11 |
| Screen route | 22-control main menu → 17-entry Select Campaign → visually verified Select Lord |
| Named reader | 22 Next commands acknowledged successfully, including selected lord, race, faction, campaign/battle difficulty and introduction state |
| Final failure | Attempted entry 23, the first race attribute; raw Intrigue announcement appeared, then automation reported preserved logger line 327: attempt to index a number value |
| Discovery evidence | Four pages; 192 paths examined, 118 visible node rows, 25 captured entries, 13 queued paths left; zero recorded page read errors, incomplete capture |
| Full catalog, wrap, refresh, new F4 test | Not reached; no pass claimed |
| Native clicks | Exactly two, New Campaign and Continue; no campaign start, lord choice or settings change |
| Speech transport | 33 requests and 33 NVDA returns, all code 0; full audible completion not assessed |
| Final rollback | 0.6.14 installed; all 13 installed runtime payload hashes match its manifest |
| Final cleanup | Game and test companion closed; test lease/request files absent |

0.6.17 removed the new native field watchers entirely and formatted already
captured values only. The later failure shows that removing field watching
alone did not eliminate the problem. It does not prove a specific helper or
the preserved logger is the root cause. No further build/test iteration was
started after the owner requested this stopping point.

Current installed/runtime source/package version/generic pack: **0.6.14**.
Source and harness were restored; the standard harness returns to its prior
332-scenario state. Failed candidate code and its 335-scenario harness are
preserved at `work/0.6.17-candidate-source`. Candidate ZIP/checksum are under
`outputs/failed-candidates`; they are debugging artifacts, not accepted releases.
The separate read-only Lord fixture is not an activation template.

Evidence: `work/live-0.6.17-lord-discovery`, including `summary.json`, native and
speech logs, successful reader acknowledgements, route results and disabled
status. Final cleanup/hash verification: `work/final-stopping-checkpoint.json`.
Earlier failed candidates: `outputs/0.6.15-0.6.16-lord-reader-test.md`.

Resume point: isolate captured metadata and the race-attribute prefix helper
with bounded stage/type diagnostics, independently of native field watching.
Keep 0.6.14 as the rollback. A complete 34-entry native reader and fresh capture
must pass before promotion. Automatic refresh, injected keyboard delivery,
intro skipping and audible completion remain unresolved. Starting a campaign,
lord changes, gameplay and co-op remain blocked. Await the owner's next resume
request; no automatic continuation schedule was added.
