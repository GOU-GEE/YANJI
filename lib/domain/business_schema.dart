import 'dart:typed_data';

import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

import '../sync/oplog/operation.dart';

/// Payload schema 1. Structural validation is independent of arrival order;
/// relational/owner validation happens later against resolved entity state.
final class BusinessSchema {
  static final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  static bool _zonesReady = false;
  static const fields = <String, Map<String, String>>{
    'workspace': {
      'name': 'text',
      'stats_timezone': 'zone',
      'created_at_ms': 'int',
      'created_by_device_id': 'text',
    },
    'exam_profile': {
      'exam_name': 'text?',
      'exam_date': 'date?',
      'target_school': 'text?',
      'target_major': 'text?',
      'target_total_score_x100': 'int?',
    },
    'subject': {
      'name': 'text',
      'category': 'text?',
      'parent_subject_id': 'uuid?',
      'target_score_x100': 'int?',
      'max_score_x100': 'int?',
      'sort_order': 'int',
      'archived': 'bool',
    },
    'task': {
      'title': 'text',
      'subject_id': 'uuid?',
      'knowledge_node_id': 'uuid?',
      'scheduled_date': 'date?',
      'repeat_daily': 'bool',
      'due_at_ms': 'int?',
      'estimated_seconds': 'int?',
      'priority': 'int',
      'sort_order': 'int',
      'status': 'task_status',
      'completed_at_ms': 'int?',
      'note': 'text?',
    },
    'daily_review': {'review_date': 'date', 'content': 'text'},
  };
  static const requiredFields = <String, List<String>>{
    'workspace': [
      'name',
      'stats_timezone',
      'created_at_ms',
      'created_by_device_id',
    ],
    'exam_profile': [],
    'subject': ['name'],
    'task': ['title', 'status'],
    'daily_review': ['review_date', 'content'],
  };
  static const defaults = <String, Map<String, Object?>>{
    'subject': {'sort_order': 0, 'archived': false},
    'task': {
      'priority': 0,
      'sort_order': 0,
      'status': 'todo',
      'repeat_daily': false,
    },
  };
  static const tables = {
    'workspace': 'workspaces',
    'exam_profile': 'exam_profiles',
    'subject': 'subjects',
    'task': 'tasks',
    'daily_review': 'daily_reviews',
    'study_session': 'study_sessions',
  };

  static void validate(OperationEnvelope e) {
    if (e.payloadSchemaVersion > 1) return;
    if (!uuid.hasMatch(e.workspaceId)) {
      throw const FormatException('Invalid workspace UUID');
    }
    if (e.entityType == 'device') {
      _device(e);
      return;
    }
    if (e.entityType == 'workspace') {
      if (e.entityId != e.workspaceId) {
        throw const FormatException('Workspace ID mismatch');
      }
    } else if (e.entityType == 'exam_profile') {
      if (e.entityId != 'exam_profile/${e.workspaceId}/default') {
        throw const FormatException('ExamProfile singleton ID mismatch');
      }
    } else if (e.entityType == 'daily_review') {
      final prefix = 'daily_review/${e.workspaceId}/';
      if (!e.entityId.startsWith(prefix) ||
          !_date(e.entityId.substring(prefix.length))) {
        throw const FormatException('Review ID mismatch');
      }
    } else if (!uuid.hasMatch(e.entityId)) {
      throw const FormatException('Invalid entity UUID');
    }
    final p = e.payload;
    if (p is! Map<String, Object?>) {
      throw const FormatException('Expected field patch');
    }
    if (e.entityType == 'study_session') {
      _session(e, p);
      return;
    }
    final allowed = fields[e.entityType];
    if (allowed == null) {
      throw const FormatException('Unsupported business entity');
    }
    if (e.action == 'delete') {
      if (e.entityType == 'daily_review' || p.isNotEmpty) {
        throw const FormatException('Illegal delete');
      }
      return;
    }
    if (e.action != 'create' && e.action != 'update') {
      throw const FormatException('Unsupported business action');
    }
    for (final f in p.entries) {
      if (!allowed.containsKey(f.key) || !_value(allowed[f.key]!, f.value)) {
        throw FormatException('Invalid field ${f.key}');
      }
    }
    if (e.entityType == 'daily_review' &&
        p.containsKey('review_date') &&
        e.entityId != 'daily_review/${e.workspaceId}/${p['review_date']}') {
      throw const FormatException('Review date mismatch');
    }
  }

  static void _device(OperationEnvelope e) {
    if (e.action != 'system' || e.payload is! Map<String, Object?>) {
      throw const FormatException('Invalid membership operation');
    }
    final p = e.payload! as Map<String, Object?>;
    final type = p['type'];
    if (type == 'workspace.genesis') {
      const keys = {
        'type',
        'root_device_id',
        'root_device_public_key',
        'created_at_ms',
      };
      if (e.entityId != e.workspaceId ||
          p.keys.toSet().difference(keys).isNotEmpty ||
          !keys.every(p.containsKey) ||
          p['root_device_id'] != e.originDeviceId ||
          p['root_device_public_key'] is! Uint8List ||
          (p['root_device_public_key'] as Uint8List).length != 32 ||
          p['created_at_ms'] is! int ||
          (p['created_at_ms'] as int) < 0) {
        throw const FormatException('Invalid workspace genesis');
      }
      return;
    }
    if (type == 'device.add') {
      const keys = {
        'type',
        'device_id',
        'device_name',
        'platform',
        'identity_public_key',
        'tls_cert_sha256',
        'paired_at_ms',
      };
      if (p.keys.toSet().difference(keys).isNotEmpty ||
          !keys.every(p.containsKey) ||
          e.entityId != p['device_id'] ||
          !uuid.hasMatch(e.entityId) ||
          p['device_name'] is! String ||
          (p['device_name'] as String).trim().isEmpty ||
          (p['device_name'] as String).length > 80 ||
          p['platform'] is! String ||
          (p['platform'] as String).length > 32 ||
          p['identity_public_key'] is! Uint8List ||
          (p['identity_public_key'] as Uint8List).length != 32 ||
          p['tls_cert_sha256'] is! Uint8List ||
          (p['tls_cert_sha256'] as Uint8List).length != 32 ||
          p['paired_at_ms'] is! int ||
          (p['paired_at_ms'] as int) < 0) {
        throw const FormatException('Invalid device.add');
      }
      return;
    }
    if (type == 'device.revoke') {
      const keys = {'type', 'target_device_id', 'max_allowed_origin_seq'};
      if (p.keys.toSet().difference(keys).isNotEmpty ||
          !keys.every(p.containsKey) ||
          e.entityId != p['target_device_id'] ||
          !uuid.hasMatch(e.entityId) ||
          p['max_allowed_origin_seq'] is! int ||
          (p['max_allowed_origin_seq'] as int) < 0) {
        throw const FormatException('Invalid device.revoke');
      }
      return;
    }
    throw const FormatException('Unknown membership operation');
  }

  static bool _date(String s) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return false;
    final d = DateTime.tryParse('${s}T00:00:00Z');
    return d != null && d.year > 0 && d.toIso8601String().startsWith(s);
  }

  static bool _value(String type, Object? value) {
    if (value == null) return type.endsWith('?');
    type = type.replaceAll('?', '');
    return switch (type) {
      'text' => value is String,
      'int' => value is int && value >= 0,
      'bool' => value is bool,
      'uuid' => value is String && uuid.hasMatch(value),
      'date' => value is String && _date(value),
      'task_status' => [
        'todo',
        'doing',
        'completed',
        'cancelled',
      ].contains(value),
      'zone' => value is String && _zone(value),
      _ => false,
    };
  }

  static bool _zone(String s) {
    if (!_zonesReady) {
      data.initializeTimeZones();
      _zonesReady = true;
    }
    return tz.timeZoneDatabase.locations.containsKey(s);
  }

  static void _session(OperationEnvelope e, Map<String, Object?> p) {
    if (e.action == 'delete') {
      if (p.isNotEmpty) throw const FormatException('Delete payload');
      return;
    }
    final Map<String, String> allowed;
    final List<String> required;
    switch (e.action) {
      case 'session.start':
        allowed = {
          'owner_device_id': 'text',
          'subject_id': 'uuid',
          'task_id': 'uuid?',
          'knowledge_node_id': 'uuid?',
          'started_at_ms': 'int',
          'segment_id': 'uuid',
          'mode': 'text',
          'note': 'text?',
        };
        required = [
          'owner_device_id',
          'subject_id',
          'started_at_ms',
          'segment_id',
          'mode',
        ];
      case 'session.resume':
        allowed = {'segment_id': 'uuid', 'started_at_ms': 'int'};
        required = allowed.keys.toList();
      case 'session.pause':
      case 'session.stop':
        allowed = {'segment_id': 'uuid', 'ended_at_ms': 'int'};
        required = allowed.keys.toList();
      default:
        throw const FormatException('Session requires atomic action');
    }
    if (!required.every(p.containsKey)) {
      throw const FormatException('Incomplete session action');
    }
    for (final f in p.entries) {
      if (!allowed.containsKey(f.key) || !_value(allowed[f.key]!, f.value)) {
        throw FormatException('Invalid session field ${f.key}');
      }
    }
    if (e.action == 'session.start' &&
        (p['owner_device_id'] != e.originDeviceId ||
            !['stopwatch', 'pomodoro'].contains(p['mode']))) {
      throw const FormatException('Invalid timer owner/mode');
    }
  }
}
