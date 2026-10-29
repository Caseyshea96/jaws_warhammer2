# Warhammer II accessibility: research and implementation plan

## Current Windows/NVDA status

The active screen-reader target is now NVDA, with keyboard-only operation. The 0.4.2 live frontend test spoke all 22 controls and supported reverse wraparound. The 0.4.3 read-only package adds the separately removable NVDA quiet-mode add-on; its live speech and stability test is pending. Normal Steam-path discovery is verified on this Windows PC.

The next interactive prototype permits only the captured Graphics button, with identity revalidation and a second F4 within four seconds. Browsing away cancels confirmation; expiry or a backward clock change requires a fresh confirmation. This prototype is not included in 0.4.3. After the speech/stability test, verify opening Graphics and returning with the game's Escape key, then develop campaign setup and a settlement interaction alongside unit reporting and battle commands. Actual campaign and battle play, including co-op, remain the acceptance target.

Use [current progress](docs/CURRENT_PROGRESS.md) for release status. The earlier dated notes below describe the project's Linux/JAWS origins and are retained as research history; their old version numbers and unresolved frontend-reading claims do not describe the current NVDA build.

## Earlier development notes

Unreleased source fixes: opaque control identity validation, UI lifecycle invalidation/readiness checks, and frontend-only Escape action are implemented with regression tests. Native Windows menu reading remains unresolved; the diagnostic package is unchanged.

Diagnostic implementation: `diagnostics/jaws_access.lua` and the `0.3.0-diagnostic` ZIP now provide bounded raw native-read comparisons with lifecycle checks and no game actions. The companion launcher disables global hotkeys. Local tests pass; the Windows diagnostic log remains required before menu compatibility can be established.

Latest research: [WH2 native UI findings and diagnostic specification](docs/ENGINE_RESEARCH.md). CA itself uses protected UI calls; root lifecycle and raw per-method reads must be checked before attributing failure to pcall or tail calls.

Review gate: [JAWS 2026 and game input audit](docs/JAWS_INPUT_REVIEW.md) identifies unresolved root traversal, global hotkey conflicts, opaque-address validation and frontend modal gaps. Pause speculative compatibility releases until the controlled native-read diagnostic establishes the failing boundary. 0.2.4 remains unverified in-game.

Updated 2026-10-25: the integrated Windows pilot 0.2.4 is implemented and packaged, with Lua, transport, pack and installer fixture tests. Live Windows/JAWS and co-op tests remain outstanding. See [pilot release coverage and recipient instructions](docs/PILOT_RELEASE.md). The roadmap below continues beyond the pilot; it is not a claim that every screen or spatial control is finished.

## Authorized integration scope

The user requests an end-to-end implementation attempt without waiting for every diagnostic result. Proceed with the verified source interfaces and explicit provisional adapters, then revise using runtime evidence. The probe remains a diagnostic mode rather than a prerequisite for writing the next components. Never label an untested integration as working or co-op compatible.

Implement in this order:

1. **Windows JAWS companion and installer.** Consume the local event stream; support JAWS COM speech, interrupt, repeat, mute, bounded queues, and reconnection. Include a fixed-text self-test and a console backend. Ship sources plus a Windows-runnable package; verify Windows execution separately. The existing diagnostic ZIP in `artifacts/jaws-probe-windows-0.1.0.zip` is only the packaging baseline and contains no speech companion.
2. **Robust mod-to-companion transport.** Evolve the probe into versioned sessions with context resets, bounded record sizes, markup cleanup, explicit active-session handshake, and no historical replay after reconnect. Reuse the file-output mechanism found in installed scripts. Keep speech failures isolated from game execution.
3. **Keyboard UI navigation.** Use native script shortcuts to browse visible interactive components and request name/state/tooltip. Build context-aware focus and stable ordering, with per-panel adapters where the generic tree is unsuitable. Re-resolve targets before activation, handle modals/back, and report unsupported panels. Cached hover text is not an accessibility solution.
4. **Campaign integration.** Implement settlements/armies, recruitment, construction, research, turn announcements, and dialogs, then map movement and diplomacy. Prefer existing UI actions. Enforce local turn and ownership restrictions, confirm actual outcomes, and expose gaps explicitly. Begin with one chosen faction/campaign fixture before generalizing.
5. **Co-op campaign battle integration.** Implement owned/currently controllable unit selection, concise status, visible-target browsing, attack/halt, and a simple accessible movement scheme. Add deployment, formations, abilities and prioritized alerts afterward. Detect current control and transfers; if detection is unresolved, disable commands for ambiguous units rather than assume allied units are controllable. Do not rely on pause or tutorial-only controllers.
6. **Co-op lifecycle and packaging.** Handle turn changes, campaign-to-battle-to-campaign transitions, host roles, helper restarts, save/reload, and identical pack distribution. Use the game's existing Steam launcher, with manual enablement initially. A launcher shortcut is included; no third-party launcher is required or redistributed.

Develop and test independent layers on Linux while Windows/game tests are outstanding. Add engine mocks for meaningful boundary cases, but treat real Windows JAWS and two-player co-op runs as the acceptance evidence. Make speculative capabilities opt-in or clearly unavailable until their command route is validated. A full attempt covers both campaign and battles; it does not imply every faction-specific screen will work in the first build.

The immediate implementation target is: launch the Windows companion, enable the mod through Steam's launcher, enter a campaign, navigate a panel by keyboard and hear JAWS output, then enter a battle and select/report/control a unit. Once this works locally, run the same flow in co-op with the Proton peer and correct failures. Proceed without repeated approval questions for routine reversible implementation changes.

## Scope and environment

Casey has installed the Steam Windows game and plans to run it through Proton on Linux, without JAWS. Their friend plays on Windows with JAWS. The main target is a two-player co-op campaign, including its battles, with equal priority for campaign and battle accessibility. Build a game-side Lua mod and a Windows-only speech companion. Initially install identical mod packs on both machines; the companion is optional and local.

Develop each small feature in single-player, then immediately test it in co-op before expanding scope. Competitive multiplayer is outside the initial scope. Custom battles are useful development fixtures but cannot replace campaign battle testing. Follow [the implementation backlog](docs/IMPLEMENTATION_BACKLOG.md) and [co-op acceptance scenarios](docs/COOP_TEST_PLAN.md).

Steam app 594570 is installed, build 13784690, with the Windows executable verified and Proton Experimental selected. See [environment findings](docs/ENVIRONMENT.md). The workspace contains a JAWS installer, not an implementation. Earlier environment inspection found no `dotnet`, `lua`, `luajit`, or `rpfm_cli` executable on PATH. The installer was identified as a Windows executable, not installed or integrity-verified.

## Verified foundations

- WH2 exposes `GetStateText`, `GetTooltipText`, hierarchy traversal, visibility/interactivity queries, and simulated clicks through its [UIComponent API](https://chadvandy.github.io/tw_modding_resources/WH2/campaign/uicomponent.html). This establishes available mechanisms, not usable labels or reliable keyboard navigation on every screen.
- The [core API](https://chadvandy.github.io/tw_modding_resources/WH2/campaign/core.html) documents `core:add_listener`, UI roots, and mod loading. Its loader example includes `script/_lib/mod/` and `script/battle/mod/`; campaign/frontend entry points must be checked in the installed build before packaging.
- WH2 documents [script output](https://chadvandy.github.io/tw_modding_resources/WH2/frontend/global.html), [campaign startup callbacks](https://chadvandy.github.io/tw_modding_resources/WH2/campaign/campaign_manager.html), and the [`UITrigger` event](https://chadvandy.github.io/tw_modding_resources/WH2/scripting_doc.html), with `trigger()` and `faction_cqi()` context accessors. Do not copy event names from newer Total War games without verification.
- Tolk's actual [JAWS driver source](https://github.com/dkager/tolk/blob/master/src/ScreenReaderDriverJAWS.cpp) creates a JAWS COM object and calls `SayString` and `StopSpeech`. Its [interface header](https://github.com/dkager/tolk/blob/master/src/fsapi.h) supplies the COM interface definitions. Compatibility with the friend's installed JAWS version and process architecture remains a runtime test.
- [RPFM](https://github.com/Frodo45127/rpfm) supports Warhammer II. Package as a normal Mod pack with the WH2 game selected; pin a tested tool release and inspect its actual CLI help rather than assume commands from another version.

## Tooling decision

RPFM is selected. The official Linux x86-64 release 4.5.4 and its published checksum are pinned in `tools/rpfm-release.json`; `tools/setup-rpfm.sh` provides resumable project-local setup. See [RPFM setup](docs/RPFM_SETUP.md). The archive checksum, CLI startup, and base-pack listing/extraction have passed. The 5.2.0 binaries required a newer glibc, so 4.5.4 is pinned instead; GUI dependencies remain untested.

## Proposed architecture

Game Lua → local structured output → Windows companion → JAWS COM → speech.

Prefer Lua for reading game UI and maintaining logical focus. Use a small C# companion for file handling, speech scheduling, and Windows integration. Direct COM is the initial candidate; Tolk is an alternative if broader screen-reader support becomes useful. Keep a console-only output backend for development without JAWS. Confirm the registered JAWS class/type library on Windows before fixing the interop implementation.

Start by testing dedicated Lua file output (`io.open`, append, flush/close). If unavailable, test the game's documented logging facilities and inspect the installed scripts for activation requirements. File availability, writable paths, encoding, buffering, and timing are unverified. Do not assume Lua sockets or native DLL loading are available.

Use versioned records with session ID, sequence, event kind, text, and priority. Handle partial writes, truncation, duplicate records, companion restart, and game restart. Strip game markup and suppress repetitive hover events. Provide interrupt, repeat-last, and mute; do not let an unbounded speech queue build up.

For commands back into the game, first probe available keyboard/shortcut events in the installed scripts. If insufficient, test companion hotkeys and a bounded, data-only command file read by Lua. Do not execute external Lua as the command protocol. Include sequence acknowledgements and panel-generation IDs to reject stale or duplicate activation. Test how JAWS and fullscreen input affect delivery. [Windows RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey) is an available helper mechanism, not proof it works with this game's input handling.

## Milestones and acceptance criteria

1. **Baseline and source inspection.** Locate both game installations; record game build, storefront, Proton version, JAWS version, and mod list. Play an unmodded multiplayer turn and battle, then save/reload. Inspect game packs read-only for mod loaders, UI events, logging, and keyboard handling. Keep extracted proprietary files local.
2. **Independent probes.** On Windows, speak, interrupt, and repeat fixed text through JAWS while the game has focus. In the game, load a minimal mod and emit a startup marker plus a visible button's text and tooltip. Prove output works separately in campaign, frontend, and battle; mark unsupported contexts explicitly.
3. **Read-only vertical slice.** Speak a selected settlement/panel and useful visible details through the companion. Report missing labels instead of inventing them. Verify correct Unicode, no stale replay after reload, and a measured response time; target under 300 ms from event to speech request, subject to testing.
4. **One keyboard-operable panel.** Implement next/previous item, read details, activate, and back for one chosen settlement panel. Re-resolve UI components after panel changes; skip hidden/disabled controls. Confirm actual in-game results before announcing success. Test with the friend without mouse assistance. A hover reader alone does not pass this milestone.
5. **Multiplayer validation.** Both use identical pack bytes and load order; only the friend runs the helper. Test each player as host, at least ten turns, one battle transition, save/reload, and helper exit/restart. Verify no duplicate action, new desync, or gameplay difference caused by speech settings.
6. **Expand from feedback.** Extend campaign and battle coverage together, based on testing with the friend. Campaign candidates are recruitment, construction, research, notifications, diplomacy, and campaign-map navigation. Battle candidates are unit selection, visible-target browsing, movement, attack, halt, formations, and abilities. Do not declare the first playable version complete on campaign coverage alone.

### Battle workstream, starting at milestone 2

Run battle probes alongside campaign probes, without waiting for a campaign feature set. Develop the smallest slice in a single-player battle, then immediately test a battle entered from the co-op campaign. Verify the mod loads, current local control can be identified, and visible unit information can be read without assuming tutorial-only interfaces work everywhere. If co-op unit sharing is available, distinguish original army ownership from the player currently authorized to command each unit, including transfer and return of control.

The [WH2 unit API](https://chadvandy.github.io/tw_modding_resources/WH2/battle/battle_unit.html) documents position, unit distance, live soldier count, hitpoint fraction, ammunition, routing, and visibility-to-alliance. Build a short on-demand report for a selected owned unit, plus prioritized routing/under-attack alerts. Establish which values actually exist in each tested battle mode. Do not read hidden enemies.

The first interactive battle slice must let the friend select an owned unit, hear its status, select a visible target, and issue and verify an ordinary attack/halt command. Movement needs an accessible destination representation (relative directions/distances or named targets), to be designed with the friend. Audit native hotkeys and UI actions before attempting scripted unit controllers: controller availability alone does not prove correct ownership or multiplayer synchronization. Test command delivery independently of speech; excessive narration must not delay commands.

Pass the slice in a multiplayer battle on both machines without duplicate orders or desync, with keyboard-only operation by the friend. If multiplayer script loading, unit access, or command delivery fails, explicitly reassess battle feasibility before expanding campaign work. Do not rely on multiplayer pause availability until tested.

The milestone list above is iterative: milestone 5 applies immediately after each interactive campaign or battle slice, not only after completing single-player coverage. An unmodded co-op baseline must precede claims about mod-induced desyncs, but source inspection and single-player probes need not wait for both players.

## Multiplayer rules

Speech state and UI focus are local. Reading aloud must not consume the gameplay RNG or change the simulation. Prefer existing UI actions for commands, and verify their multiplayer behavior. If custom simulation commands become necessary, investigate `CampaignUI.TriggerCampaignScriptEvent` in the actual WH2 scripts and the documented `UITrigger` event before implementation; the complete sending interface was not verified in this research. Revalidate ownership, turn, target, and costs; never substitute free scripted grants for normal paid actions.

Expose only information available to the local player. Unit visibility and fog of war need explicit checks before any battle or map summaries.

LAN and online modes can share this accessibility design. [Steam lists LAN support](https://store.steampowered.com/app/594570/Total_War_WARHAMMER_II/), but independence from all authentication/matchmaking services is not proven. The [native Linux port cannot play with Windows](https://www.feralinteractive.com/en/faqs/warhammer2tw/1.0/linux/); test Windows-under-Proton instead.

## Planned repository layout

`mod/` — Lua sources and screen adapters, with entry paths fixed after inspection.

`companion/` — C# speech bridge, transport, diagnostics, and configurable input.

`protocol/` — record specification and representative fixtures.

`tools/` — reproducible packing and deployment scripts using a pinned RPFM version.

`tests/` — transport parsing/restart tests and UI-adapter fixtures captured from real sessions.

`docs/` — setup, keyboard controls, supported screens, and multiplayer test results.

## Next information needed

After installation: game path and build; friend's availability for Windows/JAWS tests; required speech/braille support and preferred keyboard scheme. Both campaign and battles are required. Development can begin with the speech and transport probes before installation. A usable release estimate should wait until both keyboard-operable slices and multiplayer tests pass.

### Development validation update

The 0.2.5-dev build includes lifecycle/identity fixes and foreground-scoped companion registration. Lua fixtures, hotkey-policy tests, .NET Framework compilation, transport/parser tests and packaged installer/removal fixtures pass. Native Windows focus timing and JAWS conflicts remain unverified. Do not replace the pending 0.3.0-diagnostic experiment with this development build; native menu-reading evidence is still required.
