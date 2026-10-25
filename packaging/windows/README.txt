WARHAMMER II JAWS DIAGNOSTIC PROBE - 0.1.0

This package contains an early diagnostic mod, NOT finished JAWS support.
It does not install JAWS, provide speech, or enable keyboard navigation.
Windows execution and in-game behavior have not yet been tested.

REQUIREMENTS
Windows Steam installation of Total War: WARHAMMER II.
Windows PowerShell 5.1 (included with standard Windows 10/11).
No RPFM, Python, .NET SDK, or separate third-party mod launcher required.

INSTALL
1. Extract the entire ZIP to a folder. Do not run files inside the ZIP.
2. Close Warhammer II.
3. Double-click Install.cmd. It checks the pack checksum, searches the usual
   Steam installation paths, and copies only data\jaws_probe.pack.
   For a separate Steam library, enter the game folder when prompted. Find
   it in Steam > Warhammer II > Manage > Browse local files.
4. Double-click Launch Warhammer II.cmd. This asks Steam to launch app 594570
   using its existing launch configuration. Remove any launcher-skipping
   launch option if necessary.
5. In the game's existing launcher, open Mod Manager and enable jaws_probe.
   If the mod is missing, report that before continuing. Do not replace
   vanilla packs or change this pack to a movie pack.

The launcher itself comes with the Steam game and is not redistributed here.
Mod enablement is manual. The installer does not edit launcher settings.
Scripts are unsigned. The CMD uses a process-only PowerShell execution policy;
it does not change system-wide policy. Follow local device policy if execution
is blocked. Manual installation is also supported below.

TEST
Use a disposable single-player session first.
F2: record current context.
F3: record last hovered component's label/tooltip (may be stale).
F4: record UI root child count.
Repeat at the main menu, in a campaign, and in a battle.
These listeners do not suppress existing F-key actions.
Look for jaws_probe.jsonl beside Warhammer2.exe. If absent, inspect
lua_mod_log.txt for loading errors. The actual output location depends on the
game working directory and is part of the test.

CO-OP
Co-op compatibility is unverified. After single-player checks, both players
should enable the identical pack with matching mod load order for a test.
The same pack can be used with the Windows game through Proton on Linux;
these installation scripts are for Windows only.

MANUAL INSTALL / REMOVE
Copy jaws_probe.pack to the game's data folder, then enable it in Mod Manager.
To uninstall, close the game and run Uninstall.cmd, entering the game folder.
It removes only a matching pack. Alternatively delete data\jaws_probe.pack.
Your saves and other mods are not removed. Diagnostic logs are preserved.
An interrupted installation may leave an incomplete jaws_probe.pack; remove
that file before retrying. A different existing mod is never overwritten.

TROUBLESHOOTING
If writing into Program Files is denied, run Install.cmd as administrator
or copy the pack manually with Explorer's permission prompt. No elevation is
requested automatically. Do not turn off antivirus or device protections.
Collect the diagnostic log, game version, and manifest.json when reporting
results. The SHA-256 verifies package consistency, not publisher identity.
