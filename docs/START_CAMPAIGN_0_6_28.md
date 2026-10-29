# Start Campaign 0.6.28 — October 29, 2026

Owner unblocked Start Campaign. It is the one action that always asks first,
like a confirmation dialog, even with single-press activation.

- Enter/F4 on "Start Campaign, button": "Start the campaign as Tyrion, High
  Elves, Eataine? Press Enter again to start." A second press within 10 s
  clicks the real `button_start_campaign` (path and ID chain re-verified from a
  fresh root, state active/hover, watched fields unchanged, complete capture).
  Moving away cancels; a timeout says "Confirmation timed out. Press Enter
  again."; a changed lord or unavailable button blocks with nothing sent.
- After the click: "Starting the campaign. The campaign map cannot be read
  yet." The mod has no campaign-map reader yet; campaign/battle contexts
  remain silent.
- Automation: the first Activate returns `armed`, the second `input-sent`
  (`-DoubleConfirm`). `tools/live/Test-StartCampaign.ps1` does the real start
  and watches the menu heartbeat stop.
- Harness 364 scenarios (prompt, cancel by moving, timeout, changed lord,
  unavailable button, single-press still asks, automation two requests);
  removing the mandatory confirmation fails the harness.

## Live (0.6.28)

Regression (49 entries, wrap, refresh; Start Campaign asked and moving away
cancelled, two menu clicks). Then the real start: prompt spoken, exactly one
click; the High Elves campaign intro movie played (still counted as frontend;
the owner pressed Escape to skip it at ~130 s, confirming a physical Escape
reaches the game with the companion running); loading screen; the campaign map
with Tyrion and the tutorial advisor appeared ~4 minutes after the click.
No saves were written (save folder empty before and after; advice history
backed up to `work/pre-campaign-backup-*`). Game closed gracefully; no errors.

Evidence: `work/live-0.6.28-start-campaign` (campaign-*.png, map-*.png).
Next: campaign intro movies could be added to the test skip pack; a campaign
map reader is a new, larger piece of work.
