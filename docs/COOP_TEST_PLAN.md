# Co-op acceptance plan

Status: not run. Target: Steam Windows game on both peers, Casey through Proton, friend on Windows with JAWS.

## Record for every session

Date; both game builds; Proton version; Windows and JAWS versions; campaign and factions; relevant DLC; host; LAN/online; pack SHA-256 hashes and load order; companion version; starting save; exact steps; expected/actual results; logs. Keep account identifiers out of shared captures.

Establish the same basic session without the mod before diagnosing a desync as a mod regression. Test one supported connection mode first. Do not describe LAN support as proven independence from authentication services.

## Required scenarios

| Scenario | Expected result |
|---|---|
| Co-op lobby and campaign load | Both connect; only the enabled companion speaks; startup is not repeated indefinitely. |
| Friend's active turn | Read panel, navigate, activate valid action once; both peers observe the same result and resource cost. |
| Casey's active turn | Friend can inspect permitted information; actions respect the game's actual turn restrictions. |
| Pending dilemma or modal panel | Navigation remains in the active dialog; closing it invalidates stale selections. |
| Enter a campaign battle | Campaign speech is discarded; battle readers initialize without duplicated listeners. |
| Unit initially controlled by friend | Select, report, move, attack and halt behave like ordinary commands. |
| Allied unit outside friend's control | Reporting respects visibility; command is unavailable. |
| Transfer/return unit control, if supported | Available commands update with actual control; a stale queued command cannot affect a transferred unit. |
| Hidden enemy | No position, status, or target choice is disclosed beyond ordinary player knowledge. |
| Routing/under-attack alerts | Important alerts are timely; repeated alerts do not bury on-demand reports or delay commands. |
| Battle results and campaign return | Correct context resumes; battle objects and commands are invalidated. |
| Save, quit, and reload co-op | Fresh session identifiers; no replay of prior speech or gameplay actions. |
| Helper stops/restarts or JAWS exits | Game remains responsive; no gameplay mutation; reconnect gives current state rather than old queued actions. |
| Host roles reversed | The same supported interactions work without assuming the JAWS user is host. |

Start with a short co-op smoke test after each slice. Broader milestone: at least ten turns, a battle and return, save/reload, and both host roles, with no observed new desync or duplicated action. This is evidence for the tested configuration, not proof that all campaigns are supported.

## Friend usability check

Can the friend complete each supported interaction without a mouse or sighted prompts? Are names, costs, disabled states, target selection, and results clear? Can they repeat, interrupt, and mute? Do shortcuts conflict with JAWS? Is assistance still needed for the lobby, deployment, movement, or dialogs? Record each gap explicitly.

## Release gate

Do not call the prototype co-op compatible based solely on single-player tests, spoken hover text, or a standalone battle. Require a keyboard-operable campaign action and a battle action within the co-op campaign, demonstrated with JAWS on Windows against the Proton peer.
