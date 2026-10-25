# Warhammer II JAWS co-op pilot

Experimental Windows accessibility integration for a two-player Total War: WARHAMMER II campaign and its battles. Casey plays the Windows game through Proton; their friend uses Windows and JAWS.

**Current status:** JAWS speech and shortcut delivery have been observed on Windows, but main-menu UI traversal still fails. Campaign/battle accessibility and co-op compatibility are unverified. Development is waiting for the native UI diagnostic log; mock tests are not proof of engine compatibility.

The current investigation uses the read-only **0.3.0-diagnostic** package. See [diagnostic instructions](diagnostics/README.txt). It compares native UI reads without issuing game commands, and its launcher disables companion global hotkeys. Existing diagnostic test packages remain separate from development builds.

The **0.2.5-dev** source includes control-identity checks, UI lifecycle invalidation, foreground-scoped hotkeys and speech-batch preservation. These fixes have automated coverage but do not resolve the unverified native-reading issue.

Build artifacts are excluded from Git. Build locally with `bash tools/build-pilot.sh --diagnostic` and `python3 tools/package-pilot.py --diagnostic` after setting up the project-local tools described in the documentation. The resulting ZIP contains the installer and companion; the recipient does not need development tools. Do not enable the diagnostic and another pilot/probe simultaneously.

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
