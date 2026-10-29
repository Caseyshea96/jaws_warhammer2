WARHAMMER II NVDA GRAPHICS ACTIVATION PREVIEW 0.5.2

This revision removes the intermediate native-reader return layer after
0.5.1 returned function values instead of UI properties. This is a candidate
scanner correction; it has not yet passed an in-game test.
The first retest must confirm real menu controls with F2/F3 before F4.

Experimental preview, not a playable accessibility release.
The game-side activation method is documented but has not been verified live
with this package. Frontend modal behavior and complete spoken feedback still
need validation. Do not use this preview to interact with an open modal dialog.

Close the game and companion. Use the installed pilot's Uninstall.cmd, then
extract this ZIP and run Install.cmd. The normal Steam game folder is detected.
Keep the existing Warhammer II Quiet Mode add-on enabled in NVDA.
Run Start Pilot.cmd and enable only jaws_access in the game's mod manager.

At the main menu:
1. F2 selects the next spoken control; F3 selects the previous one.
2. Find Graphics. Tap F4 once to hear the confirmation prompt.
3. Tap F4 again within four seconds to send the component activation.
4. Verify that the Graphics screen actually opens. Input sent is not proof.
5. Use the game's Escape key to return, then browse again with F2/F3.

Only the captured Graphics button at its verified path can activate. Changed,
hidden, inactive, or unreadable controls are rejected. All other menu controls,
campaign/battle actions, and shortcut dispatch remain blocked. Enter is not
bound. No screen-coordinate click or companion global hotkey code is included.

Speech tracing is enabled. speech-trace.jsonl records full UI text, UTC time,
request IDs, API return codes, and stop requests locally in
%LOCALAPPDATA%\JawsWarhammer2. It rotates after approximately 1 MB.
A successful API return does not prove audible speech completion.

Fallback: close game and companion, uninstall this preview, then reinstall
the unchanged 0.4.3-nvda-diagnostic ZIP. Never enable both packs together.
Saves and unrelated mods are not removed by the pilot uninstaller.
