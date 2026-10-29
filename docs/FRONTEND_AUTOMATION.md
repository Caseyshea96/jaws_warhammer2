# Opt-in frontend automation

This development channel avoids desktop key injection when testing native UI
navigation and activation. It does **not** verify physical or injected F2/F3/F4
delivery. Keyboard events and automation requests are logged separately.

The channel is disabled without `automation-enabled.tsv` in the pilot's local
data folder. Enable it with the game closed using the installed `Automation.ps1
-Action Enable -LeaseSeconds 1800`, then launch through Steam and TW Mod Manager.
Keep exactly one valid accessibility pack enabled and DirectX 11 selected.
Observe the main menu before issuing navigation requests; UI readiness alone
does not prove that an introductory movie has finished.

`Automation.ps1 -Action Status` reads the endpoint. `Next` and `Previous` call the
same navigation handler as the corresponding physical shortcuts. `Activate`
requires an explicit matching `-ExpectedSelectedKey`. `-DoubleConfirm` sends two
individually validated requests only if the first arms the expected target.
It does not bypass native confirmation checks. It never resends a request after
a timeout, failed acknowledgement or uncertain native input.

The frontend uses `real_timer.register_singleshot(name,250)` with a named
`RealTimeTrigger` listener. The event callback rearms one shot only while the
channel and its lease remain active. Revocation removes this listener and
unregisters only this channel's timer. Registration/rearm failures disable the
channel; requests consumed before native input cannot be retried by a timer.
No received text is executed or resolved as a function.

The shipped `lib_timer_manager.lua` documents frontend support but requires a
`Timers` global. The actual WH2 frontend has `Timers == nil`, and both `get_tm()`
and `timer_manager:new()` return false (0.6.11 live logs). It cannot schedule
this channel. The replacement is based on the original WH2 mod author's
[frontend timer example](https://gist.github.com/Shazbot/edb8a3af536e35c030c1c29f46d5b800),
which registers a single shot and listens for `RealTimeTrigger`. The installed
game's `script/events.lua` also contains that event. Code is inspected as API
evidence, not executed from the external example.

## Wire formats

UTF-8 without BOM, one tab-delimited line ending in LF. File sizes are bounded.
The lease is `WH2LEASE1`, 32 lowercase hex owner nonce, and Unix expiry, separated
by tabs. Maximum lease horizon is 1800 seconds. The nonce is a local opt-in token,
not a security boundary against other code running as the same Windows user.

Epoch fields are decimal text in Lua. Live WH2 rounded a contemporary numeric
Unix timestamp by 12 seconds, so numeric epoch arithmetic cannot enforce a
four-second confirmation. The game reads UTC calendar text without passing a
rounded timestamp to os.date, uses an exact day-relative confirmation clock,
and constructs/computes epoch text digit by digit. Status still publishes the
pending deadline as exact Unix text for the PowerShell client. Clock reversal,
invalid calendar values, precision exhaustion, stale requests and expiry fail
closed. The client uses NullString.Value for atomic replacement on Windows
PowerShell 5.1; an ordinary null argument produced an invalid backup path.

The request file has nine fields:

| Field | Meaning |
| --- | --- |
| 1 | `WH2REQ1` |
| 2 | Lease owner nonce |
| 3 | Exact game session |
| 4 | Next monotonic sequence |
| 5 | Expected UI generation |
| 6 | Expected interaction revision |
| 7 | `next`, `previous`, `activate`, or read-only `discover` |
| 8 | Exact current selected key, or `-` |
| 9 | Unix expiry, no more than five seconds ahead |

The status has 16 fields: `WH2STATUS1`, build version, game session, generation,
revision, consumed sequence, result, screen kind, selected key, readable label,
control count, pending target key, confirmation deadline, UI-ready flag, enabled
flag and lease expiry. Flags are `0` or `1`. Acknowledgements report consumption
and handler outcome. `input-sent` is not observed-result confirmation; inspect
the next native screen and `activation.observed_result` diagnostics.

The client publishes requests atomically and serializes clients with a mutex.
Duplicates and earlier sequences cannot repeat input. Other owners/sessions and
out-of-order or malformed data cannot act. Owned stale requests are consumed and
rejected. Physical input, lifecycle changes and UI validation can cancel pending
confirmation. A confirmation cannot be completed by a different input source.
The existing root, path, visibility, active state, identity, observed-layout and
raw-text fingerprint checks remain mandatory, with one native click call site.

`Automation.ps1 -Action Disable` removes only the lease and request. Keep logs
and status as evidence. The native channel revokes its callback on its next tick.
Unknown setup screens, Start Campaign and campaign/battle gameplay stay blocked.

## Read-only lord discovery (0.6.14)

At the observed `sp_grand_campaign` frontend shell, `-Action Discover` reads
one breadth-first page of at most 48 queued index paths. It re-resolves paths
from a fresh root with visible ancestors. The separate
`native-ui-lord-discovery.jsonl` records compact node rows and explicit page
completion/limit metadata. The existing diagnostic traversal/logger remain
unchanged. Bounds are 1,536 examined paths, depth 16, 100 children per node,
2,048 queued paths, 512 spoken entries, 1,000 bytes per text field and 2 MiB of
discovery output. Truncation, malformed native reads and exhausted budgets are
explicitly limited; they cannot produce an activation template.

Results are `discovery-page`, `discovery-complete` or `discovery-limited`.
The first two are accepted client acknowledgements; limited/error results
stop an automated pass. Completion means the bounded visible-panel queue was
exhausted without a recorded limit/error, not an atomic snapshot of the game.

F2/F3 browse captured read-only lord setup text. F2 gathers another bounded
page when the end of the captured entries is reached. UI recreation starts a
new discovery run; returning to a supported main/campaign screen restores the
existing browser. All discovery keys use a separate namespace. F4 is blocked
throughout discovery, including on captured Start Campaign text. No new native
activation target or shortcut injection is introduced.

## Test interpretation

Report native navigation/activation and physical keyboard delivery separately.
Neither a package build, a status acknowledgement nor NVDA Controller Client
code 0 proves a completed in-game transition or full audible speech. The initial
0.6.3 installer omitted the helper; 0.6.4 adds it to the verified install/remove
allowlists and checks all installed runtime payload hashes in regression tests.

## Named Lord fields (promoted in 0.6.18 as captured-data labels)

0.6.18 ships the captured-data labels and explicit Discover refresh (no native
field watchers). The 0.6.15–0.6.16 watcher design below was never promoted; its
failures came from `string.find` (see LORD_READER_0_6_18_TEST.md).

The read-only browser labels the selected lord, race, faction, campaign and battle
difficulty, campaign introduction state, race attributes and individual faction/
lord effects. These descriptions use observed field paths and ancestor IDs;
they are never activation templates. Unknown fields remain captured raw text.

Each browse/discovery request freshly checks the six selected setup fields,
their visible ancestors and leaf identities. A change, missing field, hidden
ancestor or native read failure invalidates the previous snapshot, even when
the root/panel identities stay unchanged. A second check after each page
discards entries if those selected values changed during the page. This is a
bounded consistency check, not an atomic transaction over the whole UI.

After discovery completes, `-Action Discover` explicitly starts a fresh capture
for other text changes that do not affect the six watched fields. No background
full-tree polling or new physical shortcut is added. Lord selection, settings
changes and Start Campaign remain blocked. Fixture selection changes are not
live proof of manual-change refresh; record these separately in test reports.

These candidates failed live validation and were rolled back. The following
field/refresh behavior remains a proposal tested by fixtures, not installed
functionality. See LORD_READER_CANDIDATE_TEST.md; 0.6.14 is installed.

The subsequent captured-data-only 0.6.17 candidate also failed live at the
first race attribute and was rolled back. FINAL_LORD_READER_TEST.md records
the owner-requested stopping point. 0.6.14 remains installed.

## Automatic freshness and tooltip layers (0.6.21)

Each F2/F3 on the Lord setup browser re-reads the watched named fields
(selected lord, race, faction, campaign/battle difficulty) by their captured
index paths. A changed, missing or unreadable field logs `{"kind":"stale"}`,
restarts discovery and announces from entry 1 with "Lord setup changed."
Other captured text still needs an explicit `-Action Discover` to refresh.
The Lord context accepts root tooltip layers (`Tooltip`, `tooltip_*`) shown or
hidden; the `browser` layer must be hidden; any other root layer rejects the
context and logs `lord.context_reject` with the reason.

## Lord selection (0.6.23)

Lord-choice entries (portraits) are the only actionable Lord setup entries.
F4 twice within four seconds, from a complete and still-current capture, sends
one click through the shared single call site; everything else on Lord setup,
including Start Campaign, answers "read only". The automation client needs
`-ExpectedSelectedKey <lord choice key> -DoubleConfirm`. The next capture logs
`activation.observed_result lord-match:<name>` or `lord-mismatch:<name>`.

## Companion key channel (0.6.27)

Production input path, separate from the lease-gated automation channel: the
mod writes `reader-state.tsv` (`WH2READER1 session generation frontend screen`)
every second and polls `keys.tsv` (`WH2KEYS1 owner session generation`, then
`seq action` lines) every 100 ms. Actions: next, previous, first, last,
activate, letter:a–z. Same handlers as F2/F3/F4. See STANDARD_KEYS_0_6_27.md.
