"""Package Windows pilot with a hash manifest and exact payload checks."""
from pathlib import Path
import hashlib
import json
import zipfile
import sys
diagnostic = "--diagnostic" in sys.argv
version = "0.3.0-diagnostic" if diagnostic else "0.2.5-dev"
pack_name = "jaws_access_diagnostic.pack" if diagnostic else "jaws_access.pack"

root = Path(__file__).resolve().parents[1]
pack = (root / 'artifacts' / pack_name).read_bytes()
digest = hashlib.sha256(pack).hexdigest()
assert (root / 'artifacts' / (pack_name + '.sha256')).read_text().split()[0] == digest
assert pack[:4] == b'PFH5' and int.from_bytes(pack[4:8], 'little') & 15 == 3
files = {'jaws_access.pack': pack}
for folder in ('companion', 'packaging/pilot'):
    for path in sorted((root / folder).iterdir()):
        if not path.is_file():
            continue
        assert path.name not in files, f'duplicate {path.name}'
        files[path.name] = path.read_text().replace('\n', '\r\n').encode('utf-8')
if diagnostic:
    files['Start Pilot.cmd'] = files['Start Pilot.cmd'].replace(b' -Launch', b' -Launch -NoHotkeys')
    files['README.txt'] = (root / 'diagnostics/README.txt').read_bytes()
    assert files['Start Pilot.cmd'].count(b'-NoHotkeys') == 2
    assert b'[switch]$NoHotkeys' in files['Companion.ps1']
manifest = {
    'version': version, 'stage': 'read-only-native-ui-diagnostic' if diagnostic else 'experimental-integration-pilot', 'steam_app_id': 594570,
    'windows_runtime_tested': False, 'jaws_runtime_tested': False, 'coop_tested': False,
    'previous_probe_sha256': hashlib.sha256((root / 'artifacts/jaws_probe.pack').read_bytes()).hexdigest(),
    'files': {name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())}
}
files['manifest.json'] = (json.dumps(manifest, indent=2) + '\n').encode()
expected = {'jaws_access.pack','Companion.ps1','Bridge.cs','Native.cs','HotkeyPolicy.cs','Protocol.ps1',
            'Install.ps1','Install.cmd','Uninstall.ps1','Uninstall.cmd','Start Pilot.cmd','README.txt','manifest.json'}
assert set(files) == expected, (set(files) ^ expected)
output = root / f'artifacts/jaws-coop-pilot-windows-{version}.zip'
prefix = f'jaws-coop-pilot-windows-{version}/'
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for name, data in sorted(files.items()):
        archive.writestr(prefix + name, data)
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    for name, data in files.items():
        assert archive.read(prefix + name) == data
output.with_suffix('.zip.sha256').write_text(hashlib.sha256(output.read_bytes()).hexdigest() + '  ' + output.name + '\n')
print(output)
