WARHAMMER II NVDA READ-ONLY KEYBOARD BROWSER 0.4.3

This replaces the JAWS diagnostic for testing; it is not a playable accessibility release.
1. Close the game and old companion. Uninstall the previous pilot using its package.
2. Extract this ZIP and run Install.cmd. The installer checks the normal Steam
   folder automatically and saves it for every later launch.
3. Start NVDA. In the installed App folder, press Enter on
   warhammer2-quiet-mode-0.1.0.nvda-addon, approve installation, and restart
   NVDA. This add-on enables sleep mode only in Warhammer2.exe and is separately
   removable in NVDA Add-on Manager.
4. Run Start Pilot.cmd from THIS package or use the installed Warhammer NVDA
   Pilot shortcut. Choose Test NVDA / reconnect.
   This launcher disables companion global hotkeys and makes no NVDA setting changes.
5. Enable jaws_access; disable jaws_probe and every other pilot copy.
6. At the main menu tap F2 to hear the first control. Tap F2 for the next
   control or F3 for the previous control. No mouse, click, activation, or
   other game command is used. F4 is not handled by this diagnostic.
7. Leave the game focused for ten minutes, then use Open diagnostic folder.
   Send native-ui-diagnostic.log, bridge.jsonl, and the NVDA log.
   If absent, check beside Warhammer2.exe for the log and jaws_access.jsonl.
   Include exact NVDA/game versions, active mods, and local/remote input details.

The pack retains jaws_access.pack and the legacy JawsWarhammer2 diagnostic folder
for upgrade compatibility. The companion uses the official NVDA 2026.2 64-bit
Controller Client under the included LGPL 2.1 license. No NVDA add-on is installed.

The first F2 logs a bounded tree of visible descendants: at most 200 nodes,
20 levels, and 100 children per node. It then speaks the first known button;
F2/F3 browse the detected button wrappers using their visible child labels.
New sessions replace the log, so copy it before restarting. It may contain UI
text and opaque native addresses. All game API calls remain protected.

This build preserves the traversal/classification logic proven by the complete
0.3.4 JAWS capture. The diagnostic manifest forces NVDA/read-only mode even
when Companion.ps1 is invoked directly, and the package contains no native
mouse or global-hotkey assembly. The game does not launch until NVDA connects.
Local fixture tests do not establish game or NVDA runtime
compatibility. Uninstall this package before restoring a different pilot.
Removing the pilot does not silently remove an NVDA add-on. Remove Warhammer II
Quiet Mode separately through NVDA Add-on Manager and restart NVDA.
