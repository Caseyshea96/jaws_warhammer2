"""Build a portable Windows installer ZIP from the round-trip checked pack."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[1]
pack = root / 'artifacts/jaws_probe.pack'
payload = pack.read_bytes()
digest = hashlib.sha256(payload).hexdigest()
assert (root / 'artifacts/jaws_probe.pack.sha256').read_text().split()[0] == digest
assert payload[:4] == b'PFH5' and int.from_bytes(payload[4:8], 'little') & 15 == 3
manifest = {'version': '0.1.0', 'stage': 'diagnostic-only', 'steam_app_id': 594570,
            'pack': 'jaws_probe.pack', 'pack_sha256': digest,
            'windows_runtime_tested': False, 'coop_tested': False}
output = root / 'artifacts/jaws-probe-windows-0.1.0.zip'
prefix = 'jaws-probe-windows-0.1.0/'
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    archive.writestr(prefix + 'jaws_probe.pack', payload)
    archive.writestr(prefix + 'manifest.json', json.dumps(manifest, indent=2) + '\n')
    for path in sorted((root / 'packaging/windows').iterdir()):
        archive.writestr(prefix + path.name, path.read_text().replace('\n', '\r\n'))
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert hashlib.sha256(archive.read(prefix + 'jaws_probe.pack')).hexdigest() == digest
    assert len(archive.namelist()) == 8
output.with_suffix('.zip.sha256').write_text(hashlib.sha256(output.read_bytes()).hexdigest() + '  ' + output.name + '\n')
print(output)
