# Warhammer II screen-reader accessibility pilot

Experimental Windows accessibility integration for Total War: WARHAMMER II.

**Current verified status:** Native automation in 0.6.13 traverses all 22 main-menu controls with next/previous wrap, opens New Campaign, reads all 17 campaign-selection entries, and opens Select Lord through the guarded Continue button. The four-second confirmation clock has passed a live expiry check with no click. Start Campaign, gameplay and co-op remain blocked. The Graphics checkpoint is complete.

**Installed development preview:** 0.6.14 adds a tested read-only Lord setup information browser. Five bounded discovery pages captured 131 visible nodes and 34 text entries, including Tyrion, High Elves, Eataine, effects and difficulty information. All 34 entries and both wrap directions passed native testing; F4 on Start Campaign was blocked without a click. The original scanner/logger and four activation targets are preserved. All 332 Lua scenarios and package/installer checks pass. Test automation is disabled after use. Injected keys, intro skipping and automatic refresh after manual lord/settings changes remain unresolved. See the [automation session handoff](docs/AUTOMATION_SESSION.md). Prior previews and the read-only diagnostic remain rollback paths.

The older **0.2.5-dev** source includes control-identity checks, UI lifecycle invalidation, foreground-scoped hotkeys, and speech-batch preservation. It is not a verified playable release.

Build artifacts are excluded from Git. Build locally with `bash tools/build-pilot.sh --diagnostic` and `python3 tools/package-pilot.py --diagnostic` after setting up the project-local tools described in the documentation. The resulting ZIP contains the installer, companion, and licensed NVDA controller runtime. Do not enable the diagnostic and another pilot/probe simultaneously.

See [current progress and validation](docs/CURRENT_PROGRESS.md), [input review](docs/JAWS_INPUT_REVIEW.md), and [engine research](docs/ENGINE_RESEARCH.md).

## Project documents

- [Release and test instructions](docs/PILOT_RELEASE.md)
- [Implementation plan](IMPLEMENTATION_PLAN.md)
- [Co-op acceptance scenarios](docs/COOP_TEST_PLAN.md)
- [Local environment and pack inspection](docs/ENVIRONMENT.md)
- [RPFM setup](docs/RPFM_SETUP.md)
- [Implementation backlog](docs/IMPLEMENTATION_BACKLOG.md)
- [Transport specification](protocol/README.md)

Sources: `mod/` (Lua), `companion/` (Windows PowerShell and C#), `packaging/pilot/` (installer), `tests/`, and `tools/`. Proprietary game extracts and downloaded tools remain under ignored `local/`; release packages remain under ignored `artifacts/`.
