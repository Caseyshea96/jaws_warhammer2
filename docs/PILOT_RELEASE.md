# Pilot 0.2.4: native UI call frames

The 0.2.3 transcript still reports one scanned node, with IsInteractive returning a function and GetStateText returning userdata. Explicit method names did not fix it. All native-reader adapters previously used `return obj:Method()`, which permits Lua tail-call optimization. They now assign the native result to a local before returning, preserving the adapter frame. Native binding sensitivity to tail calls is a hypothesis, not yet established by a live comparison. Local Lua mocks cannot establish that engine behavior.

Use artifacts/jaws-coop-pilot-windows-0.2.4.zip. Close game and companion; uninstall the previous version with its package, then install this one. Confirm 0.2.4 in both startup messages and press F2 in the main menu. Report the full result, including scan diagnostics if empty. A successful menu listing and confirmed click are still required before claiming compatibility.

# Pilot 0.2.3: UI traversal investigation

The 0.2.2 Windows test confirms speech and shortcut events, but Controls and Readable text are empty. The earlier protected-call hypothesis has not resolved navigation. This build replaces dynamic method lookup with explicit colon calls matching installed game scripts, retains type validation, and reports visited-node count plus the first failed method when a scan is empty. This is an investigative compatibility update, not verified menu support. Pressing F4 without a selection now gives a plain instruction instead of a Lua error.

Close game and companion, uninstall using the previous package, then install 0.2.3. Verify both startup messages say 0.2.3. Press F2 once in the main menu and collect the entire response, especially the scan count and method/type error. Tests include a function-valued root child count and assert useful diagnostic speech without a crash.

# Windows co-op integration pilot 0.2.2

Send `artifacts/jaws-coop-pilot-windows-0.2.3.zip`, not the earlier diagnostic ZIP. The ZIP includes the mod, Windows companion, installer, uninstaller, hash manifest and plain-text instructions. It is a real integration attempt, not a promise of complete screen-reader or co-op support.

## 0.2.2 child-count correction

The Windows speech transcript confirms JAWS speaks both its test message and frontend mod output. Browsing failed at `math.min` because the child-count lookup supplied a function. The exact engine cause is not yet confirmed. Results are now captured inside protected closures (including child component conversion), with invalid numeric/boolean return types rejected. Tests exercise both ordinary Lua pcall and a simulated host wrapper returning a function as its second result, plus malformed child counts. Both the companion title and game hello identify 0.2.2; the former was accidentally hardcoded to 0.2.0 in the previous update. Main-menu activation is still unverified.

Uninstall using the previously installed package before installing this version.

## Earlier main-menu correction

A Windows test showed frontend messages reaching the companion and F2 enumerating controls, but menu interaction failed. Audible JAWS speech and successful clicks have not yet been confirmed. The previous code used an undocumented `IsDisabled` getter, defaulting every missing call to disabled; the fixture incorrectly provided that getter. The update uses documented `IsInteractive` and `CurrentState`, blocks inactive/disabled/unavailable states, and filters interactive layout containers while continuing to traverse their children. It does not change game control states. Tests now omit `IsDisabled` and include interactive layout/movie/main containers.

For an existing 0.2.0 installation, close game and companion, run the **old package's Uninstall.cmd**, then install 0.2.2. The installer refuses differing files rather than silently upgrading them. Test F2/F3 for menu choices and F4 twice to activate, then submenu/back navigation. If it fails, collect the spoken label, Shift+F2 details, and fresh bridge.jsonl. Live main-menu compatibility is still unverified.

## Recipient steps

1. Extract the entire ZIP on the Windows Steam PC; close the game.
2. Run `Install.cmd`. A normal Steam library is detected; other locations can be entered. Program Files permissions may require running the installer as administrator using the same Windows account.
3. Start JAWS, then use the `Warhammer JAWS Pilot` desktop shortcut or `Start Pilot.cmd`.
4. Hear the test sentence, then enable `jaws_access` in the existing game's Mod Manager. Do not enable `jaws_probe` simultaneously.
5. Try F2/F3 to browse and F4 twice to activate in a disposable single-player session. Test a battle as well, then run the same flow in co-op.

Casey's Proton peer needs the same `artifacts/jaws_access.pack` and load order, not the Windows companion. The original read-only probe remains deployed locally unless explicitly replaced; building a release does not silently change that deployment.

## Implemented coverage

| Area | Pilot implementation | Important limit |
|---|---|---|
| JAWS | Windows COM speech, test/reconnect, repeat, stop, mute | JAWS 2026 runtime still untested |
| Game connection | Local versioned JSON lines, AppData output with game-directory fallback, bounded files and incremental reader | Actual engine write permissions/working directory need a live run |
| Menus and panels | Visible controls/text browsing, details, hierarchy, disabled-state check, confirmed UI clicks | Generic traversal; some screens/modal controls may expose poor labels or require adapters |
| Campaign | Normal shortcuts for recruitment, construction browser, research, diplomacy, finance, selection and end turn; treasury/turn summary | Movement/target choice uses native UI or keyboard mouse; not a semantic world-map navigator |
| Battles | Normal movement/halt/formation/ability shortcuts; local-army and visibility-filtered enemy reports | Reports are on demand; shared-unit reporting and command behavior need co-op testing |
| Map input | Windows keyboard cursor with coordinate speech, hover speech, ordinary left/right clicks | Spatial targeting is a rough aid and may require sighted assistance |
| Multiplayer | Identical mod, local speech, ordinary input; no model grants or scripted unit controllers | Real desync, transfer, host-role and save/reload tests are outstanding |
| Installation | Game detection, hashes, same-version rerun, known-probe backup, local companion, desktop shortcut, removal | Windows registry/ACL/desktop behavior remains untested on Windows |

## What verification proves

- Lua 5.1 syntax and engine-mock tests exercise confirmation, changed/disabled targets, hidden controls, local army index, enemy visibility, turn checks and failed output.
- RPFM builds a PFH5 Mod pack, extracts it, and checks exact source equality.
- PowerShell tests compile the transport and exercise partial UTF-8, partial lines, duplicate/session filtering, malformed input, bounded buffers and file replacement.
- Installer tests execute the scripts from the actual ZIP against temporary game paths with spaces. They cover fresh install, rerun, preservation of changed files, diagnostic backup, payload tampering, removal and reinstall.
- Companion replay consumes the Lua fixture output through its actual protocol path.
- Bridge.cs and Native.cs compile as C# 5 against Microsoft's .NET Framework 4.8 reference assemblies, including WinForms. This does not verify Windows runtime behavior.
- Every ZIP entry is compared to its intended payload, with per-file hashes and a ZIP SHA-256 sidecar.

These are local automated checks, not Windows/JAWS/game/co-op runtime verification. The manifest deliberately leaves those three runtime statuses false. The pilot is complete as a sendable experimental integration package; production accessibility work remains.

## Reproduction

```sh
bash tools/build-pilot.sh
bash tools/pwsh-test.sh -File tests/bridge_tests.ps1
bash tools/pwsh-test.sh -File tests/compile_windows.ps1
python3 tools/package-pilot.py
python3 tests/check_installer.py
bash tools/pwsh-test.sh -File companion/Companion.ps1 -ReplayFile tests/fixtures/access-events.jsonl
```

`pwsh-test.sh` uses a project-local portable PowerShell. The recipient uses Windows PowerShell 5.1 already installed on standard Windows 10/11, not this developer test runtime. The Lua compiler is also developer-only. No SDK or game assets are bundled.

## First feedback to collect

JAWS test sentence; game message after F2; usable labels on a campaign panel; a successful confirmed UI action; unit selection/report/halt in a battle; transition back to campaign; two-player co-op turn/battle/save/reload with both host roles. Collect `bridge.jsonl` (or fallback `jaws_access.jsonl`), `companion.log`, game versions and `manifest.json`. Logs can contain UI text. Do not send Steam credentials or configuration files.
