# Warhammer II screen-reader accessibility pilot

Experimental Windows accessibility integration for Total War: WARHAMMER II.

**Accepted installed build: 0.6.28.** Native menu navigation, lord selection,
NVDA-style speech, standard menu keys and confirmed Start Campaign have passed
live testing. Campaign-map actions, gameplay and co-op remain unavailable.

**Current development candidate: 0.6.31.** Adds opt-in HUD readiness checks,
native getter type diagnostics and a read-only capture refresh channel. All 402
Lua scenarios and package/client checks pass; live campaign verification remains
pending. The owner requested a stopping point. 0.6.28 remains installed and all
test processes/flags are closed. See the [candidate checkpoint](docs/CAMPAIGN_DISCOVERY_0_6_31.md).
It is not an accepted campaign HUD reader. Physical-key and full audible
completion acceptance remain separate from native handler/API results.

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
