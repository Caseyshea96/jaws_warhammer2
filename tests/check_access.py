from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]
lua = root / 'local/tools/lua-5.1.5/src/lua'
result = subprocess.run([str(lua), 'tests/access_harness.lua'], cwd=root,
                        capture_output=True, text=True, check=True)
host = subprocess.run([str(lua), 'tests/access_harness.lua', 'host-pcall'], cwd=root,
                      capture_output=True, text=True, check=True)
assert [json.loads(line)['text'] for line in host.stdout.splitlines()] == [json.loads(line)['text'] for line in result.stdout.splitlines()]
records = [json.loads(line) for line in result.stdout.splitlines()]
assert set(r['context'] for r in records) == {'frontend', 'campaign', 'battle'}
assert all(r['version'] == 1 for r in records)
for context in ('frontend', 'campaign', 'battle'):
    group = [r for r in records if r['context'] == context]
    assert len({r['session'] for r in group}) == 1
    assert [r['sequence'] for r in group] == list(range(1, len(group) + 1))
assert not any('HIDDEN ENEMY' in r['text'] or 'OTHER PLAYER' in r['text'] for r in records)
fixtures = root / 'tests/fixtures/access-events.jsonl'
fixtures.write_text(''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in records))
print(f'PASS: {len(records)} records; UI navigation, confirmation, opaque/replaced/missing identity, UI lifecycle, stale/disabled controls, frontend action scope, turn checks, local-army selection, fog of war, file failures')
