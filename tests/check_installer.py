"""Exercise the shipped PS installer against temporary game/library fixtures.

Runs on Linux PowerShell: does not validate Windows ACLs, COM, shortcut creation,
WinForms, Steam launch, or JAWS. Those remain explicit pilot runtime tests.
"""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import zipfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='installer-test-', dir=root / 'local') as tmp:
    folder = Path(tmp)
    with zipfile.ZipFile(root / 'artifacts/jaws-coop-pilot-windows-0.2.4.zip') as z:
        z.extractall(folder / 'package')
    package = folder / 'package/jaws-coop-pilot-windows-0.2.4'
    manifest = json.loads((package / 'manifest.json').read_text())
    game = folder / 'Steam Library/steamapps/common/Total War WARHAMMER II'
    (game / 'data').mkdir(parents=True)
    (game / 'Warhammer2.exe').touch()
    (game / 'data/unrelated.pack').write_bytes(b'preserve this')
    (game / 'save.txt').write_text('preserve save')
    appdata = folder / 'User AppData'
    appdata.mkdir()
    base = appdata / 'JawsWarhammer2'
    app = base / 'App'
    env = os.environ.copy()
    env['LOCALAPPDATA'] = str(appdata)
    env.pop('OS', None)  # Desktop COM is separately Windows-only.

    def run(script, *args, success=True):
        result = subprocess.run(['bash', str(root / 'tools/pwsh-test.sh'), '-File', str(script), *args],
                                env=env, cwd=root, capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result

    def install(success=True):
        return run(package / 'Install.ps1', '-GamePath', str(game), '-NoShortcut', success=success)

    # Invalid path is rejected before any game pack copy.
    run(package / 'Install.ps1', '-GamePath', str(folder), '-NoShortcut', success=False)
    # Existing distinct pack cannot be overwritten.
    target = game / 'data/jaws_access.pack'
    target.write_bytes(b'unknown mod')
    install(success=False)
    assert target.read_bytes() == b'unknown mod'
    target.unlink()
    # The known diagnostic is backed up and removed to prevent duplicate keys.
    old = game / 'data/jaws_probe.pack'
    shutil.copyfile(root / 'artifacts/jaws_probe.pack', old)
    install()
    assert not old.exists()
    assert hashlib.sha256((base / 'diagnostic-backup.pack').read_bytes()).hexdigest() == manifest['previous_probe_sha256']
    assert hashlib.sha256(target.read_bytes()).hexdigest() == manifest['files']['jaws_access.pack']
    assert json.loads((app / 'config.json').read_text(encoding='utf-8-sig'))['game_path'] == str(game)
    assert (app / 'Start Pilot.cmd').exists()
    install()  # Idempotent same-version install.
    # A modified companion is preserved rather than silently overwritten.
    companion = app / 'Companion.ps1'
    original = companion.read_bytes()
    companion.write_bytes(original + b'\n# custom\n')
    install(success=False)
    assert companion.read_bytes().endswith(b'# custom\n')
    companion.write_bytes(original)
    # Package tampering must fail before installation.
    packaged = package / 'Bridge.cs'
    original = packaged.read_bytes()
    packaged.write_bytes(b'corrupt')
    install(success=False)
    packaged.write_bytes(original)
    # Uninstaller must not delete a changed pack.
    original_pack = target.read_bytes()
    target.write_bytes(b'changed')
    run(app / 'Uninstall.ps1', success=False)
    assert target.read_bytes() == b'changed'
    target.write_bytes(original_pack)
    (base / 'companion.log').write_text('preserve diagnostics')
    run(app / 'Uninstall.ps1')
    assert not target.exists() and not app.exists()
    assert (game / 'data/unrelated.pack').read_bytes() == b'preserve this'
    assert (game / 'save.txt').read_text() == 'preserve save'
    assert (base / 'companion.log').read_text() == 'preserve diagnostics'
    assert (base / 'diagnostic-backup.pack').exists()
    install()  # Fresh install after removal.
    run(app / 'Uninstall.ps1')
print('PASS: shipped ZIP install, non-default path with spaces, idempotence, old-probe backup, mismatch refusal, tamper detection, uninstall and preservation')
