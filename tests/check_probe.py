"""Run Lua 5.1 engine-mock tests and validate the emitted JSON records."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
lua = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / "local/tools/lua-5.1.5/src/lua"
result = subprocess.run([str(lua), "tests/probe_harness.lua"], cwd=root,
                        check=True, capture_output=True, text=True)
records = [json.loads(line) for line in result.stdout.splitlines()]
assert len(records) == 16
for mode, count in (("frontend", 5), ("campaign", 6), ("battle", 5)):
    selected = [r for r in records if r["context"] == mode]
    assert len(selected) == count
    assert [r["sequence"] for r in selected] == list(range(1, count + 1))
    assert len({r["session"] for r in selected}) == 1
    assert 'Label "quoted"\\\n\t\x00 café' in selected[2]["text"]
    assert selected[-1]["text"].endswith("Panel closed; hover a component again.")
    assert all(r["version"] == 0 and r["generation"] == 0 for r in selected)
assert len({r["session"] for r in records}) == 3
print("PASS: three contexts, shortcut filtering, stale hover, panel reset, first tick, file failure, JSON escaping and sequences")
