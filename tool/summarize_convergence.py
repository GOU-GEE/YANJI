#!/usr/bin/env python3
"""Summarize measured convergence runs; never infer unexecuted profiles."""
import argparse
import json
import platform
import statistics
from collections import Counter
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--input', type=Path, default=Path('.dart_tool/convergence/metrics'))
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--actions', type=int, default=200)
args = parser.parse_args()
records = [json.loads(p.read_text()) for p in sorted(args.input.glob(f'seed_*_actions_{args.actions}.json'))]
if not records:
    parser.error('No measured records found')
events = Counter()
for record in records:
    events.update(record['event_counts'])

def span(values):
    return {'min': min(values), 'median': statistics.median(values), 'max': max(values)}

report = {
    'description': 'Observed passing M3 runs only; fixed tests and replay test reported separately.',
    'platform': platform.platform(),
    'seeds': [r['seed'] for r in records],
    'workload_actions': sum(r['actions'] for r in records),
    'seed_duration_ms': span([r['duration_ms'] for r in records]),
    'total_seed_duration_ms': sum(r['duration_ms'] for r in records),
    'operations_per_db': span([n for r in records for n in r['stored_op_counts'].values()]),
    'rebuild_us': span([n for r in records for n in r['rebuild_us'].values()]),
    'digest_us': span([n for r in records for n in r['digest_us'].values()]),
    'database_bytes_without_wal': span([n for r in records for k, n in r['sqlite_bytes'].items() if not k.endswith('_wal')]),
    'delivered_packets': sum(r['delivered'] for r in records),
    'dropped_attempts': sum(r['dropped_attempts'] for r in records),
    'duplicates': sum(r['duplicated'] for r in records),
    'event_counts': dict(sorted(events.items())),
    'records': records,
}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({k: v for k, v in report.items() if k != 'records'}, ensure_ascii=False, indent=2))
