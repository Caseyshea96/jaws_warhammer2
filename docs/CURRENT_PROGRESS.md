# Current progress

## Implemented

- Read-only native UI diagnostic with bounded root/child/event-component captures, raw return types and per-method errors; frontend-only logging preserves evidence across campaign/battle loading.
- Windows JAWS COM speech companion and installer/removal scripts.
- Development control identity validation, UI readiness gates and lifecycle invalidation.
- Companion hotkeys registered while the game is foreground, with focus checks at dispatch and tested registration/release behavior. Focus detection polls every 100 ms; in-game JAWS conflicts remain unverified.
- Bounded speech batches preserve errors/results and collapse consecutive focus messages. Speech completion across polls and simultaneous-source arbitration remain outstanding.

## Validation

Lua fixture tests cover native-like opaque identities, replaced controls, missing identities, lifecycle, turn checks and visibility filtering. Separate diagnostic fixtures check bounded captures and malformed returns. PowerShell tests cover transport, protocol, speech batches and hotkey policy. C# compilation targets .NET Framework 4.8 and C#5. Pack builds round-trip through RPFM. Installer fixtures run against temporary Steam-like paths with spaces and cover reruns, tampering and removal/preservation.

These checks are local simulations and packaging checks. No claim of full Windows runtime, main-menu activation, battle or co-op compatibility is made.

## Required next evidence

Run 0.3.0-diagnostic on the Windows test PC, press F2 once in the main menu, then hover a menu button. Collect native-ui-diagnostic.log from LocalAppData/JawsWarhammer2 or beside Warhammer2.exe, plus game/JAWS versions and active mods. Compare inline/adapted native reads and root/event component results before choosing the engine fix.

The diagnostic package is not playable. 0.2.5-dev is a development build, not a verified replacement. Prior pcall/tail-call explanations remain hypotheses. See ENGINE_RESEARCH.md for the decision table.

Proprietary game extracts, JAWS installers, downloaded developer tools, local captures and ZIP/pack artifacts are intentionally not committed. No license is assigned to third-party material.
