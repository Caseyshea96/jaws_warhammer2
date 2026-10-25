WARHAMMER II READ-ONLY NATIVE UI DIAGNOSTIC 0.3.0

This replaces the pilot for testing; it is not a playable accessibility release.
1. Close game and companion. Uninstall the previous pilot using its package.
2. Extract this ZIP and run Install.cmd.
3. Start JAWS, then Start Pilot.cmd from THIS package or the installed shortcut.
   This launcher disables companion global hotkeys; no JAWS settings change.
4. Enable jaws_access; disable jaws_probe and other pilot copies.
5. At the main menu press F2 once, then move the mouse over a menu button.
   No click is needed. Each completed capture should be announced.
6. Use Open diagnostic folder. Send native-ui-diagnostic.log and bridge.jsonl.
   If absent, check beside Warhammer2.exe for the log and jaws_access.jsonl.
   Include exact JAWS/game versions, active mods, and local/remote input details.

The pack retains jaws_access.pack as its name for installer compatibility.
Its startup message identifies the diagnostic. No activation or game-command
handlers are included. Other pilot F-key controls are absent in this build.
The companion retains its buttons; keyboard mouse hotkeys are disabled.

Each capture logs raw types/errors for root, at most eight children and,
when hovered, an event component. Six captures maximum per session. New
sessions replace the log, so copy it before restarting. It may contain UI
text and opaque native addresses. Inline means no reader adapter; all test
calls remain protected. Tail and non-tail variants are compared.

Local fixture tests do not establish game runtime compatibility.
Uninstall this package before restoring the playable pilot.
