# Lord reader candidate tests — October 29, 2026

The live-verified **0.6.14** build is restored and installed. The new semantic
reader/refresh candidates did not pass live testing and are not promoted.

| Check | 0.6.15 | 0.6.16 |
| --- | --- | --- |
| Offline validation | 343 Lua scenarios; package, speech, atomic-write and installer checks passed | Same checks passed |
| Actual launch | Steam → TW Mod Manager, one valid active pack, DirectX 11 | Same |
| Guarded native route | 22-control main menu → 17-entry Select Campaign → actual Select Lord | Same |
| New reader | Failed during the first page; one native-visible row saved | First page examined 48 paths, with 39 visible rows and zero page read errors; six reader entries existed and Select Lord was announced, then failure |
| Native error | Preserved logger line 327: attempt to index a number value | Same reported location/message |
| Complete catalog / wrap / explicit refresh | Not reached | Not reached |
| Native clicks | Exactly two: New Campaign and Continue | Exactly two: New Campaign and Continue |
| Speech transport | 11 requests, 11 NVDA returns with code 0 | 11 requests, 11 NVDA returns with code 0 |

The actual screens were visually checked before native commands and again after
Continue. Intro skipping was not attempted. No campaign, lord selection or
settings change was sent. No Start Campaign input was sent. Candidate F4/live
refresh acceptance was not reached. Fixture refresh tests are not live proof.
NVDA return code 0 does not establish full audible speech.

0.6.15 added named selected lord/race/faction/difficulty/introduction fields,
effect labels and fresh selected-field checks. Its failure was not reproduced
by fixtures. 0.6.16 moved presentation after native traversal and restored the
live-proven 0.6.14 page body except captured ID/state metadata. A source comparison
confirmed that match. The later failure still prevents accepting the candidate;
the exact native compatibility mechanism remains unproven. Do not treat the
reported logger line as proof that the preserved logger caused the problem.

Both candidate sessions had their leases revoked and owned test processes
closed. Installed manifest and pack hash confirm restoration to 0.6.14. Lease
and request files are absent; no test game or owned companion remains running.
The source, packaging version and generic pack artifact also return to 0.6.14.
The restored pack SHA-256 is
`6f03365aa4f29611a706424864b2391d230d0f65acfd0260934dfcd373ce1f00`.
This rollback was verified by manifest/hash and known source comparison; it was
not relaunched in a third unchanged-build live pass.

Evidence in this workspace:

- `work/live-0.6.15-lord-discovery` and `work/live-0.6.16-lord-discovery`: fresh native/speech logs, route acknowledgements and owned game identities.
- `work/lord-candidate-failure-summary.json`: per-process speech and native counts.
- `work/0.6.16-candidate-source`: exact candidate runtime, packaging source and 343-scenario harness; preserve this before further isolation.
- `work/graphics_preview_0615_failed.lua`: first failed runtime source.
- `work/rollback-0614-verified.json`: final installed/version/hash/process checks.
- `outputs/failed-candidates`: candidate ZIPs and checksums, retained solely for debugging.
- `outputs/0.6.14-lord-setup-test.md`: earlier full live acceptance of the restored build.

Next: isolate the added field watcher and presentation helpers independently,
using bounded native-stage/type diagnostics. Preserve the original traversal,
logger, exact activation gates and known working package. Do not repeat the old
Timers/get_tm or epoch precision investigation. Full native catalog, wrap and
refresh must pass before promotion; physical injected-key delivery, intro
skipping, audible completion and gameplay remain separate gates.
