# Warhammer II JAWS co-op pilot

Experimental Windows accessibility integration for a two-player Total War: WARHAMMER II campaign and its battles. Casey plays the Windows game through Proton; their friend uses Windows and JAWS.

**Sendable package:** [jaws-coop-pilot-windows-0.2.4.zip](artifacts/jaws-coop-pilot-windows-0.2.4.zip).

Extract the ZIP, run `Install.cmd`, start JAWS, then use `Start Pilot.cmd`. Enable `jaws_access` in the existing game launcher's Mod Manager. The companion and mod provide speech, UI browsing, native actions, battle reports and a keyboard mouse. No third-party launcher or developer tools are required on the recipient's PC.

This is a pilot, not verified full accessibility: live Windows/JAWS and co-op testing are outstanding. See [release coverage, limits and tests](docs/PILOT_RELEASE.md). The earlier `jaws_probe` is diagnostic-only and should not be enabled alongside this pilot.

## Project documents

- [Release and test instructions](docs/PILOT_RELEASE.md)
- [Implementation plan](IMPLEMENTATION_PLAN.md)
- [Co-op acceptance scenarios](docs/COOP_TEST_PLAN.md)
- [Local environment and pack inspection](docs/ENVIRONMENT.md)
- [RPFM setup](docs/RPFM_SETUP.md)
- [Implementation backlog](docs/IMPLEMENTATION_BACKLOG.md)
- [Transport specification](protocol/README.md)

Sources: `mod/` (Lua), `companion/` (Windows PowerShell and C#), `packaging/pilot/` (installer), `tests/`, and `tools/`. Proprietary game extracts and downloaded tools remain under ignored `local/`; release packages remain under ignored `artifacts/`.
