# RPFM tooling decision

Use Rusted PackFile Manager for reading game packs and building our accessibility mod. Selected official release: **4.5.4**, Linux x86-64 archive. The release metadata and SHA-256 are pinned in `tools/rpfm-release.json`.

Official release: https://github.com/Frodo45127/rpfm/releases/tag/v4.5.4

## Installation

Run from the project directory:

```sh
bash tools/setup-rpfm.sh
```

This resumes a partial download, checks the published SHA-256, and extracts under ignored `local/tools/rpfm-4.5.4/`. It does not install system packages or change Steam files. The CLI has been verified by listing and extracting the installed WH2 base pack. GUI runtime dependencies remain unverified. Use `bash tools/rpfm.sh pack --help` for the checked CLI entry point. Consult the release's included documentation after extraction; do not assume the current website's CLI matches this pinned version.

## First-use workflow

1. Finish downloading and extracting RPFM; inspect its included executables and help output. Record any missing runtime libraries before installing dependencies.
2. Wait for Steam's game installation to finish. Confirm the Windows build (`Warhammer2.exe`) and Proton configuration.
3. Select **Warhammer 2** in RPFM and set the game path. Update the appropriate schemas if required by that version.
4. Inspect vanilla packs read-only. Extract needed loader/UI scripts into ignored `local/`; keep original game files intact.
5. Create our pack with type **Mod**, using WH2-compatible settings. Add only our Lua sources at entry paths verified from this installed game.
6. Save development builds under ignored `artifacts/`. Reopen the built pack and verify its paths and contents before deployment.
7. Copy an explicitly selected build to each player's game setup and enable it in the mod manager. Match SHA-256 and load order for co-op testing.

The CLI list/extract/create/add interfaces have been checked. Both the diagnostic and integration pilot packs have been built and round-trip extracted with exact source comparison. Live engine loading remains to be tested.
