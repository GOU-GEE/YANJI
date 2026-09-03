"""Independent oracle. --write changes the frozen protocol vector: review as breaking.
Run with cbor2 and cryptography installed (the Flutter tests need neither).
Only the public test seed 00..1f is used here.
"""
import argparse
import json
from pathlib import Path
import cbor2
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
seed = bytes(range(32))
envelope = {
    'wire_version': 1,
    'workspace_id': '01991f82-0000-7000-8000-000000000001',
    'op_id': '01991f82-0000-7000-8000-000000000002',
    'origin_device_id': '01991f82-0000-7000-8000-000000000003',
    'origin_seq': 1,
    'hlc_wall_ms': 1788426321000,
    'hlc_counter': 0,
    'causal_context': {},
    'entity_type': 'task',
    'entity_id': '01991f82-0000-7000-8000-000000000004',
    'action': 'create',
    'payload_schema_version': 1,
    'payload': {'title': '高数极限30题', 'estimated_seconds': 5400, 'completed': False, 'note': None},
}
# All map keys are text, so cbor2's canonical length-first ordering equals
# RFC 8949 core deterministic encoded-byte ordering for this V1 profile.
wire = cbor2.dumps(envelope, canonical=True)
key = Ed25519PrivateKey.from_private_bytes(seed)
vector = {
    'profile': 'YanJi SYNC v1.1 / RFC8949 core deterministic text-key maps',
    'seed_hex': seed.hex(),
    'public_key_hex': key.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw).hex(),
    'envelope': envelope,
    'canonical_cbor_hex': wire.hex(),
    'signature_hex': key.sign(wire).hex(),
}
path = Path(__file__).resolve().parents[1] / 'test/fixtures/operation_v1.json'
parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
args = parser.parse_args()
if args.write:
    path.write_text(json.dumps(vector, ensure_ascii=False, indent=2) + '\n')
else:
    assert json.loads(path.read_text()) == vector, 'Golden vector changed: protocol review required'
print('Independent CBOR and Ed25519 vector verified')
