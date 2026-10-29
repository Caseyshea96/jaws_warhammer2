# JAWS 2026 / Warhammer II interaction review

Reviewed 2026-10-25 against current 0.2.4 source, the user's Windows transcripts through 0.2.3, installed WH2 documentation/scripts, and the primary sources below. No Windows runtime was available to this review. No new runtime package was issued. The 0.2.4 native-tail-call change remains unverified.

## Conclusion and evidence boundary

The immediate failure is game-side UI extraction, not a demonstrated JAWS speech failure. F2, category switching, repeat/summary and F4 handlers produce specific messages in the transcripts. Those messages establish that those particular inputs reached Lua, the transport delivered output, and JAWS spoke it. They do not establish all shortcuts work, a click reached a valid control, or co-op compatibility.

A scan of one node with function/userdata results means traversal is failing at or near the root. The diagnostics retain only the first failure, which can be GetStateText on a non-text root, and hide the actual ChildCount result behind a fallback of zero. Therefore they do not identify the decisive failed method. The underlying native-call failure is still unknown. The protected-call and tail-call explanations offered during earlier patches were hypotheses, not findings. Repeated installer releases preceded adequate runtime instrumentation.

## Findings

### High: global companion keys conflict with JAWS use

`companion/Native.cs:13` registers Ctrl+Alt combinations system-wide for the lifetime of the companion. `companion/Companion.ps1:160` includes the arrow keys. JAWS uses Ctrl+Alt+arrows for table navigation. F3/Shift+F3 also have JAWS find roles in web contexts, relevant to the launcher but not proof they are intercepted inside the game. RegisterHotKey success is not proof a JAWS keyboard hook will pass an input. The game-foreground checks occur only after dispatch for mouse actions; they do not release reservations outside the game. Repeat/mute/stop are global too. Remapping and focus-scoped registration are required. Do not simply change the default to another untested chord.

### High: UI reading fails silently into empty lists

`mod/script/_lib/mod/jaws_access.lua:34` converts unexpected native results to defaults. ChildCount becomes zero and traversal stops. Some diagnostics capture irrelevant root properties first. Add per-method type/value/error records for root Id, ChildCount, Visible, and one child, independently of normal traversal and filtering. Log stages before calling native methods so a missing completion record is meaningful. Compare inline, non-tail adapter and protected adapter calls on the same root in the same session. Do not infer success from lack of exceptions. Do not remove all error protection from the gameplay mod.

### High: opaque address validation is ineffective for userdata

The generic reader only accepts strings/numbers for string-fallback fields, including Address. Installed WH2 docs define Address as an address, not a string. If the engine returns userdata, both saved and re-read addresses collapse to an empty string, so the identity comparison can pass when a component has been replaced. The fixture defines no Address method and consequently tests the same empty-string equality. Use a method-specific contract, preserve valid opaque identity before normalization, and add replaced-node tests with different addresses but identical path/text/state. Verify the actual address representation in the diagnostic run.

### High: frontend modal isolation is not established

Only PanelOpenedCampaign/PanelClosedCampaign events update the panel stack. A frontend dialog may leave background items in the generic tree, and no frontend adapter or verified modal detection exists. Double-confirmation does not establish that a target belongs to the active dialog. Establish main-menu and submenu scopes from real UI data before allowing arbitrary traversal clicks.

### Medium: double F4 is not a verified two-press confirmation

Pending activation is keyed to component and generation but has no timeout or key-up requirement. Repeated ShortcutTriggered events might consume both stages while a key is held. This is a risk to test, not an observed event. Mouse-driven changes to focus/dialogs can also leave pending state. Use observed key/event behavior to design distinct confirmation input, expiry and invalidation. Hold-F4 and remote-control repetition belong in acceptance testing.

### Medium: speech handling can drop or interrupt useful information

Every Speak calls SayString(text, true), requesting a flush. Read-Bridge retains only the last primary message per 100ms poll, discarding earlier errors/results along with navigation. It reads two possible files with separate states but no active-source arbitration, so the second source wins regardless of event time if both are active. Focused status textbox updates and console output add another path for JAWS to announce text. Separate replaceable focus messages from queued results/errors, select an active stream, and test interruption with held Ctrl modifiers. The API shape matches Tolk's published COM interface and actual speech works; this is a scheduling/design problem, not evidence that COM must be replaced.

### Medium: mouse commands are a separate, unverified input route

Pointer helpers use foreground process checks, client bounds and modifier-release delay, which are useful. But mouse_event has no inserted-event count, and the returned sentence only says the request was sent. Microsoft supersedes it with SendInput. Migration should check insertion count and account for integrity-level restrictions; neither API proves the game accepted a target. Test local keyboard before Zoom remote control, and test equal-elevation game/companion sessions. Do not advise elevating everything as a general remedy. Physical pointer clicks, Lua SimulateLClick and effect.trigger_shortcut must have separate acceptance results.

### Medium: misleading frontend Game actions

The frontend exposes next army/unit and halt actions even though these are not main-menu actions. The transcript's "Input sent" for next army is not evidence of main-menu interaction. Restrict actions to valid contexts and announce unsupported actions explicitly. GetStateText and GetTooltipText need real descendant/label inspection; a generic interactive predicate is insufficient to identify semantic buttons.

### Testing gap

Lua table mocks validate our logic but do not reproduce native userdata, engine lifetime, UI thread behavior or actual input routing. The synthetic host-pcall variant demonstrates robustness to a fabricated wrapper, not that WH2 uses such a wrapper. Lua bytecode confirms removal of tail calls, not that this fixes WH2. Installer tests prove file operations, not Windows JAWS integration. State-labelled fixtures, opaque address tests and native integration traces are required before interpreting passing tests as menu support.

## JAWS 2026-specific conclusions

Freedom Scientific lists JAWS 2026.2609.84 as the September build, matching the installer filename provided earlier. That does not prove the friend's installed build: collect Help/About build, desktop/laptop layout and application-specific scripts/settings. We found no authoritative evidence tying this native Lua result-type failure to a JAWS 2026 regression. The public JAWS What's New endpoint did not expose useful release text during review; do not claim an exhaustive release-note exclusion.

JAWS' ability to read the launcher or companion is independent of access to the rendered game UI. Speech output through COM does not create UI Automation controls, braille semantics or accessible focus inside the game. "Computer Braille" in the transcript does not establish mod braille output. The user's input path also includes Zoom remote control; distinguish local input from remote input when testing.

Pass Key Through (Insert+3 on desktop layout, Caps Lock+3 on laptop layout) is a one-key diagnostic for suspected interception. It cannot repair an already-executing Lua handler's bad native return values. Sleep Mode is documented for programs with competing speech, but don't enable it as a blanket fix: verify external COM speech behavior and preserve the user's ability to navigate the launcher/desktop. There is no evidence requiring a JAWS reinstall or downgrade.

## Next controlled test, before another compatibility release

1. Record exact JAWS/game/pack versions, active mods, keyboard layout, local versus remote input, and window mode. Use only the pilot for the baseline without changing saves.
2. Disable companion global key registration in a diagnostic variant. Keep COM speech and JSONL transport. Test F2 locally, then remotely; compare event counts, not only speech. Keep all raw records even when speech coalesces.
3. On one F2 event, record raw native root and child reads using inline, ordinary adapter and protected adapter paths. Record result types, numeric counts, stage completion and errors for each method separately. Limit nodes; perform no clicks. Use logs rather than speaking every property.
4. If the direct read works and an adapter fails, isolate that exact call shape. If all fail, inspect root lifetime/context, game build, other mods and API availability. If the root works but a child fails, isolate conversion and lifetime. Do not treat invalid values as genuine zero-child nodes in diagnostic output.
5. Once reads are valid, enumerate actual menu labels/IDs, identify active modal scope, and test one harmless menu/submenu/back sequence. Then validate deliberate two-stage activation and stale-target rejection.
6. Test keyboard conflicts with JAWS active, single-key passthrough when needed, and the companion closed outside the game. Introduce a game-specific configurable key profile only after this comparison.
7. Resume campaign/battle and co-op work after main-menu read/select/back succeeds. Recheck both native input routing and speech under those contexts.

## Sources

- Installed engine docs: local/inspection/text/frontend_uicomponent.txt (Address, ChildCount, Visible, IsInteractive, SimulateLClick); local/inspection/base/script/_lib/lib_core.lua (cached root initialization and get_ui_root); current mod/companion source and user transcripts.
- Freedom Scientific keyboard reference: https://www.freedomscientific.com/training/jaws/hotkeys/
- Freedom Scientific keystrokes/table navigation: https://support.freedomscientific.com/content/html/jawshq/JAWS-Keystrokes.html
- Freedom Scientific pass-through scripting: https://support.freedomscientific.com/Content/Documents/Other/ScriptManual/10-1_PassThroughScripts.htm
- Freedom Scientific downloads/build listing: https://support.freedomscientific.com/Downloads/JAWS
- Freedom Scientific Sleep Mode support (historical guidance, not a 2026 COM guarantee): https://support.freedomscientific.com/support/technicalsupport/bulletin/909
- Microsoft RegisterHotKey: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey
- Microsoft mouse_event: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mouse_event
- Tolk project's COM interface declaration (implementation source, not a JAWS 2026 vendor guarantee): https://github.com/dkager/tolk/blob/master/src/fsapi.h

## Development follow-up: identity and lifecycle

The unreleased playable source now accepts opaque userdata addresses, rejects missing identity during current-target validation, gates input on core UI readiness, and clears selection/pending actions/panels on core UI creation and destruction callbacks. Frontend Game actions now contains only Escape/back. The fixture now supplies opaque addresses and tests address replacement with unchanged labels, unavailable identity, and UI destruction between confirmation presses. These changes pass Lua fixtures but do not establish native address stability or frontend modal correctness.

The first 0.3.0 native diagnostic run proved that root Id and ChildCount work identically through inline, adapter, tail and nested protected calls, and that Address is opaque userdata. This disproves the protected-call and tail-call hypotheses. That diagnostic then failed in its own unprotected bounded-loop setup before the first child read, while F2 repeat consumed five captures. The 0.3.1 run successfully converted every direct root child and confirmed stable opaque addresses; its hover event yielded only the broad `main` container. The user rejected mouse-dependent testing. The 0.3.2 F2-only run completed 86 visible-tree nodes and exposed labeled menu-button wrappers and their `button_txt` children without errors. The 0.3.3 read-only browser stopped after the root ChildCount, before its first child lookup. The 0.3.4 browser classifies only exact IDs observed in 0.3.2, performs classification after child traversal, and isolates classification errors. The development scanner derives wrapper labels from descendants, excludes duplicate presentation nodes, and avoids the failing `math.*` bounds. Diagnostic mode no longer loads the native mouse/hotkey assembly.

## Development follow-up: scoped companion hotkeys

The 0.2.5-dev source now configures keys without reserving them, registers on game-foreground entry, and unregisters on exit. Native message dispatch also rechecks foreground and registration ownership. The existing 100ms polling timer introduces a short release delay; Windows/JAWS hook interactions are not verified. Failed registration is reported once per transition and retried on re-entry; failed release is retried while inactive, with repeated identical speech suppressed. Dispose releases keys and destroys the window. NoHotkeys diagnostic mode still reserves none. In-game JAWS chord conflicts and configurable remapping remain outstanding.

HotkeyPolicy.cs isolates registration lifetime behind native delegates. tests/hotkey_policy_tests.ps1 exercises focus transitions, registration conflict, failed release and retry, stale dispatch, polling idempotence and disposal. Native.cs plus the policy compile against .NET Framework 4.8/C#5. The 0.2.5-dev ZIP passes installation/rerun/removal checks including the added policy file. This package is for development validation; use the separate keyboard-only 0.3.4-diagnostic package before testing activation.

## Development follow-up: same-poll speech preservation

The development mod labels navigation as focus and dispatch acknowledgements as result. The companion preserves non-hover messages in a bounded batch and collapses only consecutive focus updates. Errors, confirmations (speech), and results no longer silently disappear merely because a later record arrived in the same poll. Overflow is spoken and logged; original records remain in the rotating bridge file. Protocol, ordering and bound tests pass. Speech completion across polling intervals and simultaneous-source arbitration remain unresolved, and native JAWS speech timing needs live testing. Use matching development mod/companion versions because earlier parsers do not accept focus/result kinds. The diagnostic package remains separate from the playable development ZIP.
