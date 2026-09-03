// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Oplog extends Table with TableInfo<Oplog, OplogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Oplog(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originSeqMeta = const VerificationMeta(
    'originSeq',
  );
  late final GeneratedColumn<int> originSeq = GeneratedColumn<int>(
    'origin_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (origin_seq > 0)',
  );
  static const VerificationMeta _wireVersionMeta = const VerificationMeta(
    'wireVersion',
  );
  late final GeneratedColumn<int> wireVersion = GeneratedColumn<int>(
    'wire_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (wire_version > 0)',
  );
  static const VerificationMeta _hlcWallMsMeta = const VerificationMeta(
    'hlcWallMs',
  );
  late final GeneratedColumn<int> hlcWallMs = GeneratedColumn<int>(
    'hlc_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (hlc_wall_ms >= 0)',
  );
  static const VerificationMeta _hlcCounterMeta = const VerificationMeta(
    'hlcCounter',
  );
  late final GeneratedColumn<int> hlcCounter = GeneratedColumn<int>(
    'hlc_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (hlc_counter >= 0)',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadSchemaVersionMeta =
      const VerificationMeta('payloadSchemaVersion');
  late final GeneratedColumn<int> payloadSchemaVersion = GeneratedColumn<int>(
    'payload_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (payload_schema_version > 0)',
  );
  static const VerificationMeta _envelopeBytesMeta = const VerificationMeta(
    'envelopeBytes',
  );
  late final GeneratedColumn<Uint8List> envelopeBytes =
      GeneratedColumn<Uint8List>(
        'envelope_bytes',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  late final GeneratedColumn<Uint8List> signature = GeneratedColumn<Uint8List>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(signature) = 64)',
  );
  static const VerificationMeta _receivedFromDeviceIdMeta =
      const VerificationMeta('receivedFromDeviceId');
  late final GeneratedColumn<String> receivedFromDeviceId =
      GeneratedColumn<String>(
        'received_from_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _receivedAtMsMeta = const VerificationMeta(
    'receivedAtMs',
  );
  late final GeneratedColumn<int> receivedAtMs = GeneratedColumn<int>(
    'received_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _applyStateMeta = const VerificationMeta(
    'applyState',
  );
  late final GeneratedColumn<String> applyState = GeneratedColumn<String>(
    'apply_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending_entity_create\' CHECK (apply_state IN (\'applied\', \'pending_entity_create\', \'pending_dependency\', \'pending_authorization\', \'pending_schema\', \'unauthorized_revoked\', \'invalid_domain\'))',
    defaultValue: const CustomExpression('\'pending_entity_create\''),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _localErrorMeta = const VerificationMeta(
    'localError',
  );
  late final GeneratedColumn<String> localError = GeneratedColumn<String>(
    'local_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    workspaceId,
    originDeviceId,
    originSeq,
    wireVersion,
    hlcWallMs,
    hlcCounter,
    entityType,
    entityId,
    action,
    payloadSchemaVersion,
    envelopeBytes,
    signature,
    receivedFromDeviceId,
    receivedAtMs,
    applyState,
    retryCount,
    localError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oplog';
  @override
  VerificationContext validateIntegrity(
    Insertable<OplogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('origin_seq')) {
      context.handle(
        _originSeqMeta,
        originSeq.isAcceptableOrUnknown(data['origin_seq']!, _originSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_originSeqMeta);
    }
    if (data.containsKey('wire_version')) {
      context.handle(
        _wireVersionMeta,
        wireVersion.isAcceptableOrUnknown(
          data['wire_version']!,
          _wireVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wireVersionMeta);
    }
    if (data.containsKey('hlc_wall_ms')) {
      context.handle(
        _hlcWallMsMeta,
        hlcWallMs.isAcceptableOrUnknown(data['hlc_wall_ms']!, _hlcWallMsMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcWallMsMeta);
    }
    if (data.containsKey('hlc_counter')) {
      context.handle(
        _hlcCounterMeta,
        hlcCounter.isAcceptableOrUnknown(data['hlc_counter']!, _hlcCounterMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcCounterMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_schema_version')) {
      context.handle(
        _payloadSchemaVersionMeta,
        payloadSchemaVersion.isAcceptableOrUnknown(
          data['payload_schema_version']!,
          _payloadSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadSchemaVersionMeta);
    }
    if (data.containsKey('envelope_bytes')) {
      context.handle(
        _envelopeBytesMeta,
        envelopeBytes.isAcceptableOrUnknown(
          data['envelope_bytes']!,
          _envelopeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_envelopeBytesMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('received_from_device_id')) {
      context.handle(
        _receivedFromDeviceIdMeta,
        receivedFromDeviceId.isAcceptableOrUnknown(
          data['received_from_device_id']!,
          _receivedFromDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('received_at_ms')) {
      context.handle(
        _receivedAtMsMeta,
        receivedAtMs.isAcceptableOrUnknown(
          data['received_at_ms']!,
          _receivedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('apply_state')) {
      context.handle(
        _applyStateMeta,
        applyState.isAcceptableOrUnknown(data['apply_state']!, _applyStateMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('local_error')) {
      context.handle(
        _localErrorMeta,
        localError.isAcceptableOrUnknown(data['local_error']!, _localErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, originDeviceId, originSeq},
  ];
  @override
  OplogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OplogData(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      originSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_seq'],
      )!,
      wireVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wire_version'],
      )!,
      hlcWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_wall_ms'],
      )!,
      hlcCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_counter'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_schema_version'],
      )!,
      envelopeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}envelope_bytes'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}signature'],
      )!,
      receivedFromDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_from_device_id'],
      ),
      receivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_ms'],
      ),
      applyState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apply_state'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      localError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_error'],
      ),
    );
  }

  @override
  Oplog createAlias(String alias) {
    return Oplog(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(workspace_id, origin_device_id, origin_seq)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class OplogData extends DataClass implements Insertable<OplogData> {
  final String opId;
  final String workspaceId;
  final String originDeviceId;
  final int originSeq;
  final int wireVersion;
  final int hlcWallMs;
  final int hlcCounter;
  final String entityType;
  final String entityId;
  final String action;
  final int payloadSchemaVersion;
  final Uint8List envelopeBytes;
  final Uint8List signature;
  final String? receivedFromDeviceId;
  final int? receivedAtMs;
  final String applyState;
  final int retryCount;
  final String? localError;
  const OplogData({
    required this.opId,
    required this.workspaceId,
    required this.originDeviceId,
    required this.originSeq,
    required this.wireVersion,
    required this.hlcWallMs,
    required this.hlcCounter,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payloadSchemaVersion,
    required this.envelopeBytes,
    required this.signature,
    this.receivedFromDeviceId,
    this.receivedAtMs,
    required this.applyState,
    required this.retryCount,
    this.localError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['origin_seq'] = Variable<int>(originSeq);
    map['wire_version'] = Variable<int>(wireVersion);
    map['hlc_wall_ms'] = Variable<int>(hlcWallMs);
    map['hlc_counter'] = Variable<int>(hlcCounter);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload_schema_version'] = Variable<int>(payloadSchemaVersion);
    map['envelope_bytes'] = Variable<Uint8List>(envelopeBytes);
    map['signature'] = Variable<Uint8List>(signature);
    if (!nullToAbsent || receivedFromDeviceId != null) {
      map['received_from_device_id'] = Variable<String>(receivedFromDeviceId);
    }
    if (!nullToAbsent || receivedAtMs != null) {
      map['received_at_ms'] = Variable<int>(receivedAtMs);
    }
    map['apply_state'] = Variable<String>(applyState);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || localError != null) {
      map['local_error'] = Variable<String>(localError);
    }
    return map;
  }

  OplogCompanion toCompanion(bool nullToAbsent) {
    return OplogCompanion(
      opId: Value(opId),
      workspaceId: Value(workspaceId),
      originDeviceId: Value(originDeviceId),
      originSeq: Value(originSeq),
      wireVersion: Value(wireVersion),
      hlcWallMs: Value(hlcWallMs),
      hlcCounter: Value(hlcCounter),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payloadSchemaVersion: Value(payloadSchemaVersion),
      envelopeBytes: Value(envelopeBytes),
      signature: Value(signature),
      receivedFromDeviceId: receivedFromDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedFromDeviceId),
      receivedAtMs: receivedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAtMs),
      applyState: Value(applyState),
      retryCount: Value(retryCount),
      localError: localError == null && nullToAbsent
          ? const Value.absent()
          : Value(localError),
    );
  }

  factory OplogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OplogData(
      opId: serializer.fromJson<String>(json['op_id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      originSeq: serializer.fromJson<int>(json['origin_seq']),
      wireVersion: serializer.fromJson<int>(json['wire_version']),
      hlcWallMs: serializer.fromJson<int>(json['hlc_wall_ms']),
      hlcCounter: serializer.fromJson<int>(json['hlc_counter']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      action: serializer.fromJson<String>(json['action']),
      payloadSchemaVersion: serializer.fromJson<int>(
        json['payload_schema_version'],
      ),
      envelopeBytes: serializer.fromJson<Uint8List>(json['envelope_bytes']),
      signature: serializer.fromJson<Uint8List>(json['signature']),
      receivedFromDeviceId: serializer.fromJson<String?>(
        json['received_from_device_id'],
      ),
      receivedAtMs: serializer.fromJson<int?>(json['received_at_ms']),
      applyState: serializer.fromJson<String>(json['apply_state']),
      retryCount: serializer.fromJson<int>(json['retry_count']),
      localError: serializer.fromJson<String?>(json['local_error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'op_id': serializer.toJson<String>(opId),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'origin_seq': serializer.toJson<int>(originSeq),
      'wire_version': serializer.toJson<int>(wireVersion),
      'hlc_wall_ms': serializer.toJson<int>(hlcWallMs),
      'hlc_counter': serializer.toJson<int>(hlcCounter),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload_schema_version': serializer.toJson<int>(payloadSchemaVersion),
      'envelope_bytes': serializer.toJson<Uint8List>(envelopeBytes),
      'signature': serializer.toJson<Uint8List>(signature),
      'received_from_device_id': serializer.toJson<String?>(
        receivedFromDeviceId,
      ),
      'received_at_ms': serializer.toJson<int?>(receivedAtMs),
      'apply_state': serializer.toJson<String>(applyState),
      'retry_count': serializer.toJson<int>(retryCount),
      'local_error': serializer.toJson<String?>(localError),
    };
  }

  OplogData copyWith({
    String? opId,
    String? workspaceId,
    String? originDeviceId,
    int? originSeq,
    int? wireVersion,
    int? hlcWallMs,
    int? hlcCounter,
    String? entityType,
    String? entityId,
    String? action,
    int? payloadSchemaVersion,
    Uint8List? envelopeBytes,
    Uint8List? signature,
    Value<String?> receivedFromDeviceId = const Value.absent(),
    Value<int?> receivedAtMs = const Value.absent(),
    String? applyState,
    int? retryCount,
    Value<String?> localError = const Value.absent(),
  }) => OplogData(
    opId: opId ?? this.opId,
    workspaceId: workspaceId ?? this.workspaceId,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    originSeq: originSeq ?? this.originSeq,
    wireVersion: wireVersion ?? this.wireVersion,
    hlcWallMs: hlcWallMs ?? this.hlcWallMs,
    hlcCounter: hlcCounter ?? this.hlcCounter,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payloadSchemaVersion: payloadSchemaVersion ?? this.payloadSchemaVersion,
    envelopeBytes: envelopeBytes ?? this.envelopeBytes,
    signature: signature ?? this.signature,
    receivedFromDeviceId: receivedFromDeviceId.present
        ? receivedFromDeviceId.value
        : this.receivedFromDeviceId,
    receivedAtMs: receivedAtMs.present ? receivedAtMs.value : this.receivedAtMs,
    applyState: applyState ?? this.applyState,
    retryCount: retryCount ?? this.retryCount,
    localError: localError.present ? localError.value : this.localError,
  );
  OplogData copyWithCompanion(OplogCompanion data) {
    return OplogData(
      opId: data.opId.present ? data.opId.value : this.opId,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      originSeq: data.originSeq.present ? data.originSeq.value : this.originSeq,
      wireVersion: data.wireVersion.present
          ? data.wireVersion.value
          : this.wireVersion,
      hlcWallMs: data.hlcWallMs.present ? data.hlcWallMs.value : this.hlcWallMs,
      hlcCounter: data.hlcCounter.present
          ? data.hlcCounter.value
          : this.hlcCounter,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payloadSchemaVersion: data.payloadSchemaVersion.present
          ? data.payloadSchemaVersion.value
          : this.payloadSchemaVersion,
      envelopeBytes: data.envelopeBytes.present
          ? data.envelopeBytes.value
          : this.envelopeBytes,
      signature: data.signature.present ? data.signature.value : this.signature,
      receivedFromDeviceId: data.receivedFromDeviceId.present
          ? data.receivedFromDeviceId.value
          : this.receivedFromDeviceId,
      receivedAtMs: data.receivedAtMs.present
          ? data.receivedAtMs.value
          : this.receivedAtMs,
      applyState: data.applyState.present
          ? data.applyState.value
          : this.applyState,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      localError: data.localError.present
          ? data.localError.value
          : this.localError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OplogData(')
          ..write('opId: $opId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('wireVersion: $wireVersion, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadSchemaVersion: $payloadSchemaVersion, ')
          ..write('envelopeBytes: $envelopeBytes, ')
          ..write('signature: $signature, ')
          ..write('receivedFromDeviceId: $receivedFromDeviceId, ')
          ..write('receivedAtMs: $receivedAtMs, ')
          ..write('applyState: $applyState, ')
          ..write('retryCount: $retryCount, ')
          ..write('localError: $localError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    workspaceId,
    originDeviceId,
    originSeq,
    wireVersion,
    hlcWallMs,
    hlcCounter,
    entityType,
    entityId,
    action,
    payloadSchemaVersion,
    $driftBlobEquality.hash(envelopeBytes),
    $driftBlobEquality.hash(signature),
    receivedFromDeviceId,
    receivedAtMs,
    applyState,
    retryCount,
    localError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OplogData &&
          other.opId == this.opId &&
          other.workspaceId == this.workspaceId &&
          other.originDeviceId == this.originDeviceId &&
          other.originSeq == this.originSeq &&
          other.wireVersion == this.wireVersion &&
          other.hlcWallMs == this.hlcWallMs &&
          other.hlcCounter == this.hlcCounter &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payloadSchemaVersion == this.payloadSchemaVersion &&
          $driftBlobEquality.equals(other.envelopeBytes, this.envelopeBytes) &&
          $driftBlobEquality.equals(other.signature, this.signature) &&
          other.receivedFromDeviceId == this.receivedFromDeviceId &&
          other.receivedAtMs == this.receivedAtMs &&
          other.applyState == this.applyState &&
          other.retryCount == this.retryCount &&
          other.localError == this.localError);
}

class OplogCompanion extends UpdateCompanion<OplogData> {
  final Value<String> opId;
  final Value<String> workspaceId;
  final Value<String> originDeviceId;
  final Value<int> originSeq;
  final Value<int> wireVersion;
  final Value<int> hlcWallMs;
  final Value<int> hlcCounter;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<int> payloadSchemaVersion;
  final Value<Uint8List> envelopeBytes;
  final Value<Uint8List> signature;
  final Value<String?> receivedFromDeviceId;
  final Value<int?> receivedAtMs;
  final Value<String> applyState;
  final Value<int> retryCount;
  final Value<String?> localError;
  final Value<int> rowid;
  const OplogCompanion({
    this.opId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.originSeq = const Value.absent(),
    this.wireVersion = const Value.absent(),
    this.hlcWallMs = const Value.absent(),
    this.hlcCounter = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadSchemaVersion = const Value.absent(),
    this.envelopeBytes = const Value.absent(),
    this.signature = const Value.absent(),
    this.receivedFromDeviceId = const Value.absent(),
    this.receivedAtMs = const Value.absent(),
    this.applyState = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.localError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OplogCompanion.insert({
    required String opId,
    required String workspaceId,
    required String originDeviceId,
    required int originSeq,
    required int wireVersion,
    required int hlcWallMs,
    required int hlcCounter,
    required String entityType,
    required String entityId,
    required String action,
    required int payloadSchemaVersion,
    required Uint8List envelopeBytes,
    required Uint8List signature,
    this.receivedFromDeviceId = const Value.absent(),
    this.receivedAtMs = const Value.absent(),
    this.applyState = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.localError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       workspaceId = Value(workspaceId),
       originDeviceId = Value(originDeviceId),
       originSeq = Value(originSeq),
       wireVersion = Value(wireVersion),
       hlcWallMs = Value(hlcWallMs),
       hlcCounter = Value(hlcCounter),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payloadSchemaVersion = Value(payloadSchemaVersion),
       envelopeBytes = Value(envelopeBytes),
       signature = Value(signature);
  static Insertable<OplogData> custom({
    Expression<String>? opId,
    Expression<String>? workspaceId,
    Expression<String>? originDeviceId,
    Expression<int>? originSeq,
    Expression<int>? wireVersion,
    Expression<int>? hlcWallMs,
    Expression<int>? hlcCounter,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<int>? payloadSchemaVersion,
    Expression<Uint8List>? envelopeBytes,
    Expression<Uint8List>? signature,
    Expression<String>? receivedFromDeviceId,
    Expression<int>? receivedAtMs,
    Expression<String>? applyState,
    Expression<int>? retryCount,
    Expression<String>? localError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (originSeq != null) 'origin_seq': originSeq,
      if (wireVersion != null) 'wire_version': wireVersion,
      if (hlcWallMs != null) 'hlc_wall_ms': hlcWallMs,
      if (hlcCounter != null) 'hlc_counter': hlcCounter,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payloadSchemaVersion != null)
        'payload_schema_version': payloadSchemaVersion,
      if (envelopeBytes != null) 'envelope_bytes': envelopeBytes,
      if (signature != null) 'signature': signature,
      if (receivedFromDeviceId != null)
        'received_from_device_id': receivedFromDeviceId,
      if (receivedAtMs != null) 'received_at_ms': receivedAtMs,
      if (applyState != null) 'apply_state': applyState,
      if (retryCount != null) 'retry_count': retryCount,
      if (localError != null) 'local_error': localError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OplogCompanion copyWith({
    Value<String>? opId,
    Value<String>? workspaceId,
    Value<String>? originDeviceId,
    Value<int>? originSeq,
    Value<int>? wireVersion,
    Value<int>? hlcWallMs,
    Value<int>? hlcCounter,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<int>? payloadSchemaVersion,
    Value<Uint8List>? envelopeBytes,
    Value<Uint8List>? signature,
    Value<String?>? receivedFromDeviceId,
    Value<int?>? receivedAtMs,
    Value<String>? applyState,
    Value<int>? retryCount,
    Value<String?>? localError,
    Value<int>? rowid,
  }) {
    return OplogCompanion(
      opId: opId ?? this.opId,
      workspaceId: workspaceId ?? this.workspaceId,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      originSeq: originSeq ?? this.originSeq,
      wireVersion: wireVersion ?? this.wireVersion,
      hlcWallMs: hlcWallMs ?? this.hlcWallMs,
      hlcCounter: hlcCounter ?? this.hlcCounter,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payloadSchemaVersion: payloadSchemaVersion ?? this.payloadSchemaVersion,
      envelopeBytes: envelopeBytes ?? this.envelopeBytes,
      signature: signature ?? this.signature,
      receivedFromDeviceId: receivedFromDeviceId ?? this.receivedFromDeviceId,
      receivedAtMs: receivedAtMs ?? this.receivedAtMs,
      applyState: applyState ?? this.applyState,
      retryCount: retryCount ?? this.retryCount,
      localError: localError ?? this.localError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (originSeq.present) {
      map['origin_seq'] = Variable<int>(originSeq.value);
    }
    if (wireVersion.present) {
      map['wire_version'] = Variable<int>(wireVersion.value);
    }
    if (hlcWallMs.present) {
      map['hlc_wall_ms'] = Variable<int>(hlcWallMs.value);
    }
    if (hlcCounter.present) {
      map['hlc_counter'] = Variable<int>(hlcCounter.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadSchemaVersion.present) {
      map['payload_schema_version'] = Variable<int>(payloadSchemaVersion.value);
    }
    if (envelopeBytes.present) {
      map['envelope_bytes'] = Variable<Uint8List>(envelopeBytes.value);
    }
    if (signature.present) {
      map['signature'] = Variable<Uint8List>(signature.value);
    }
    if (receivedFromDeviceId.present) {
      map['received_from_device_id'] = Variable<String>(
        receivedFromDeviceId.value,
      );
    }
    if (receivedAtMs.present) {
      map['received_at_ms'] = Variable<int>(receivedAtMs.value);
    }
    if (applyState.present) {
      map['apply_state'] = Variable<String>(applyState.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (localError.present) {
      map['local_error'] = Variable<String>(localError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OplogCompanion(')
          ..write('opId: $opId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('wireVersion: $wireVersion, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadSchemaVersion: $payloadSchemaVersion, ')
          ..write('envelopeBytes: $envelopeBytes, ')
          ..write('signature: $signature, ')
          ..write('receivedFromDeviceId: $receivedFromDeviceId, ')
          ..write('receivedAtMs: $receivedAtMs, ')
          ..write('applyState: $applyState, ')
          ..write('retryCount: $retryCount, ')
          ..write('localError: $localError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceClockState extends Table
    with TableInfo<WorkspaceClockState, WorkspaceClockStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceClockState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nextOriginSeqMeta = const VerificationMeta(
    'nextOriginSeq',
  );
  late final GeneratedColumn<int> nextOriginSeq = GeneratedColumn<int>(
    'next_origin_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (next_origin_seq > 0)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _lastHlcWallMsMeta = const VerificationMeta(
    'lastHlcWallMs',
  );
  late final GeneratedColumn<int> lastHlcWallMs = GeneratedColumn<int>(
    'last_hlc_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (last_hlc_wall_ms >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastHlcCounterMeta = const VerificationMeta(
    'lastHlcCounter',
  );
  late final GeneratedColumn<int> lastHlcCounter = GeneratedColumn<int>(
    'last_hlc_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (last_hlc_counter >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    deviceId,
    nextOriginSeq,
    lastHlcWallMs,
    lastHlcCounter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_clock_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceClockStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('next_origin_seq')) {
      context.handle(
        _nextOriginSeqMeta,
        nextOriginSeq.isAcceptableOrUnknown(
          data['next_origin_seq']!,
          _nextOriginSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_hlc_wall_ms')) {
      context.handle(
        _lastHlcWallMsMeta,
        lastHlcWallMs.isAcceptableOrUnknown(
          data['last_hlc_wall_ms']!,
          _lastHlcWallMsMeta,
        ),
      );
    }
    if (data.containsKey('last_hlc_counter')) {
      context.handle(
        _lastHlcCounterMeta,
        lastHlcCounter.isAcceptableOrUnknown(
          data['last_hlc_counter']!,
          _lastHlcCounterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, deviceId};
  @override
  WorkspaceClockStateData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceClockStateData(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      nextOriginSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_origin_seq'],
      )!,
      lastHlcWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_hlc_wall_ms'],
      )!,
      lastHlcCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_hlc_counter'],
      )!,
    );
  }

  @override
  WorkspaceClockState createAlias(String alias) {
    return WorkspaceClockState(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, device_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceClockStateData extends DataClass
    implements Insertable<WorkspaceClockStateData> {
  final String workspaceId;
  final String deviceId;
  final int nextOriginSeq;
  final int lastHlcWallMs;
  final int lastHlcCounter;
  const WorkspaceClockStateData({
    required this.workspaceId,
    required this.deviceId,
    required this.nextOriginSeq,
    required this.lastHlcWallMs,
    required this.lastHlcCounter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['device_id'] = Variable<String>(deviceId);
    map['next_origin_seq'] = Variable<int>(nextOriginSeq);
    map['last_hlc_wall_ms'] = Variable<int>(lastHlcWallMs);
    map['last_hlc_counter'] = Variable<int>(lastHlcCounter);
    return map;
  }

  WorkspaceClockStateCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceClockStateCompanion(
      workspaceId: Value(workspaceId),
      deviceId: Value(deviceId),
      nextOriginSeq: Value(nextOriginSeq),
      lastHlcWallMs: Value(lastHlcWallMs),
      lastHlcCounter: Value(lastHlcCounter),
    );
  }

  factory WorkspaceClockStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceClockStateData(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      nextOriginSeq: serializer.fromJson<int>(json['next_origin_seq']),
      lastHlcWallMs: serializer.fromJson<int>(json['last_hlc_wall_ms']),
      lastHlcCounter: serializer.fromJson<int>(json['last_hlc_counter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'device_id': serializer.toJson<String>(deviceId),
      'next_origin_seq': serializer.toJson<int>(nextOriginSeq),
      'last_hlc_wall_ms': serializer.toJson<int>(lastHlcWallMs),
      'last_hlc_counter': serializer.toJson<int>(lastHlcCounter),
    };
  }

  WorkspaceClockStateData copyWith({
    String? workspaceId,
    String? deviceId,
    int? nextOriginSeq,
    int? lastHlcWallMs,
    int? lastHlcCounter,
  }) => WorkspaceClockStateData(
    workspaceId: workspaceId ?? this.workspaceId,
    deviceId: deviceId ?? this.deviceId,
    nextOriginSeq: nextOriginSeq ?? this.nextOriginSeq,
    lastHlcWallMs: lastHlcWallMs ?? this.lastHlcWallMs,
    lastHlcCounter: lastHlcCounter ?? this.lastHlcCounter,
  );
  WorkspaceClockStateData copyWithCompanion(WorkspaceClockStateCompanion data) {
    return WorkspaceClockStateData(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      nextOriginSeq: data.nextOriginSeq.present
          ? data.nextOriginSeq.value
          : this.nextOriginSeq,
      lastHlcWallMs: data.lastHlcWallMs.present
          ? data.lastHlcWallMs.value
          : this.lastHlcWallMs,
      lastHlcCounter: data.lastHlcCounter.present
          ? data.lastHlcCounter.value
          : this.lastHlcCounter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceClockStateData(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('nextOriginSeq: $nextOriginSeq, ')
          ..write('lastHlcWallMs: $lastHlcWallMs, ')
          ..write('lastHlcCounter: $lastHlcCounter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    deviceId,
    nextOriginSeq,
    lastHlcWallMs,
    lastHlcCounter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceClockStateData &&
          other.workspaceId == this.workspaceId &&
          other.deviceId == this.deviceId &&
          other.nextOriginSeq == this.nextOriginSeq &&
          other.lastHlcWallMs == this.lastHlcWallMs &&
          other.lastHlcCounter == this.lastHlcCounter);
}

class WorkspaceClockStateCompanion
    extends UpdateCompanion<WorkspaceClockStateData> {
  final Value<String> workspaceId;
  final Value<String> deviceId;
  final Value<int> nextOriginSeq;
  final Value<int> lastHlcWallMs;
  final Value<int> lastHlcCounter;
  final Value<int> rowid;
  const WorkspaceClockStateCompanion({
    this.workspaceId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.nextOriginSeq = const Value.absent(),
    this.lastHlcWallMs = const Value.absent(),
    this.lastHlcCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceClockStateCompanion.insert({
    required String workspaceId,
    required String deviceId,
    this.nextOriginSeq = const Value.absent(),
    this.lastHlcWallMs = const Value.absent(),
    this.lastHlcCounter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       deviceId = Value(deviceId);
  static Insertable<WorkspaceClockStateData> custom({
    Expression<String>? workspaceId,
    Expression<String>? deviceId,
    Expression<int>? nextOriginSeq,
    Expression<int>? lastHlcWallMs,
    Expression<int>? lastHlcCounter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (deviceId != null) 'device_id': deviceId,
      if (nextOriginSeq != null) 'next_origin_seq': nextOriginSeq,
      if (lastHlcWallMs != null) 'last_hlc_wall_ms': lastHlcWallMs,
      if (lastHlcCounter != null) 'last_hlc_counter': lastHlcCounter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceClockStateCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? deviceId,
    Value<int>? nextOriginSeq,
    Value<int>? lastHlcWallMs,
    Value<int>? lastHlcCounter,
    Value<int>? rowid,
  }) {
    return WorkspaceClockStateCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      deviceId: deviceId ?? this.deviceId,
      nextOriginSeq: nextOriginSeq ?? this.nextOriginSeq,
      lastHlcWallMs: lastHlcWallMs ?? this.lastHlcWallMs,
      lastHlcCounter: lastHlcCounter ?? this.lastHlcCounter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (nextOriginSeq.present) {
      map['next_origin_seq'] = Variable<int>(nextOriginSeq.value);
    }
    if (lastHlcWallMs.present) {
      map['last_hlc_wall_ms'] = Variable<int>(lastHlcWallMs.value);
    }
    if (lastHlcCounter.present) {
      map['last_hlc_counter'] = Variable<int>(lastHlcCounter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceClockStateCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('nextOriginSeq: $nextOriginSeq, ')
          ..write('lastHlcWallMs: $lastHlcWallMs, ')
          ..write('lastHlcCounter: $lastHlcCounter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ObservedOrigins extends Table
    with TableInfo<ObservedOrigins, ObservedOrigin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ObservedOrigins(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _maxObservedSeqMeta = const VerificationMeta(
    'maxObservedSeq',
  );
  late final GeneratedColumn<int> maxObservedSeq = GeneratedColumn<int>(
    'max_observed_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (max_observed_seq >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    deviceId,
    originDeviceId,
    maxObservedSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observed_origins';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObservedOrigin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('max_observed_seq')) {
      context.handle(
        _maxObservedSeqMeta,
        maxObservedSeq.isAcceptableOrUnknown(
          data['max_observed_seq']!,
          _maxObservedSeqMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxObservedSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    workspaceId,
    deviceId,
    originDeviceId,
  };
  @override
  ObservedOrigin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObservedOrigin(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      maxObservedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_observed_seq'],
      )!,
    );
  }

  @override
  ObservedOrigins createAlias(String alias) {
    return ObservedOrigins(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, device_id, origin_device_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ObservedOrigin extends DataClass implements Insertable<ObservedOrigin> {
  final String workspaceId;
  final String deviceId;
  final String originDeviceId;
  final int maxObservedSeq;
  const ObservedOrigin({
    required this.workspaceId,
    required this.deviceId,
    required this.originDeviceId,
    required this.maxObservedSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['device_id'] = Variable<String>(deviceId);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['max_observed_seq'] = Variable<int>(maxObservedSeq);
    return map;
  }

  ObservedOriginsCompanion toCompanion(bool nullToAbsent) {
    return ObservedOriginsCompanion(
      workspaceId: Value(workspaceId),
      deviceId: Value(deviceId),
      originDeviceId: Value(originDeviceId),
      maxObservedSeq: Value(maxObservedSeq),
    );
  }

  factory ObservedOrigin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObservedOrigin(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      maxObservedSeq: serializer.fromJson<int>(json['max_observed_seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'device_id': serializer.toJson<String>(deviceId),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'max_observed_seq': serializer.toJson<int>(maxObservedSeq),
    };
  }

  ObservedOrigin copyWith({
    String? workspaceId,
    String? deviceId,
    String? originDeviceId,
    int? maxObservedSeq,
  }) => ObservedOrigin(
    workspaceId: workspaceId ?? this.workspaceId,
    deviceId: deviceId ?? this.deviceId,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    maxObservedSeq: maxObservedSeq ?? this.maxObservedSeq,
  );
  ObservedOrigin copyWithCompanion(ObservedOriginsCompanion data) {
    return ObservedOrigin(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      maxObservedSeq: data.maxObservedSeq.present
          ? data.maxObservedSeq.value
          : this.maxObservedSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObservedOrigin(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('maxObservedSeq: $maxObservedSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(workspaceId, deviceId, originDeviceId, maxObservedSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObservedOrigin &&
          other.workspaceId == this.workspaceId &&
          other.deviceId == this.deviceId &&
          other.originDeviceId == this.originDeviceId &&
          other.maxObservedSeq == this.maxObservedSeq);
}

class ObservedOriginsCompanion extends UpdateCompanion<ObservedOrigin> {
  final Value<String> workspaceId;
  final Value<String> deviceId;
  final Value<String> originDeviceId;
  final Value<int> maxObservedSeq;
  final Value<int> rowid;
  const ObservedOriginsCompanion({
    this.workspaceId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.maxObservedSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObservedOriginsCompanion.insert({
    required String workspaceId,
    required String deviceId,
    required String originDeviceId,
    required int maxObservedSeq,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       deviceId = Value(deviceId),
       originDeviceId = Value(originDeviceId),
       maxObservedSeq = Value(maxObservedSeq);
  static Insertable<ObservedOrigin> custom({
    Expression<String>? workspaceId,
    Expression<String>? deviceId,
    Expression<String>? originDeviceId,
    Expression<int>? maxObservedSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (deviceId != null) 'device_id': deviceId,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (maxObservedSeq != null) 'max_observed_seq': maxObservedSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObservedOriginsCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? deviceId,
    Value<String>? originDeviceId,
    Value<int>? maxObservedSeq,
    Value<int>? rowid,
  }) {
    return ObservedOriginsCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      deviceId: deviceId ?? this.deviceId,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      maxObservedSeq: maxObservedSeq ?? this.maxObservedSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (maxObservedSeq.present) {
      map['max_observed_seq'] = Variable<int>(maxObservedSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservedOriginsCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('maxObservedSeq: $maxObservedSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncQuarantine extends Table
    with TableInfo<SyncQuarantine, SyncQuarantineData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncQuarantine(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _receivedAtMsMeta = const VerificationMeta(
    'receivedAtMs',
  );
  late final GeneratedColumn<int> receivedAtMs = GeneratedColumn<int>(
    'received_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, reason, receivedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_quarantine';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQuarantineData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('received_at_ms')) {
      context.handle(
        _receivedAtMsMeta,
        receivedAtMs.isAcceptableOrUnknown(
          data['received_at_ms']!,
          _receivedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQuarantineData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQuarantineData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      receivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_ms'],
      )!,
    );
  }

  @override
  SyncQuarantine createAlias(String alias) {
    return SyncQuarantine(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncQuarantineData extends DataClass
    implements Insertable<SyncQuarantineData> {
  final int id;
  final String reason;
  final int receivedAtMs;
  const SyncQuarantineData({
    required this.id,
    required this.reason,
    required this.receivedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reason'] = Variable<String>(reason);
    map['received_at_ms'] = Variable<int>(receivedAtMs);
    return map;
  }

  SyncQuarantineCompanion toCompanion(bool nullToAbsent) {
    return SyncQuarantineCompanion(
      id: Value(id),
      reason: Value(reason),
      receivedAtMs: Value(receivedAtMs),
    );
  }

  factory SyncQuarantineData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQuarantineData(
      id: serializer.fromJson<int>(json['id']),
      reason: serializer.fromJson<String>(json['reason']),
      receivedAtMs: serializer.fromJson<int>(json['received_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reason': serializer.toJson<String>(reason),
      'received_at_ms': serializer.toJson<int>(receivedAtMs),
    };
  }

  SyncQuarantineData copyWith({int? id, String? reason, int? receivedAtMs}) =>
      SyncQuarantineData(
        id: id ?? this.id,
        reason: reason ?? this.reason,
        receivedAtMs: receivedAtMs ?? this.receivedAtMs,
      );
  SyncQuarantineData copyWithCompanion(SyncQuarantineCompanion data) {
    return SyncQuarantineData(
      id: data.id.present ? data.id.value : this.id,
      reason: data.reason.present ? data.reason.value : this.reason,
      receivedAtMs: data.receivedAtMs.present
          ? data.receivedAtMs.value
          : this.receivedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQuarantineData(')
          ..write('id: $id, ')
          ..write('reason: $reason, ')
          ..write('receivedAtMs: $receivedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reason, receivedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQuarantineData &&
          other.id == this.id &&
          other.reason == this.reason &&
          other.receivedAtMs == this.receivedAtMs);
}

class SyncQuarantineCompanion extends UpdateCompanion<SyncQuarantineData> {
  final Value<int> id;
  final Value<String> reason;
  final Value<int> receivedAtMs;
  const SyncQuarantineCompanion({
    this.id = const Value.absent(),
    this.reason = const Value.absent(),
    this.receivedAtMs = const Value.absent(),
  });
  SyncQuarantineCompanion.insert({
    this.id = const Value.absent(),
    required String reason,
    required int receivedAtMs,
  }) : reason = Value(reason),
       receivedAtMs = Value(receivedAtMs);
  static Insertable<SyncQuarantineData> custom({
    Expression<int>? id,
    Expression<String>? reason,
    Expression<int>? receivedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reason != null) 'reason': reason,
      if (receivedAtMs != null) 'received_at_ms': receivedAtMs,
    });
  }

  SyncQuarantineCompanion copyWith({
    Value<int>? id,
    Value<String>? reason,
    Value<int>? receivedAtMs,
  }) {
    return SyncQuarantineCompanion(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      receivedAtMs: receivedAtMs ?? this.receivedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (receivedAtMs.present) {
      map['received_at_ms'] = Variable<int>(receivedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQuarantineCompanion(')
          ..write('id: $id, ')
          ..write('reason: $reason, ')
          ..write('receivedAtMs: $receivedAtMs')
          ..write(')'))
        .toString();
  }
}

class Workspaces extends Table with TableInfo<Workspaces, Workspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Workspaces(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statsTimezoneMeta = const VerificationMeta(
    'statsTimezone',
  );
  late final GeneratedColumn<String> statsTimezone = GeneratedColumn<String>(
    'stats_timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (created_at_ms >= 0)',
  );
  static const VerificationMeta _createdByDeviceIdMeta = const VerificationMeta(
    'createdByDeviceId',
  );
  late final GeneratedColumn<String> createdByDeviceId =
      GeneratedColumn<String>(
        'created_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    statsTimezone,
    createdAtMs,
    createdByDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workspace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stats_timezone')) {
      context.handle(
        _statsTimezoneMeta,
        statsTimezone.isAcceptableOrUnknown(
          data['stats_timezone']!,
          _statsTimezoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statsTimezoneMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('created_by_device_id')) {
      context.handle(
        _createdByDeviceIdMeta,
        createdByDeviceId.isAcceptableOrUnknown(
          data['created_by_device_id']!,
          _createdByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByDeviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workspace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      statsTimezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats_timezone'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      createdByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_device_id'],
      )!,
    );
  }

  @override
  Workspaces createAlias(String alias) {
    return Workspaces(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Workspace extends DataClass implements Insertable<Workspace> {
  final String id;
  final String name;
  final String statsTimezone;
  final int createdAtMs;
  final String createdByDeviceId;
  const Workspace({
    required this.id,
    required this.name,
    required this.statsTimezone,
    required this.createdAtMs,
    required this.createdByDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['stats_timezone'] = Variable<String>(statsTimezone);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['created_by_device_id'] = Variable<String>(createdByDeviceId);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      statsTimezone: Value(statsTimezone),
      createdAtMs: Value(createdAtMs),
      createdByDeviceId: Value(createdByDeviceId),
    );
  }

  factory Workspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workspace(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      statsTimezone: serializer.fromJson<String>(json['stats_timezone']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      createdByDeviceId: serializer.fromJson<String>(
        json['created_by_device_id'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'stats_timezone': serializer.toJson<String>(statsTimezone),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'created_by_device_id': serializer.toJson<String>(createdByDeviceId),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? statsTimezone,
    int? createdAtMs,
    String? createdByDeviceId,
  }) => Workspace(
    id: id ?? this.id,
    name: name ?? this.name,
    statsTimezone: statsTimezone ?? this.statsTimezone,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
  );
  Workspace copyWithCompanion(WorkspacesCompanion data) {
    return Workspace(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      statsTimezone: data.statsTimezone.present
          ? data.statsTimezone.value
          : this.statsTimezone,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      createdByDeviceId: data.createdByDeviceId.present
          ? data.createdByDeviceId.value
          : this.createdByDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workspace(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('statsTimezone: $statsTimezone, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('createdByDeviceId: $createdByDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, statsTimezone, createdAtMs, createdByDeviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workspace &&
          other.id == this.id &&
          other.name == this.name &&
          other.statsTimezone == this.statsTimezone &&
          other.createdAtMs == this.createdAtMs &&
          other.createdByDeviceId == this.createdByDeviceId);
}

class WorkspacesCompanion extends UpdateCompanion<Workspace> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> statsTimezone;
  final Value<int> createdAtMs;
  final Value<String> createdByDeviceId;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.statsTimezone = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.createdByDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required String statsTimezone,
    required int createdAtMs,
    required String createdByDeviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       statsTimezone = Value(statsTimezone),
       createdAtMs = Value(createdAtMs),
       createdByDeviceId = Value(createdByDeviceId);
  static Insertable<Workspace> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? statsTimezone,
    Expression<int>? createdAtMs,
    Expression<String>? createdByDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (statsTimezone != null) 'stats_timezone': statsTimezone,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (createdByDeviceId != null) 'created_by_device_id': createdByDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? statsTimezone,
    Value<int>? createdAtMs,
    Value<String>? createdByDeviceId,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      statsTimezone: statsTimezone ?? this.statsTimezone,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (statsTimezone.present) {
      map['stats_timezone'] = Variable<String>(statsTimezone.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (createdByDeviceId.present) {
      map['created_by_device_id'] = Variable<String>(createdByDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('statsTimezone: $statsTimezone, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('createdByDeviceId: $createdByDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TrustedDevices extends Table
    with TableInfo<TrustedDevices, TrustedDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TrustedDevices(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _identityPublicKeyMeta = const VerificationMeta(
    'identityPublicKey',
  );
  late final GeneratedColumn<Uint8List> identityPublicKey =
      GeneratedColumn<Uint8List>(
        'identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (length(identity_public_key) = 32)',
      );
  static const VerificationMeta _trustStateMeta = const VerificationMeta(
    'trustState',
  );
  late final GeneratedColumn<String> trustState = GeneratedColumn<String>(
    'trust_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (trust_state IN (\'active\', \'pending\', \'revoked\'))',
  );
  static const VerificationMeta _maxAllowedOriginSeqMeta =
      const VerificationMeta('maxAllowedOriginSeq');
  late final GeneratedColumn<int> maxAllowedOriginSeq = GeneratedColumn<int>(
    'max_allowed_origin_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (max_allowed_origin_seq >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    deviceId,
    identityPublicKey,
    trustState,
    maxAllowedOriginSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trusted_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrustedDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
        _identityPublicKeyMeta,
        identityPublicKey.isAcceptableOrUnknown(
          data['identity_public_key']!,
          _identityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('trust_state')) {
      context.handle(
        _trustStateMeta,
        trustState.isAcceptableOrUnknown(data['trust_state']!, _trustStateMeta),
      );
    } else if (isInserting) {
      context.missing(_trustStateMeta);
    }
    if (data.containsKey('max_allowed_origin_seq')) {
      context.handle(
        _maxAllowedOriginSeqMeta,
        maxAllowedOriginSeq.isAcceptableOrUnknown(
          data['max_allowed_origin_seq']!,
          _maxAllowedOriginSeqMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, deviceId};
  @override
  TrustedDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrustedDevice(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      identityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}identity_public_key'],
      )!,
      trustState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trust_state'],
      )!,
      maxAllowedOriginSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_allowed_origin_seq'],
      ),
    );
  }

  @override
  TrustedDevices createAlias(String alias) {
    return TrustedDevices(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, device_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TrustedDevice extends DataClass implements Insertable<TrustedDevice> {
  final String workspaceId;
  final String deviceId;
  final Uint8List identityPublicKey;
  final String trustState;
  final int? maxAllowedOriginSeq;
  const TrustedDevice({
    required this.workspaceId,
    required this.deviceId,
    required this.identityPublicKey,
    required this.trustState,
    this.maxAllowedOriginSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['device_id'] = Variable<String>(deviceId);
    map['identity_public_key'] = Variable<Uint8List>(identityPublicKey);
    map['trust_state'] = Variable<String>(trustState);
    if (!nullToAbsent || maxAllowedOriginSeq != null) {
      map['max_allowed_origin_seq'] = Variable<int>(maxAllowedOriginSeq);
    }
    return map;
  }

  TrustedDevicesCompanion toCompanion(bool nullToAbsent) {
    return TrustedDevicesCompanion(
      workspaceId: Value(workspaceId),
      deviceId: Value(deviceId),
      identityPublicKey: Value(identityPublicKey),
      trustState: Value(trustState),
      maxAllowedOriginSeq: maxAllowedOriginSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAllowedOriginSeq),
    );
  }

  factory TrustedDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrustedDevice(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      identityPublicKey: serializer.fromJson<Uint8List>(
        json['identity_public_key'],
      ),
      trustState: serializer.fromJson<String>(json['trust_state']),
      maxAllowedOriginSeq: serializer.fromJson<int?>(
        json['max_allowed_origin_seq'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'device_id': serializer.toJson<String>(deviceId),
      'identity_public_key': serializer.toJson<Uint8List>(identityPublicKey),
      'trust_state': serializer.toJson<String>(trustState),
      'max_allowed_origin_seq': serializer.toJson<int?>(maxAllowedOriginSeq),
    };
  }

  TrustedDevice copyWith({
    String? workspaceId,
    String? deviceId,
    Uint8List? identityPublicKey,
    String? trustState,
    Value<int?> maxAllowedOriginSeq = const Value.absent(),
  }) => TrustedDevice(
    workspaceId: workspaceId ?? this.workspaceId,
    deviceId: deviceId ?? this.deviceId,
    identityPublicKey: identityPublicKey ?? this.identityPublicKey,
    trustState: trustState ?? this.trustState,
    maxAllowedOriginSeq: maxAllowedOriginSeq.present
        ? maxAllowedOriginSeq.value
        : this.maxAllowedOriginSeq,
  );
  TrustedDevice copyWithCompanion(TrustedDevicesCompanion data) {
    return TrustedDevice(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      trustState: data.trustState.present
          ? data.trustState.value
          : this.trustState,
      maxAllowedOriginSeq: data.maxAllowedOriginSeq.present
          ? data.maxAllowedOriginSeq.value
          : this.maxAllowedOriginSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrustedDevice(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('trustState: $trustState, ')
          ..write('maxAllowedOriginSeq: $maxAllowedOriginSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    deviceId,
    $driftBlobEquality.hash(identityPublicKey),
    trustState,
    maxAllowedOriginSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustedDevice &&
          other.workspaceId == this.workspaceId &&
          other.deviceId == this.deviceId &&
          $driftBlobEquality.equals(
            other.identityPublicKey,
            this.identityPublicKey,
          ) &&
          other.trustState == this.trustState &&
          other.maxAllowedOriginSeq == this.maxAllowedOriginSeq);
}

class TrustedDevicesCompanion extends UpdateCompanion<TrustedDevice> {
  final Value<String> workspaceId;
  final Value<String> deviceId;
  final Value<Uint8List> identityPublicKey;
  final Value<String> trustState;
  final Value<int?> maxAllowedOriginSeq;
  final Value<int> rowid;
  const TrustedDevicesCompanion({
    this.workspaceId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.trustState = const Value.absent(),
    this.maxAllowedOriginSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrustedDevicesCompanion.insert({
    required String workspaceId,
    required String deviceId,
    required Uint8List identityPublicKey,
    required String trustState,
    this.maxAllowedOriginSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       deviceId = Value(deviceId),
       identityPublicKey = Value(identityPublicKey),
       trustState = Value(trustState);
  static Insertable<TrustedDevice> custom({
    Expression<String>? workspaceId,
    Expression<String>? deviceId,
    Expression<Uint8List>? identityPublicKey,
    Expression<String>? trustState,
    Expression<int>? maxAllowedOriginSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (deviceId != null) 'device_id': deviceId,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (trustState != null) 'trust_state': trustState,
      if (maxAllowedOriginSeq != null)
        'max_allowed_origin_seq': maxAllowedOriginSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrustedDevicesCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? deviceId,
    Value<Uint8List>? identityPublicKey,
    Value<String>? trustState,
    Value<int?>? maxAllowedOriginSeq,
    Value<int>? rowid,
  }) {
    return TrustedDevicesCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      deviceId: deviceId ?? this.deviceId,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      trustState: trustState ?? this.trustState,
      maxAllowedOriginSeq: maxAllowedOriginSeq ?? this.maxAllowedOriginSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<Uint8List>(identityPublicKey.value);
    }
    if (trustState.present) {
      map['trust_state'] = Variable<String>(trustState.value);
    }
    if (maxAllowedOriginSeq.present) {
      map['max_allowed_origin_seq'] = Variable<int>(maxAllowedOriginSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrustedDevicesCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('deviceId: $deviceId, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('trustState: $trustState, ')
          ..write('maxAllowedOriginSeq: $maxAllowedOriginSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExamProfiles extends Table with TableInfo<ExamProfiles, ExamProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExamProfiles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES workspaces(id)',
  );
  static const VerificationMeta _examNameMeta = const VerificationMeta(
    'examName',
  );
  late final GeneratedColumn<String> examName = GeneratedColumn<String>(
    'exam_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _examDateMeta = const VerificationMeta(
    'examDate',
  );
  late final GeneratedColumn<String> examDate = GeneratedColumn<String>(
    'exam_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _targetSchoolMeta = const VerificationMeta(
    'targetSchool',
  );
  late final GeneratedColumn<String> targetSchool = GeneratedColumn<String>(
    'target_school',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _targetMajorMeta = const VerificationMeta(
    'targetMajor',
  );
  late final GeneratedColumn<String> targetMajor = GeneratedColumn<String>(
    'target_major',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _targetTotalScoreX100Meta =
      const VerificationMeta('targetTotalScoreX100');
  late final GeneratedColumn<int> targetTotalScoreX100 = GeneratedColumn<int>(
    'target_total_score_x100',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (target_total_score_x100 >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    examName,
    examDate,
    targetSchool,
    targetMajor,
    targetTotalScoreX100,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('exam_name')) {
      context.handle(
        _examNameMeta,
        examName.isAcceptableOrUnknown(data['exam_name']!, _examNameMeta),
      );
    }
    if (data.containsKey('exam_date')) {
      context.handle(
        _examDateMeta,
        examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta),
      );
    }
    if (data.containsKey('target_school')) {
      context.handle(
        _targetSchoolMeta,
        targetSchool.isAcceptableOrUnknown(
          data['target_school']!,
          _targetSchoolMeta,
        ),
      );
    }
    if (data.containsKey('target_major')) {
      context.handle(
        _targetMajorMeta,
        targetMajor.isAcceptableOrUnknown(
          data['target_major']!,
          _targetMajorMeta,
        ),
      );
    }
    if (data.containsKey('target_total_score_x100')) {
      context.handle(
        _targetTotalScoreX100Meta,
        targetTotalScoreX100.isAcceptableOrUnknown(
          data['target_total_score_x100']!,
          _targetTotalScoreX100Meta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExamProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      examName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_name'],
      ),
      examDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_date'],
      ),
      targetSchool: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_school'],
      ),
      targetMajor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_major'],
      ),
      targetTotalScoreX100: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_total_score_x100'],
      ),
    );
  }

  @override
  ExamProfiles createAlias(String alias) {
    return ExamProfiles(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ExamProfile extends DataClass implements Insertable<ExamProfile> {
  final String id;
  final String workspaceId;
  final String? examName;
  final String? examDate;
  final String? targetSchool;
  final String? targetMajor;
  final int? targetTotalScoreX100;
  const ExamProfile({
    required this.id,
    required this.workspaceId,
    this.examName,
    this.examDate,
    this.targetSchool,
    this.targetMajor,
    this.targetTotalScoreX100,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || examName != null) {
      map['exam_name'] = Variable<String>(examName);
    }
    if (!nullToAbsent || examDate != null) {
      map['exam_date'] = Variable<String>(examDate);
    }
    if (!nullToAbsent || targetSchool != null) {
      map['target_school'] = Variable<String>(targetSchool);
    }
    if (!nullToAbsent || targetMajor != null) {
      map['target_major'] = Variable<String>(targetMajor);
    }
    if (!nullToAbsent || targetTotalScoreX100 != null) {
      map['target_total_score_x100'] = Variable<int>(targetTotalScoreX100);
    }
    return map;
  }

  ExamProfilesCompanion toCompanion(bool nullToAbsent) {
    return ExamProfilesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      examName: examName == null && nullToAbsent
          ? const Value.absent()
          : Value(examName),
      examDate: examDate == null && nullToAbsent
          ? const Value.absent()
          : Value(examDate),
      targetSchool: targetSchool == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSchool),
      targetMajor: targetMajor == null && nullToAbsent
          ? const Value.absent()
          : Value(targetMajor),
      targetTotalScoreX100: targetTotalScoreX100 == null && nullToAbsent
          ? const Value.absent()
          : Value(targetTotalScoreX100),
    );
  }

  factory ExamProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamProfile(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      examName: serializer.fromJson<String?>(json['exam_name']),
      examDate: serializer.fromJson<String?>(json['exam_date']),
      targetSchool: serializer.fromJson<String?>(json['target_school']),
      targetMajor: serializer.fromJson<String?>(json['target_major']),
      targetTotalScoreX100: serializer.fromJson<int?>(
        json['target_total_score_x100'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'exam_name': serializer.toJson<String?>(examName),
      'exam_date': serializer.toJson<String?>(examDate),
      'target_school': serializer.toJson<String?>(targetSchool),
      'target_major': serializer.toJson<String?>(targetMajor),
      'target_total_score_x100': serializer.toJson<int?>(targetTotalScoreX100),
    };
  }

  ExamProfile copyWith({
    String? id,
    String? workspaceId,
    Value<String?> examName = const Value.absent(),
    Value<String?> examDate = const Value.absent(),
    Value<String?> targetSchool = const Value.absent(),
    Value<String?> targetMajor = const Value.absent(),
    Value<int?> targetTotalScoreX100 = const Value.absent(),
  }) => ExamProfile(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    examName: examName.present ? examName.value : this.examName,
    examDate: examDate.present ? examDate.value : this.examDate,
    targetSchool: targetSchool.present ? targetSchool.value : this.targetSchool,
    targetMajor: targetMajor.present ? targetMajor.value : this.targetMajor,
    targetTotalScoreX100: targetTotalScoreX100.present
        ? targetTotalScoreX100.value
        : this.targetTotalScoreX100,
  );
  ExamProfile copyWithCompanion(ExamProfilesCompanion data) {
    return ExamProfile(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      examName: data.examName.present ? data.examName.value : this.examName,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      targetSchool: data.targetSchool.present
          ? data.targetSchool.value
          : this.targetSchool,
      targetMajor: data.targetMajor.present
          ? data.targetMajor.value
          : this.targetMajor,
      targetTotalScoreX100: data.targetTotalScoreX100.present
          ? data.targetTotalScoreX100.value
          : this.targetTotalScoreX100,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamProfile(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('examName: $examName, ')
          ..write('examDate: $examDate, ')
          ..write('targetSchool: $targetSchool, ')
          ..write('targetMajor: $targetMajor, ')
          ..write('targetTotalScoreX100: $targetTotalScoreX100')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    examName,
    examDate,
    targetSchool,
    targetMajor,
    targetTotalScoreX100,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamProfile &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.examName == this.examName &&
          other.examDate == this.examDate &&
          other.targetSchool == this.targetSchool &&
          other.targetMajor == this.targetMajor &&
          other.targetTotalScoreX100 == this.targetTotalScoreX100);
}

class ExamProfilesCompanion extends UpdateCompanion<ExamProfile> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String?> examName;
  final Value<String?> examDate;
  final Value<String?> targetSchool;
  final Value<String?> targetMajor;
  final Value<int?> targetTotalScoreX100;
  final Value<int> rowid;
  const ExamProfilesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.examName = const Value.absent(),
    this.examDate = const Value.absent(),
    this.targetSchool = const Value.absent(),
    this.targetMajor = const Value.absent(),
    this.targetTotalScoreX100 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamProfilesCompanion.insert({
    required String id,
    required String workspaceId,
    this.examName = const Value.absent(),
    this.examDate = const Value.absent(),
    this.targetSchool = const Value.absent(),
    this.targetMajor = const Value.absent(),
    this.targetTotalScoreX100 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId);
  static Insertable<ExamProfile> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? examName,
    Expression<String>? examDate,
    Expression<String>? targetSchool,
    Expression<String>? targetMajor,
    Expression<int>? targetTotalScoreX100,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (examName != null) 'exam_name': examName,
      if (examDate != null) 'exam_date': examDate,
      if (targetSchool != null) 'target_school': targetSchool,
      if (targetMajor != null) 'target_major': targetMajor,
      if (targetTotalScoreX100 != null)
        'target_total_score_x100': targetTotalScoreX100,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String?>? examName,
    Value<String?>? examDate,
    Value<String?>? targetSchool,
    Value<String?>? targetMajor,
    Value<int?>? targetTotalScoreX100,
    Value<int>? rowid,
  }) {
    return ExamProfilesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      examName: examName ?? this.examName,
      examDate: examDate ?? this.examDate,
      targetSchool: targetSchool ?? this.targetSchool,
      targetMajor: targetMajor ?? this.targetMajor,
      targetTotalScoreX100: targetTotalScoreX100 ?? this.targetTotalScoreX100,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (examName.present) {
      map['exam_name'] = Variable<String>(examName.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<String>(examDate.value);
    }
    if (targetSchool.present) {
      map['target_school'] = Variable<String>(targetSchool.value);
    }
    if (targetMajor.present) {
      map['target_major'] = Variable<String>(targetMajor.value);
    }
    if (targetTotalScoreX100.present) {
      map['target_total_score_x100'] = Variable<int>(
        targetTotalScoreX100.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamProfilesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('examName: $examName, ')
          ..write('examDate: $examDate, ')
          ..write('targetSchool: $targetSchool, ')
          ..write('targetMajor: $targetMajor, ')
          ..write('targetTotalScoreX100: $targetTotalScoreX100, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Subjects extends Table with TableInfo<Subjects, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Subjects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspaces(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _targetScoreX100Meta = const VerificationMeta(
    'targetScoreX100',
  );
  late final GeneratedColumn<int> targetScoreX100 = GeneratedColumn<int>(
    'target_score_x100',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (target_score_x100 >= 0)',
  );
  static const VerificationMeta _maxScoreX100Meta = const VerificationMeta(
    'maxScoreX100',
  );
  late final GeneratedColumn<int> maxScoreX100 = GeneratedColumn<int>(
    'max_score_x100',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (max_score_x100 >= 0)',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    category,
    targetScoreX100,
    maxScoreX100,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('target_score_x100')) {
      context.handle(
        _targetScoreX100Meta,
        targetScoreX100.isAcceptableOrUnknown(
          data['target_score_x100']!,
          _targetScoreX100Meta,
        ),
      );
    }
    if (data.containsKey('max_score_x100')) {
      context.handle(
        _maxScoreX100Meta,
        maxScoreX100.isAcceptableOrUnknown(
          data['max_score_x100']!,
          _maxScoreX100Meta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, id},
  ];
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      targetScoreX100: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_score_x100'],
      ),
      maxScoreX100: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_score_x100'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  Subjects createAlias(String alias) {
    return Subjects(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(workspace_id, id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Subject extends DataClass implements Insertable<Subject> {
  final String id;
  final String workspaceId;
  final String name;
  final String? category;
  final int? targetScoreX100;
  final int? maxScoreX100;
  final int sortOrder;
  final int archived;
  const Subject({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.category,
    this.targetScoreX100,
    this.maxScoreX100,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || targetScoreX100 != null) {
      map['target_score_x100'] = Variable<int>(targetScoreX100);
    }
    if (!nullToAbsent || maxScoreX100 != null) {
      map['max_score_x100'] = Variable<int>(maxScoreX100);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<int>(archived);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      targetScoreX100: targetScoreX100 == null && nullToAbsent
          ? const Value.absent()
          : Value(targetScoreX100),
      maxScoreX100: maxScoreX100 == null && nullToAbsent
          ? const Value.absent()
          : Value(maxScoreX100),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      targetScoreX100: serializer.fromJson<int?>(json['target_score_x100']),
      maxScoreX100: serializer.fromJson<int?>(json['max_score_x100']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      archived: serializer.fromJson<int>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'target_score_x100': serializer.toJson<int?>(targetScoreX100),
      'max_score_x100': serializer.toJson<int?>(maxScoreX100),
      'sort_order': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<int>(archived),
    };
  }

  Subject copyWith({
    String? id,
    String? workspaceId,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<int?> targetScoreX100 = const Value.absent(),
    Value<int?> maxScoreX100 = const Value.absent(),
    int? sortOrder,
    int? archived,
  }) => Subject(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    targetScoreX100: targetScoreX100.present
        ? targetScoreX100.value
        : this.targetScoreX100,
    maxScoreX100: maxScoreX100.present ? maxScoreX100.value : this.maxScoreX100,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      targetScoreX100: data.targetScoreX100.present
          ? data.targetScoreX100.value
          : this.targetScoreX100,
      maxScoreX100: data.maxScoreX100.present
          ? data.maxScoreX100.value
          : this.maxScoreX100,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('targetScoreX100: $targetScoreX100, ')
          ..write('maxScoreX100: $maxScoreX100, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    category,
    targetScoreX100,
    maxScoreX100,
    sortOrder,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.category == this.category &&
          other.targetScoreX100 == this.targetScoreX100 &&
          other.maxScoreX100 == this.maxScoreX100 &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> category;
  final Value<int?> targetScoreX100;
  final Value<int?> maxScoreX100;
  final Value<int> sortOrder;
  final Value<int> archived;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.targetScoreX100 = const Value.absent(),
    this.maxScoreX100 = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    this.category = const Value.absent(),
    this.targetScoreX100 = const Value.absent(),
    this.maxScoreX100 = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name);
  static Insertable<Subject> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? targetScoreX100,
    Expression<int>? maxScoreX100,
    Expression<int>? sortOrder,
    Expression<int>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (targetScoreX100 != null) 'target_score_x100': targetScoreX100,
      if (maxScoreX100 != null) 'max_score_x100': maxScoreX100,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String?>? category,
    Value<int?>? targetScoreX100,
    Value<int?>? maxScoreX100,
    Value<int>? sortOrder,
    Value<int>? archived,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      category: category ?? this.category,
      targetScoreX100: targetScoreX100 ?? this.targetScoreX100,
      maxScoreX100: maxScoreX100 ?? this.maxScoreX100,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (targetScoreX100.present) {
      map['target_score_x100'] = Variable<int>(targetScoreX100.value);
    }
    if (maxScoreX100.present) {
      map['max_score_x100'] = Variable<int>(maxScoreX100.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('targetScoreX100: $targetScoreX100, ')
          ..write('maxScoreX100: $maxScoreX100, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tasks extends Table with TableInfo<Tasks, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tasks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspaces(id)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _knowledgeNodeIdMeta = const VerificationMeta(
    'knowledgeNodeId',
  );
  late final GeneratedColumn<String> knowledgeNodeId = GeneratedColumn<String>(
    'knowledge_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dueAtMsMeta = const VerificationMeta(
    'dueAtMs',
  );
  late final GeneratedColumn<int> dueAtMs = GeneratedColumn<int>(
    'due_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (due_at_ms >= 0)',
  );
  static const VerificationMeta _estimatedSecondsMeta = const VerificationMeta(
    'estimatedSeconds',
  );
  late final GeneratedColumn<int> estimatedSeconds = GeneratedColumn<int>(
    'estimated_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (estimated_seconds >= 0)',
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'todo\', \'doing\', \'completed\', \'cancelled\'))',
  );
  static const VerificationMeta _completedAtMsMeta = const VerificationMeta(
    'completedAtMs',
  );
  late final GeneratedColumn<int> completedAtMs = GeneratedColumn<int>(
    'completed_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (completed_at_ms >= 0)',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    title,
    subjectId,
    knowledgeNodeId,
    scheduledDate,
    dueAtMs,
    estimatedSeconds,
    priority,
    sortOrder,
    status,
    completedAtMs,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('knowledge_node_id')) {
      context.handle(
        _knowledgeNodeIdMeta,
        knowledgeNodeId.isAcceptableOrUnknown(
          data['knowledge_node_id']!,
          _knowledgeNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('due_at_ms')) {
      context.handle(
        _dueAtMsMeta,
        dueAtMs.isAcceptableOrUnknown(data['due_at_ms']!, _dueAtMsMeta),
      );
    }
    if (data.containsKey('estimated_seconds')) {
      context.handle(
        _estimatedSecondsMeta,
        estimatedSeconds.isAcceptableOrUnknown(
          data['estimated_seconds']!,
          _estimatedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('completed_at_ms')) {
      context.handle(
        _completedAtMsMeta,
        completedAtMs.isAcceptableOrUnknown(
          data['completed_at_ms']!,
          _completedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, id},
  ];
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      knowledgeNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_node_id'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      ),
      dueAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at_ms'],
      ),
      estimatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_seconds'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_ms'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  Tasks createAlias(String alias) {
    return Tasks(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(workspace_id, id)',
    'FOREIGN KEY(workspace_id, subject_id)REFERENCES subjects(workspace_id, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String workspaceId;
  final String title;
  final String? subjectId;
  final String? knowledgeNodeId;
  final String? scheduledDate;
  final int? dueAtMs;
  final int? estimatedSeconds;
  final int priority;
  final int sortOrder;
  final String status;
  final int? completedAtMs;
  final String? note;
  const Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.subjectId,
    this.knowledgeNodeId,
    this.scheduledDate,
    this.dueAtMs,
    this.estimatedSeconds,
    required this.priority,
    required this.sortOrder,
    required this.status,
    this.completedAtMs,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || knowledgeNodeId != null) {
      map['knowledge_node_id'] = Variable<String>(knowledgeNodeId);
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<String>(scheduledDate);
    }
    if (!nullToAbsent || dueAtMs != null) {
      map['due_at_ms'] = Variable<int>(dueAtMs);
    }
    if (!nullToAbsent || estimatedSeconds != null) {
      map['estimated_seconds'] = Variable<int>(estimatedSeconds);
    }
    map['priority'] = Variable<int>(priority);
    map['sort_order'] = Variable<int>(sortOrder);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAtMs != null) {
      map['completed_at_ms'] = Variable<int>(completedAtMs);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      knowledgeNodeId: knowledgeNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgeNodeId),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      dueAtMs: dueAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAtMs),
      estimatedSeconds: estimatedSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedSeconds),
      priority: Value(priority),
      sortOrder: Value(sortOrder),
      status: Value(status),
      completedAtMs: completedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtMs),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      title: serializer.fromJson<String>(json['title']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      knowledgeNodeId: serializer.fromJson<String?>(json['knowledge_node_id']),
      scheduledDate: serializer.fromJson<String?>(json['scheduled_date']),
      dueAtMs: serializer.fromJson<int?>(json['due_at_ms']),
      estimatedSeconds: serializer.fromJson<int?>(json['estimated_seconds']),
      priority: serializer.fromJson<int>(json['priority']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      status: serializer.fromJson<String>(json['status']),
      completedAtMs: serializer.fromJson<int?>(json['completed_at_ms']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'subject_id': serializer.toJson<String?>(subjectId),
      'knowledge_node_id': serializer.toJson<String?>(knowledgeNodeId),
      'scheduled_date': serializer.toJson<String?>(scheduledDate),
      'due_at_ms': serializer.toJson<int?>(dueAtMs),
      'estimated_seconds': serializer.toJson<int?>(estimatedSeconds),
      'priority': serializer.toJson<int>(priority),
      'sort_order': serializer.toJson<int>(sortOrder),
      'status': serializer.toJson<String>(status),
      'completed_at_ms': serializer.toJson<int?>(completedAtMs),
      'note': serializer.toJson<String?>(note),
    };
  }

  Task copyWith({
    String? id,
    String? workspaceId,
    String? title,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> knowledgeNodeId = const Value.absent(),
    Value<String?> scheduledDate = const Value.absent(),
    Value<int?> dueAtMs = const Value.absent(),
    Value<int?> estimatedSeconds = const Value.absent(),
    int? priority,
    int? sortOrder,
    String? status,
    Value<int?> completedAtMs = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    knowledgeNodeId: knowledgeNodeId.present
        ? knowledgeNodeId.value
        : this.knowledgeNodeId,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    dueAtMs: dueAtMs.present ? dueAtMs.value : this.dueAtMs,
    estimatedSeconds: estimatedSeconds.present
        ? estimatedSeconds.value
        : this.estimatedSeconds,
    priority: priority ?? this.priority,
    sortOrder: sortOrder ?? this.sortOrder,
    status: status ?? this.status,
    completedAtMs: completedAtMs.present
        ? completedAtMs.value
        : this.completedAtMs,
    note: note.present ? note.value : this.note,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      knowledgeNodeId: data.knowledgeNodeId.present
          ? data.knowledgeNodeId.value
          : this.knowledgeNodeId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      dueAtMs: data.dueAtMs.present ? data.dueAtMs.value : this.dueAtMs,
      estimatedSeconds: data.estimatedSeconds.present
          ? data.estimatedSeconds.value
          : this.estimatedSeconds,
      priority: data.priority.present ? data.priority.value : this.priority,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      status: data.status.present ? data.status.value : this.status,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('knowledgeNodeId: $knowledgeNodeId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('dueAtMs: $dueAtMs, ')
          ..write('estimatedSeconds: $estimatedSeconds, ')
          ..write('priority: $priority, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    subjectId,
    knowledgeNodeId,
    scheduledDate,
    dueAtMs,
    estimatedSeconds,
    priority,
    sortOrder,
    status,
    completedAtMs,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.subjectId == this.subjectId &&
          other.knowledgeNodeId == this.knowledgeNodeId &&
          other.scheduledDate == this.scheduledDate &&
          other.dueAtMs == this.dueAtMs &&
          other.estimatedSeconds == this.estimatedSeconds &&
          other.priority == this.priority &&
          other.sortOrder == this.sortOrder &&
          other.status == this.status &&
          other.completedAtMs == this.completedAtMs &&
          other.note == this.note);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String?> subjectId;
  final Value<String?> knowledgeNodeId;
  final Value<String?> scheduledDate;
  final Value<int?> dueAtMs;
  final Value<int?> estimatedSeconds;
  final Value<int> priority;
  final Value<int> sortOrder;
  final Value<String> status;
  final Value<int?> completedAtMs;
  final Value<String?> note;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.knowledgeNodeId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.dueAtMs = const Value.absent(),
    this.estimatedSeconds = const Value.absent(),
    this.priority = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String workspaceId,
    required String title,
    this.subjectId = const Value.absent(),
    this.knowledgeNodeId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.dueAtMs = const Value.absent(),
    this.estimatedSeconds = const Value.absent(),
    this.priority = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String status,
    this.completedAtMs = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       status = Value(status);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? subjectId,
    Expression<String>? knowledgeNodeId,
    Expression<String>? scheduledDate,
    Expression<int>? dueAtMs,
    Expression<int>? estimatedSeconds,
    Expression<int>? priority,
    Expression<int>? sortOrder,
    Expression<String>? status,
    Expression<int>? completedAtMs,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (subjectId != null) 'subject_id': subjectId,
      if (knowledgeNodeId != null) 'knowledge_node_id': knowledgeNodeId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (dueAtMs != null) 'due_at_ms': dueAtMs,
      if (estimatedSeconds != null) 'estimated_seconds': estimatedSeconds,
      if (priority != null) 'priority': priority,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (status != null) 'status': status,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String?>? subjectId,
    Value<String?>? knowledgeNodeId,
    Value<String?>? scheduledDate,
    Value<int?>? dueAtMs,
    Value<int?>? estimatedSeconds,
    Value<int>? priority,
    Value<int>? sortOrder,
    Value<String>? status,
    Value<int?>? completedAtMs,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dueAtMs: dueAtMs ?? this.dueAtMs,
      estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
      priority: priority ?? this.priority,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (knowledgeNodeId.present) {
      map['knowledge_node_id'] = Variable<String>(knowledgeNodeId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (dueAtMs.present) {
      map['due_at_ms'] = Variable<int>(dueAtMs.value);
    }
    if (estimatedSeconds.present) {
      map['estimated_seconds'] = Variable<int>(estimatedSeconds.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('knowledgeNodeId: $knowledgeNodeId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('dueAtMs: $dueAtMs, ')
          ..write('estimatedSeconds: $estimatedSeconds, ')
          ..write('priority: $priority, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DailyReviews extends Table with TableInfo<DailyReviews, DailyReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DailyReviews(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspaces(id)',
  );
  static const VerificationMeta _reviewDateMeta = const VerificationMeta(
    'reviewDate',
  );
  late final GeneratedColumn<String> reviewDate = GeneratedColumn<String>(
    'review_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, workspaceId, reviewDate, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('review_date')) {
      context.handle(
        _reviewDateMeta,
        reviewDate.isAcceptableOrUnknown(data['review_date']!, _reviewDateMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewDateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, reviewDate},
  ];
  @override
  DailyReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      reviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_date'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  DailyReviews createAlias(String alias) {
    return DailyReviews(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(workspace_id, review_date)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DailyReview extends DataClass implements Insertable<DailyReview> {
  final String id;
  final String workspaceId;
  final String reviewDate;
  final String content;
  const DailyReview({
    required this.id,
    required this.workspaceId,
    required this.reviewDate,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['review_date'] = Variable<String>(reviewDate);
    map['content'] = Variable<String>(content);
    return map;
  }

  DailyReviewsCompanion toCompanion(bool nullToAbsent) {
    return DailyReviewsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      reviewDate: Value(reviewDate),
      content: Value(content),
    );
  }

  factory DailyReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReview(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      reviewDate: serializer.fromJson<String>(json['review_date']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'review_date': serializer.toJson<String>(reviewDate),
      'content': serializer.toJson<String>(content),
    };
  }

  DailyReview copyWith({
    String? id,
    String? workspaceId,
    String? reviewDate,
    String? content,
  }) => DailyReview(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    reviewDate: reviewDate ?? this.reviewDate,
    content: content ?? this.content,
  );
  DailyReview copyWithCompanion(DailyReviewsCompanion data) {
    return DailyReview(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      reviewDate: data.reviewDate.present
          ? data.reviewDate.value
          : this.reviewDate,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReview(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workspaceId, reviewDate, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReview &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.reviewDate == this.reviewDate &&
          other.content == this.content);
}

class DailyReviewsCompanion extends UpdateCompanion<DailyReview> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> reviewDate;
  final Value<String> content;
  final Value<int> rowid;
  const DailyReviewsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReviewsCompanion.insert({
    required String id,
    required String workspaceId,
    required String reviewDate,
    required String content,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       reviewDate = Value(reviewDate),
       content = Value(content);
  static Insertable<DailyReview> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? reviewDate,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (reviewDate != null) 'review_date': reviewDate,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? reviewDate,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return DailyReviewsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      reviewDate: reviewDate ?? this.reviewDate,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (reviewDate.present) {
      map['review_date'] = Variable<String>(reviewDate.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReviewsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StudySessions extends Table with TableInfo<StudySessions, StudySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StudySessions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspaces(id)',
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _knowledgeNodeIdMeta = const VerificationMeta(
    'knowledgeNodeId',
  );
  late final GeneratedColumn<String> knowledgeNodeId = GeneratedColumn<String>(
    'knowledge_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ownerDeviceIdMeta = const VerificationMeta(
    'ownerDeviceId',
  );
  late final GeneratedColumn<String> ownerDeviceId = GeneratedColumn<String>(
    'owner_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'active\', \'paused\', \'completed\'))',
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (started_at_ms >= 0)',
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (mode IN (\'stopwatch\', \'pomodoro\'))',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    subjectId,
    taskId,
    knowledgeNodeId,
    ownerDeviceId,
    status,
    startedAtMs,
    endedAtMs,
    mode,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('knowledge_node_id')) {
      context.handle(
        _knowledgeNodeIdMeta,
        knowledgeNodeId.isAcceptableOrUnknown(
          data['knowledge_node_id']!,
          _knowledgeNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('owner_device_id')) {
      context.handle(
        _ownerDeviceIdMeta,
        ownerDeviceId.isAcceptableOrUnknown(
          data['owner_device_id']!,
          _ownerDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerDeviceIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, id},
  ];
  @override
  StudySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      knowledgeNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_node_id'],
      ),
      ownerDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_device_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  StudySessions createAlias(String alias) {
    return StudySessions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((status = \'completed\' AND ended_at_ms IS NOT NULL AND ended_at_ms >= started_at_ms)OR(status <> \'completed\' AND ended_at_ms IS NULL))',
    'UNIQUE(workspace_id, id)',
    'FOREIGN KEY(workspace_id, subject_id)REFERENCES subjects(workspace_id, id)',
    'FOREIGN KEY(workspace_id, task_id)REFERENCES tasks(workspace_id, id)',
    'FOREIGN KEY(workspace_id, owner_device_id)REFERENCES trusted_devices(workspace_id, device_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class StudySession extends DataClass implements Insertable<StudySession> {
  final String id;
  final String workspaceId;
  final String subjectId;
  final String? taskId;
  final String? knowledgeNodeId;
  final String ownerDeviceId;
  final String status;
  final int startedAtMs;
  final int? endedAtMs;
  final String mode;
  final String? note;
  const StudySession({
    required this.id,
    required this.workspaceId,
    required this.subjectId,
    this.taskId,
    this.knowledgeNodeId,
    required this.ownerDeviceId,
    required this.status,
    required this.startedAtMs,
    this.endedAtMs,
    required this.mode,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || knowledgeNodeId != null) {
      map['knowledge_node_id'] = Variable<String>(knowledgeNodeId);
    }
    map['owner_device_id'] = Variable<String>(ownerDeviceId);
    map['status'] = Variable<String>(status);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  StudySessionsCompanion toCompanion(bool nullToAbsent) {
    return StudySessionsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      subjectId: Value(subjectId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      knowledgeNodeId: knowledgeNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgeNodeId),
      ownerDeviceId: Value(ownerDeviceId),
      status: Value(status),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
      mode: Value(mode),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory StudySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySession(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      subjectId: serializer.fromJson<String>(json['subject_id']),
      taskId: serializer.fromJson<String?>(json['task_id']),
      knowledgeNodeId: serializer.fromJson<String?>(json['knowledge_node_id']),
      ownerDeviceId: serializer.fromJson<String>(json['owner_device_id']),
      status: serializer.fromJson<String>(json['status']),
      startedAtMs: serializer.fromJson<int>(json['started_at_ms']),
      endedAtMs: serializer.fromJson<int?>(json['ended_at_ms']),
      mode: serializer.fromJson<String>(json['mode']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'subject_id': serializer.toJson<String>(subjectId),
      'task_id': serializer.toJson<String?>(taskId),
      'knowledge_node_id': serializer.toJson<String?>(knowledgeNodeId),
      'owner_device_id': serializer.toJson<String>(ownerDeviceId),
      'status': serializer.toJson<String>(status),
      'started_at_ms': serializer.toJson<int>(startedAtMs),
      'ended_at_ms': serializer.toJson<int?>(endedAtMs),
      'mode': serializer.toJson<String>(mode),
      'note': serializer.toJson<String?>(note),
    };
  }

  StudySession copyWith({
    String? id,
    String? workspaceId,
    String? subjectId,
    Value<String?> taskId = const Value.absent(),
    Value<String?> knowledgeNodeId = const Value.absent(),
    String? ownerDeviceId,
    String? status,
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
    String? mode,
    Value<String?> note = const Value.absent(),
  }) => StudySession(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    subjectId: subjectId ?? this.subjectId,
    taskId: taskId.present ? taskId.value : this.taskId,
    knowledgeNodeId: knowledgeNodeId.present
        ? knowledgeNodeId.value
        : this.knowledgeNodeId,
    ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
    status: status ?? this.status,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
    mode: mode ?? this.mode,
    note: note.present ? note.value : this.note,
  );
  StudySession copyWithCompanion(StudySessionsCompanion data) {
    return StudySession(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      knowledgeNodeId: data.knowledgeNodeId.present
          ? data.knowledgeNodeId.value
          : this.knowledgeNodeId,
      ownerDeviceId: data.ownerDeviceId.present
          ? data.ownerDeviceId.value
          : this.ownerDeviceId,
      status: data.status.present ? data.status.value : this.status,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
      mode: data.mode.present ? data.mode.value : this.mode,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySession(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('subjectId: $subjectId, ')
          ..write('taskId: $taskId, ')
          ..write('knowledgeNodeId: $knowledgeNodeId, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('status: $status, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('mode: $mode, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    subjectId,
    taskId,
    knowledgeNodeId,
    ownerDeviceId,
    status,
    startedAtMs,
    endedAtMs,
    mode,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySession &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.subjectId == this.subjectId &&
          other.taskId == this.taskId &&
          other.knowledgeNodeId == this.knowledgeNodeId &&
          other.ownerDeviceId == this.ownerDeviceId &&
          other.status == this.status &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs &&
          other.mode == this.mode &&
          other.note == this.note);
}

class StudySessionsCompanion extends UpdateCompanion<StudySession> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> subjectId;
  final Value<String?> taskId;
  final Value<String?> knowledgeNodeId;
  final Value<String> ownerDeviceId;
  final Value<String> status;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<String> mode;
  final Value<String?> note;
  final Value<int> rowid;
  const StudySessionsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.knowledgeNodeId = const Value.absent(),
    this.ownerDeviceId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.mode = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySessionsCompanion.insert({
    required String id,
    required String workspaceId,
    required String subjectId,
    this.taskId = const Value.absent(),
    this.knowledgeNodeId = const Value.absent(),
    required String ownerDeviceId,
    required String status,
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
    required String mode,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       subjectId = Value(subjectId),
       ownerDeviceId = Value(ownerDeviceId),
       status = Value(status),
       startedAtMs = Value(startedAtMs),
       mode = Value(mode);
  static Insertable<StudySession> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? subjectId,
    Expression<String>? taskId,
    Expression<String>? knowledgeNodeId,
    Expression<String>? ownerDeviceId,
    Expression<String>? status,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<String>? mode,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (subjectId != null) 'subject_id': subjectId,
      if (taskId != null) 'task_id': taskId,
      if (knowledgeNodeId != null) 'knowledge_node_id': knowledgeNodeId,
      if (ownerDeviceId != null) 'owner_device_id': ownerDeviceId,
      if (status != null) 'status': status,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (mode != null) 'mode': mode,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? subjectId,
    Value<String?>? taskId,
    Value<String?>? knowledgeNodeId,
    Value<String>? ownerDeviceId,
    Value<String>? status,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<String>? mode,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return StudySessionsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      subjectId: subjectId ?? this.subjectId,
      taskId: taskId ?? this.taskId,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      status: status ?? this.status,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      mode: mode ?? this.mode,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (knowledgeNodeId.present) {
      map['knowledge_node_id'] = Variable<String>(knowledgeNodeId.value);
    }
    if (ownerDeviceId.present) {
      map['owner_device_id'] = Variable<String>(ownerDeviceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('subjectId: $subjectId, ')
          ..write('taskId: $taskId, ')
          ..write('knowledgeNodeId: $knowledgeNodeId, ')
          ..write('ownerDeviceId: $ownerDeviceId, ')
          ..write('status: $status, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('mode: $mode, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StudySessionSegments extends Table
    with TableInfo<StudySessionSegments, StudySessionSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StudySessionSegments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (started_at_ms >= 0)',
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (ended_at_ms >= started_at_ms)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    sessionId,
    startedAtMs,
    endedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_session_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySessionSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySessionSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySessionSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
    );
  }

  @override
  StudySessionSegments createAlias(String alias) {
    return StudySessionSegments(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(workspace_id, session_id)REFERENCES study_sessions(workspace_id, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class StudySessionSegment extends DataClass
    implements Insertable<StudySessionSegment> {
  final String id;
  final String workspaceId;
  final String sessionId;
  final int startedAtMs;
  final int? endedAtMs;
  const StudySessionSegment({
    required this.id,
    required this.workspaceId,
    required this.sessionId,
    required this.startedAtMs,
    this.endedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['session_id'] = Variable<String>(sessionId);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    return map;
  }

  StudySessionSegmentsCompanion toCompanion(bool nullToAbsent) {
    return StudySessionSegmentsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      sessionId: Value(sessionId),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
    );
  }

  factory StudySessionSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySessionSegment(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      startedAtMs: serializer.fromJson<int>(json['started_at_ms']),
      endedAtMs: serializer.fromJson<int?>(json['ended_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'session_id': serializer.toJson<String>(sessionId),
      'started_at_ms': serializer.toJson<int>(startedAtMs),
      'ended_at_ms': serializer.toJson<int?>(endedAtMs),
    };
  }

  StudySessionSegment copyWith({
    String? id,
    String? workspaceId,
    String? sessionId,
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
  }) => StudySessionSegment(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    sessionId: sessionId ?? this.sessionId,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
  );
  StudySessionSegment copyWithCompanion(StudySessionSegmentsCompanion data) {
    return StudySessionSegment(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionSegment(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, sessionId, startedAtMs, endedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySessionSegment &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.sessionId == this.sessionId &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs);
}

class StudySessionSegmentsCompanion
    extends UpdateCompanion<StudySessionSegment> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> sessionId;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<int> rowid;
  const StudySessionSegmentsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySessionSegmentsCompanion.insert({
    required String id,
    required String workspaceId,
    required String sessionId,
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       sessionId = Value(sessionId),
       startedAtMs = Value(startedAtMs);
  static Insertable<StudySessionSegment> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? sessionId,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (sessionId != null) 'session_id': sessionId,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySessionSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? sessionId,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<int>? rowid,
  }) {
    return StudySessionSegmentsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      sessionId: sessionId ?? this.sessionId,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SessionDuration extends DataClass {
  final String workspaceId;
  final String sessionId;
  final int? durationMs;
  const SessionDuration({
    required this.workspaceId,
    required this.sessionId,
    this.durationMs,
  });
  factory SessionDuration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionDuration(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      durationMs: serializer.fromJson<int?>(json['duration_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'session_id': serializer.toJson<String>(sessionId),
      'duration_ms': serializer.toJson<int?>(durationMs),
    };
  }

  SessionDuration copyWith({
    String? workspaceId,
    String? sessionId,
    Value<int?> durationMs = const Value.absent(),
  }) => SessionDuration(
    workspaceId: workspaceId ?? this.workspaceId,
    sessionId: sessionId ?? this.sessionId,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
  );
  @override
  String toString() {
    return (StringBuffer('SessionDuration(')
          ..write('workspaceId: $workspaceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workspaceId, sessionId, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionDuration &&
          other.workspaceId == this.workspaceId &&
          other.sessionId == this.sessionId &&
          other.durationMs == this.durationMs);
}

class SessionDurations extends ViewInfo<SessionDurations, SessionDuration>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  SessionDurations(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [workspaceId, sessionId, durationMs];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'session_durations';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW session_durations AS SELECT workspace_id, session_id, SUM(COALESCE(ended_at_ms - started_at_ms, 0)) AS duration_ms FROM study_session_segments GROUP BY workspace_id, session_id',
  };
  @override
  SessionDurations get asDslTable => this;
  @override
  SessionDuration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionDuration(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
    );
  }

  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  @override
  SessionDurations createAlias(String alias) {
    return SessionDurations(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'study_session_segments',
    'study_sessions',
    'workspaces',
    'subjects',
    'tasks',
    'trusted_devices',
  };
}

class EntityFieldClock extends Table
    with TableInfo<EntityFieldClock, EntityFieldClockData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntityFieldClock(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _winnerOpIdMeta = const VerificationMeta(
    'winnerOpId',
  );
  late final GeneratedColumn<String> winnerOpId = GeneratedColumn<String>(
    'winner_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES oplog(op_id)',
  );
  static const VerificationMeta _hlcWallMsMeta = const VerificationMeta(
    'hlcWallMs',
  );
  late final GeneratedColumn<int> hlcWallMs = GeneratedColumn<int>(
    'hlc_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hlcCounterMeta = const VerificationMeta(
    'hlcCounter',
  );
  late final GeneratedColumn<int> hlcCounter = GeneratedColumn<int>(
    'hlc_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originSeqMeta = const VerificationMeta(
    'originSeq',
  );
  late final GeneratedColumn<int> originSeq = GeneratedColumn<int>(
    'origin_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valueBytesMeta = const VerificationMeta(
    'valueBytes',
  );
  late final GeneratedColumn<Uint8List> valueBytes = GeneratedColumn<Uint8List>(
    'value_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    entityType,
    entityId,
    fieldName,
    winnerOpId,
    hlcWallMs,
    hlcCounter,
    originDeviceId,
    originSeq,
    valueBytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_field_clock';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityFieldClockData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('winner_op_id')) {
      context.handle(
        _winnerOpIdMeta,
        winnerOpId.isAcceptableOrUnknown(
          data['winner_op_id']!,
          _winnerOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_winnerOpIdMeta);
    }
    if (data.containsKey('hlc_wall_ms')) {
      context.handle(
        _hlcWallMsMeta,
        hlcWallMs.isAcceptableOrUnknown(data['hlc_wall_ms']!, _hlcWallMsMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcWallMsMeta);
    }
    if (data.containsKey('hlc_counter')) {
      context.handle(
        _hlcCounterMeta,
        hlcCounter.isAcceptableOrUnknown(data['hlc_counter']!, _hlcCounterMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcCounterMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('origin_seq')) {
      context.handle(
        _originSeqMeta,
        originSeq.isAcceptableOrUnknown(data['origin_seq']!, _originSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_originSeqMeta);
    }
    if (data.containsKey('value_bytes')) {
      context.handle(
        _valueBytesMeta,
        valueBytes.isAcceptableOrUnknown(data['value_bytes']!, _valueBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_valueBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    workspaceId,
    entityType,
    entityId,
    fieldName,
  };
  @override
  EntityFieldClockData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityFieldClockData(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      winnerOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_op_id'],
      )!,
      hlcWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_wall_ms'],
      )!,
      hlcCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_counter'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      originSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_seq'],
      )!,
      valueBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}value_bytes'],
      )!,
    );
  }

  @override
  EntityFieldClock createAlias(String alias) {
    return EntityFieldClock(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, entity_type, entity_id, field_name)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class EntityFieldClockData extends DataClass
    implements Insertable<EntityFieldClockData> {
  final String workspaceId;
  final String entityType;
  final String entityId;
  final String fieldName;
  final String winnerOpId;
  final int hlcWallMs;
  final int hlcCounter;
  final String originDeviceId;
  final int originSeq;
  final Uint8List valueBytes;
  const EntityFieldClockData({
    required this.workspaceId,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.winnerOpId,
    required this.hlcWallMs,
    required this.hlcCounter,
    required this.originDeviceId,
    required this.originSeq,
    required this.valueBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['field_name'] = Variable<String>(fieldName);
    map['winner_op_id'] = Variable<String>(winnerOpId);
    map['hlc_wall_ms'] = Variable<int>(hlcWallMs);
    map['hlc_counter'] = Variable<int>(hlcCounter);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['origin_seq'] = Variable<int>(originSeq);
    map['value_bytes'] = Variable<Uint8List>(valueBytes);
    return map;
  }

  EntityFieldClockCompanion toCompanion(bool nullToAbsent) {
    return EntityFieldClockCompanion(
      workspaceId: Value(workspaceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      fieldName: Value(fieldName),
      winnerOpId: Value(winnerOpId),
      hlcWallMs: Value(hlcWallMs),
      hlcCounter: Value(hlcCounter),
      originDeviceId: Value(originDeviceId),
      originSeq: Value(originSeq),
      valueBytes: Value(valueBytes),
    );
  }

  factory EntityFieldClockData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityFieldClockData(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      fieldName: serializer.fromJson<String>(json['field_name']),
      winnerOpId: serializer.fromJson<String>(json['winner_op_id']),
      hlcWallMs: serializer.fromJson<int>(json['hlc_wall_ms']),
      hlcCounter: serializer.fromJson<int>(json['hlc_counter']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      originSeq: serializer.fromJson<int>(json['origin_seq']),
      valueBytes: serializer.fromJson<Uint8List>(json['value_bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'field_name': serializer.toJson<String>(fieldName),
      'winner_op_id': serializer.toJson<String>(winnerOpId),
      'hlc_wall_ms': serializer.toJson<int>(hlcWallMs),
      'hlc_counter': serializer.toJson<int>(hlcCounter),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'origin_seq': serializer.toJson<int>(originSeq),
      'value_bytes': serializer.toJson<Uint8List>(valueBytes),
    };
  }

  EntityFieldClockData copyWith({
    String? workspaceId,
    String? entityType,
    String? entityId,
    String? fieldName,
    String? winnerOpId,
    int? hlcWallMs,
    int? hlcCounter,
    String? originDeviceId,
    int? originSeq,
    Uint8List? valueBytes,
  }) => EntityFieldClockData(
    workspaceId: workspaceId ?? this.workspaceId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    fieldName: fieldName ?? this.fieldName,
    winnerOpId: winnerOpId ?? this.winnerOpId,
    hlcWallMs: hlcWallMs ?? this.hlcWallMs,
    hlcCounter: hlcCounter ?? this.hlcCounter,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    originSeq: originSeq ?? this.originSeq,
    valueBytes: valueBytes ?? this.valueBytes,
  );
  EntityFieldClockData copyWithCompanion(EntityFieldClockCompanion data) {
    return EntityFieldClockData(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      winnerOpId: data.winnerOpId.present
          ? data.winnerOpId.value
          : this.winnerOpId,
      hlcWallMs: data.hlcWallMs.present ? data.hlcWallMs.value : this.hlcWallMs,
      hlcCounter: data.hlcCounter.present
          ? data.hlcCounter.value
          : this.hlcCounter,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      originSeq: data.originSeq.present ? data.originSeq.value : this.originSeq,
      valueBytes: data.valueBytes.present
          ? data.valueBytes.value
          : this.valueBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityFieldClockData(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldName: $fieldName, ')
          ..write('winnerOpId: $winnerOpId, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('valueBytes: $valueBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    entityType,
    entityId,
    fieldName,
    winnerOpId,
    hlcWallMs,
    hlcCounter,
    originDeviceId,
    originSeq,
    $driftBlobEquality.hash(valueBytes),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityFieldClockData &&
          other.workspaceId == this.workspaceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.fieldName == this.fieldName &&
          other.winnerOpId == this.winnerOpId &&
          other.hlcWallMs == this.hlcWallMs &&
          other.hlcCounter == this.hlcCounter &&
          other.originDeviceId == this.originDeviceId &&
          other.originSeq == this.originSeq &&
          $driftBlobEquality.equals(other.valueBytes, this.valueBytes));
}

class EntityFieldClockCompanion extends UpdateCompanion<EntityFieldClockData> {
  final Value<String> workspaceId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> fieldName;
  final Value<String> winnerOpId;
  final Value<int> hlcWallMs;
  final Value<int> hlcCounter;
  final Value<String> originDeviceId;
  final Value<int> originSeq;
  final Value<Uint8List> valueBytes;
  final Value<int> rowid;
  const EntityFieldClockCompanion({
    this.workspaceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.winnerOpId = const Value.absent(),
    this.hlcWallMs = const Value.absent(),
    this.hlcCounter = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.originSeq = const Value.absent(),
    this.valueBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntityFieldClockCompanion.insert({
    required String workspaceId,
    required String entityType,
    required String entityId,
    required String fieldName,
    required String winnerOpId,
    required int hlcWallMs,
    required int hlcCounter,
    required String originDeviceId,
    required int originSeq,
    required Uint8List valueBytes,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       fieldName = Value(fieldName),
       winnerOpId = Value(winnerOpId),
       hlcWallMs = Value(hlcWallMs),
       hlcCounter = Value(hlcCounter),
       originDeviceId = Value(originDeviceId),
       originSeq = Value(originSeq),
       valueBytes = Value(valueBytes);
  static Insertable<EntityFieldClockData> custom({
    Expression<String>? workspaceId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? fieldName,
    Expression<String>? winnerOpId,
    Expression<int>? hlcWallMs,
    Expression<int>? hlcCounter,
    Expression<String>? originDeviceId,
    Expression<int>? originSeq,
    Expression<Uint8List>? valueBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (fieldName != null) 'field_name': fieldName,
      if (winnerOpId != null) 'winner_op_id': winnerOpId,
      if (hlcWallMs != null) 'hlc_wall_ms': hlcWallMs,
      if (hlcCounter != null) 'hlc_counter': hlcCounter,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (originSeq != null) 'origin_seq': originSeq,
      if (valueBytes != null) 'value_bytes': valueBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntityFieldClockCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? fieldName,
    Value<String>? winnerOpId,
    Value<int>? hlcWallMs,
    Value<int>? hlcCounter,
    Value<String>? originDeviceId,
    Value<int>? originSeq,
    Value<Uint8List>? valueBytes,
    Value<int>? rowid,
  }) {
    return EntityFieldClockCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fieldName: fieldName ?? this.fieldName,
      winnerOpId: winnerOpId ?? this.winnerOpId,
      hlcWallMs: hlcWallMs ?? this.hlcWallMs,
      hlcCounter: hlcCounter ?? this.hlcCounter,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      originSeq: originSeq ?? this.originSeq,
      valueBytes: valueBytes ?? this.valueBytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (winnerOpId.present) {
      map['winner_op_id'] = Variable<String>(winnerOpId.value);
    }
    if (hlcWallMs.present) {
      map['hlc_wall_ms'] = Variable<int>(hlcWallMs.value);
    }
    if (hlcCounter.present) {
      map['hlc_counter'] = Variable<int>(hlcCounter.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (originSeq.present) {
      map['origin_seq'] = Variable<int>(originSeq.value);
    }
    if (valueBytes.present) {
      map['value_bytes'] = Variable<Uint8List>(valueBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntityFieldClockCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldName: $fieldName, ')
          ..write('winnerOpId: $winnerOpId, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('valueBytes: $valueBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tombstones extends Table with TableInfo<Tombstones, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tombstones(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (entity_type <> \'daily_review\')',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deleteOpIdMeta = const VerificationMeta(
    'deleteOpId',
  );
  late final GeneratedColumn<String> deleteOpId = GeneratedColumn<String>(
    'delete_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES oplog(op_id)',
  );
  static const VerificationMeta _hlcWallMsMeta = const VerificationMeta(
    'hlcWallMs',
  );
  late final GeneratedColumn<int> hlcWallMs = GeneratedColumn<int>(
    'hlc_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hlcCounterMeta = const VerificationMeta(
    'hlcCounter',
  );
  late final GeneratedColumn<int> hlcCounter = GeneratedColumn<int>(
    'hlc_counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originSeqMeta = const VerificationMeta(
    'originSeq',
  );
  late final GeneratedColumn<int> originSeq = GeneratedColumn<int>(
    'origin_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    entityType,
    entityId,
    deleteOpId,
    hlcWallMs,
    hlcCounter,
    originDeviceId,
    originSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('delete_op_id')) {
      context.handle(
        _deleteOpIdMeta,
        deleteOpId.isAcceptableOrUnknown(
          data['delete_op_id']!,
          _deleteOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deleteOpIdMeta);
    }
    if (data.containsKey('hlc_wall_ms')) {
      context.handle(
        _hlcWallMsMeta,
        hlcWallMs.isAcceptableOrUnknown(data['hlc_wall_ms']!, _hlcWallMsMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcWallMsMeta);
    }
    if (data.containsKey('hlc_counter')) {
      context.handle(
        _hlcCounterMeta,
        hlcCounter.isAcceptableOrUnknown(data['hlc_counter']!, _hlcCounterMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcCounterMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('origin_seq')) {
      context.handle(
        _originSeqMeta,
        originSeq.isAcceptableOrUnknown(data['origin_seq']!, _originSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_originSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, entityType, entityId};
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      deleteOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delete_op_id'],
      )!,
      hlcWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_wall_ms'],
      )!,
      hlcCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_counter'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      originSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_seq'],
      )!,
    );
  }

  @override
  Tombstones createAlias(String alias) {
    return Tombstones(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, entity_type, entity_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  final String workspaceId;
  final String entityType;
  final String entityId;
  final String deleteOpId;
  final int hlcWallMs;
  final int hlcCounter;
  final String originDeviceId;
  final int originSeq;
  const Tombstone({
    required this.workspaceId,
    required this.entityType,
    required this.entityId,
    required this.deleteOpId,
    required this.hlcWallMs,
    required this.hlcCounter,
    required this.originDeviceId,
    required this.originSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['delete_op_id'] = Variable<String>(deleteOpId);
    map['hlc_wall_ms'] = Variable<int>(hlcWallMs);
    map['hlc_counter'] = Variable<int>(hlcCounter);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['origin_seq'] = Variable<int>(originSeq);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      workspaceId: Value(workspaceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      deleteOpId: Value(deleteOpId),
      hlcWallMs: Value(hlcWallMs),
      hlcCounter: Value(hlcCounter),
      originDeviceId: Value(originDeviceId),
      originSeq: Value(originSeq),
    );
  }

  factory Tombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      deleteOpId: serializer.fromJson<String>(json['delete_op_id']),
      hlcWallMs: serializer.fromJson<int>(json['hlc_wall_ms']),
      hlcCounter: serializer.fromJson<int>(json['hlc_counter']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      originSeq: serializer.fromJson<int>(json['origin_seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'delete_op_id': serializer.toJson<String>(deleteOpId),
      'hlc_wall_ms': serializer.toJson<int>(hlcWallMs),
      'hlc_counter': serializer.toJson<int>(hlcCounter),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'origin_seq': serializer.toJson<int>(originSeq),
    };
  }

  Tombstone copyWith({
    String? workspaceId,
    String? entityType,
    String? entityId,
    String? deleteOpId,
    int? hlcWallMs,
    int? hlcCounter,
    String? originDeviceId,
    int? originSeq,
  }) => Tombstone(
    workspaceId: workspaceId ?? this.workspaceId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    deleteOpId: deleteOpId ?? this.deleteOpId,
    hlcWallMs: hlcWallMs ?? this.hlcWallMs,
    hlcCounter: hlcCounter ?? this.hlcCounter,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    originSeq: originSeq ?? this.originSeq,
  );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deleteOpId: data.deleteOpId.present
          ? data.deleteOpId.value
          : this.deleteOpId,
      hlcWallMs: data.hlcWallMs.present ? data.hlcWallMs.value : this.hlcWallMs,
      hlcCounter: data.hlcCounter.present
          ? data.hlcCounter.value
          : this.hlcCounter,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      originSeq: data.originSeq.present ? data.originSeq.value : this.originSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deleteOpId: $deleteOpId, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    entityType,
    entityId,
    deleteOpId,
    hlcWallMs,
    hlcCounter,
    originDeviceId,
    originSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.workspaceId == this.workspaceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.deleteOpId == this.deleteOpId &&
          other.hlcWallMs == this.hlcWallMs &&
          other.hlcCounter == this.hlcCounter &&
          other.originDeviceId == this.originDeviceId &&
          other.originSeq == this.originSeq);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> workspaceId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> deleteOpId;
  final Value<int> hlcWallMs;
  final Value<int> hlcCounter;
  final Value<String> originDeviceId;
  final Value<int> originSeq;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.workspaceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deleteOpId = const Value.absent(),
    this.hlcWallMs = const Value.absent(),
    this.hlcCounter = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.originSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String workspaceId,
    required String entityType,
    required String entityId,
    required String deleteOpId,
    required int hlcWallMs,
    required int hlcCounter,
    required String originDeviceId,
    required int originSeq,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       deleteOpId = Value(deleteOpId),
       hlcWallMs = Value(hlcWallMs),
       hlcCounter = Value(hlcCounter),
       originDeviceId = Value(originDeviceId),
       originSeq = Value(originSeq);
  static Insertable<Tombstone> custom({
    Expression<String>? workspaceId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? deleteOpId,
    Expression<int>? hlcWallMs,
    Expression<int>? hlcCounter,
    Expression<String>? originDeviceId,
    Expression<int>? originSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (deleteOpId != null) 'delete_op_id': deleteOpId,
      if (hlcWallMs != null) 'hlc_wall_ms': hlcWallMs,
      if (hlcCounter != null) 'hlc_counter': hlcCounter,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (originSeq != null) 'origin_seq': originSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? deleteOpId,
    Value<int>? hlcWallMs,
    Value<int>? hlcCounter,
    Value<String>? originDeviceId,
    Value<int>? originSeq,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      deleteOpId: deleteOpId ?? this.deleteOpId,
      hlcWallMs: hlcWallMs ?? this.hlcWallMs,
      hlcCounter: hlcCounter ?? this.hlcCounter,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      originSeq: originSeq ?? this.originSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deleteOpId.present) {
      map['delete_op_id'] = Variable<String>(deleteOpId.value);
    }
    if (hlcWallMs.present) {
      map['hlc_wall_ms'] = Variable<int>(hlcWallMs.value);
    }
    if (hlcCounter.present) {
      map['hlc_counter'] = Variable<int>(hlcCounter.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (originSeq.present) {
      map['origin_seq'] = Variable<int>(originSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deleteOpId: $deleteOpId, ')
          ..write('hlcWallMs: $hlcWallMs, ')
          ..write('hlcCounter: $hlcCounter, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TextFieldVersions extends Table
    with TableInfo<TextFieldVersions, TextFieldVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TextFieldVersions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES oplog(op_id)',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originSeqMeta = const VerificationMeta(
    'originSeq',
  );
  late final GeneratedColumn<int> originSeq = GeneratedColumn<int>(
    'origin_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (is_active = 1)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    entityType,
    entityId,
    fieldName,
    opId,
    originDeviceId,
    originSeq,
    value,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'text_field_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TextFieldVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('origin_seq')) {
      context.handle(
        _originSeqMeta,
        originSeq.isAcceptableOrUnknown(data['origin_seq']!, _originSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_originSeqMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    workspaceId,
    entityType,
    entityId,
    fieldName,
    opId,
  };
  @override
  TextFieldVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TextFieldVersion(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      originSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_seq'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  TextFieldVersions createAlias(String alias) {
    return TextFieldVersions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, entity_type, entity_id, field_name, op_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TextFieldVersion extends DataClass
    implements Insertable<TextFieldVersion> {
  final String workspaceId;
  final String entityType;
  final String entityId;
  final String fieldName;
  final String opId;
  final String originDeviceId;
  final int originSeq;
  final String value;
  final int isActive;
  const TextFieldVersion({
    required this.workspaceId,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.opId,
    required this.originDeviceId,
    required this.originSeq,
    required this.value,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['field_name'] = Variable<String>(fieldName);
    map['op_id'] = Variable<String>(opId);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['origin_seq'] = Variable<int>(originSeq);
    map['value'] = Variable<String>(value);
    map['is_active'] = Variable<int>(isActive);
    return map;
  }

  TextFieldVersionsCompanion toCompanion(bool nullToAbsent) {
    return TextFieldVersionsCompanion(
      workspaceId: Value(workspaceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      fieldName: Value(fieldName),
      opId: Value(opId),
      originDeviceId: Value(originDeviceId),
      originSeq: Value(originSeq),
      value: Value(value),
      isActive: Value(isActive),
    );
  }

  factory TextFieldVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextFieldVersion(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      fieldName: serializer.fromJson<String>(json['field_name']),
      opId: serializer.fromJson<String>(json['op_id']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      originSeq: serializer.fromJson<int>(json['origin_seq']),
      value: serializer.fromJson<String>(json['value']),
      isActive: serializer.fromJson<int>(json['is_active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'field_name': serializer.toJson<String>(fieldName),
      'op_id': serializer.toJson<String>(opId),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'origin_seq': serializer.toJson<int>(originSeq),
      'value': serializer.toJson<String>(value),
      'is_active': serializer.toJson<int>(isActive),
    };
  }

  TextFieldVersion copyWith({
    String? workspaceId,
    String? entityType,
    String? entityId,
    String? fieldName,
    String? opId,
    String? originDeviceId,
    int? originSeq,
    String? value,
    int? isActive,
  }) => TextFieldVersion(
    workspaceId: workspaceId ?? this.workspaceId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    fieldName: fieldName ?? this.fieldName,
    opId: opId ?? this.opId,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    originSeq: originSeq ?? this.originSeq,
    value: value ?? this.value,
    isActive: isActive ?? this.isActive,
  );
  TextFieldVersion copyWithCompanion(TextFieldVersionsCompanion data) {
    return TextFieldVersion(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      opId: data.opId.present ? data.opId.value : this.opId,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      originSeq: data.originSeq.present ? data.originSeq.value : this.originSeq,
      value: data.value.present ? data.value.value : this.value,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextFieldVersion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldName: $fieldName, ')
          ..write('opId: $opId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workspaceId,
    entityType,
    entityId,
    fieldName,
    opId,
    originDeviceId,
    originSeq,
    value,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextFieldVersion &&
          other.workspaceId == this.workspaceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.fieldName == this.fieldName &&
          other.opId == this.opId &&
          other.originDeviceId == this.originDeviceId &&
          other.originSeq == this.originSeq &&
          other.value == this.value &&
          other.isActive == this.isActive);
}

class TextFieldVersionsCompanion extends UpdateCompanion<TextFieldVersion> {
  final Value<String> workspaceId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> fieldName;
  final Value<String> opId;
  final Value<String> originDeviceId;
  final Value<int> originSeq;
  final Value<String> value;
  final Value<int> isActive;
  final Value<int> rowid;
  const TextFieldVersionsCompanion({
    this.workspaceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.opId = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.originSeq = const Value.absent(),
    this.value = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextFieldVersionsCompanion.insert({
    required String workspaceId,
    required String entityType,
    required String entityId,
    required String fieldName,
    required String opId,
    required String originDeviceId,
    required int originSeq,
    required String value,
    required int isActive,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       fieldName = Value(fieldName),
       opId = Value(opId),
       originDeviceId = Value(originDeviceId),
       originSeq = Value(originSeq),
       value = Value(value),
       isActive = Value(isActive);
  static Insertable<TextFieldVersion> custom({
    Expression<String>? workspaceId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? fieldName,
    Expression<String>? opId,
    Expression<String>? originDeviceId,
    Expression<int>? originSeq,
    Expression<String>? value,
    Expression<int>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (fieldName != null) 'field_name': fieldName,
      if (opId != null) 'op_id': opId,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (originSeq != null) 'origin_seq': originSeq,
      if (value != null) 'value': value,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextFieldVersionsCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? fieldName,
    Value<String>? opId,
    Value<String>? originDeviceId,
    Value<int>? originSeq,
    Value<String>? value,
    Value<int>? isActive,
    Value<int>? rowid,
  }) {
    return TextFieldVersionsCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fieldName: fieldName ?? this.fieldName,
      opId: opId ?? this.opId,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      originSeq: originSeq ?? this.originSeq,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (originSeq.present) {
      map['origin_seq'] = Variable<int>(originSeq.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextFieldVersionsCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldName: $fieldName, ')
          ..write('opId: $opId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('originSeq: $originSeq, ')
          ..write('value: $value, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MaterializationState extends Table
    with TableInfo<MaterializationState, MaterializationStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MaterializationState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (state IN (\'pending_create\', \'pending_dependency\', \'materialized\', \'deleted\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    entityType,
    entityId,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'materialization_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterializationStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, entityType, entityId};
  @override
  MaterializationStateData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterializationStateData(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  MaterializationState createAlias(String alias) {
    return MaterializationState(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, entity_type, entity_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MaterializationStateData extends DataClass
    implements Insertable<MaterializationStateData> {
  final String workspaceId;
  final String entityType;
  final String entityId;
  final String state;
  const MaterializationStateData({
    required this.workspaceId,
    required this.entityType,
    required this.entityId,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['state'] = Variable<String>(state);
    return map;
  }

  MaterializationStateCompanion toCompanion(bool nullToAbsent) {
    return MaterializationStateCompanion(
      workspaceId: Value(workspaceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      state: Value(state),
    );
  }

  factory MaterializationStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterializationStateData(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'state': serializer.toJson<String>(state),
    };
  }

  MaterializationStateData copyWith({
    String? workspaceId,
    String? entityType,
    String? entityId,
    String? state,
  }) => MaterializationStateData(
    workspaceId: workspaceId ?? this.workspaceId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    state: state ?? this.state,
  );
  MaterializationStateData copyWithCompanion(
    MaterializationStateCompanion data,
  ) {
    return MaterializationStateData(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterializationStateData(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workspaceId, entityType, entityId, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterializationStateData &&
          other.workspaceId == this.workspaceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.state == this.state);
}

class MaterializationStateCompanion
    extends UpdateCompanion<MaterializationStateData> {
  final Value<String> workspaceId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> state;
  final Value<int> rowid;
  const MaterializationStateCompanion({
    this.workspaceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterializationStateCompanion.insert({
    required String workspaceId,
    required String entityType,
    required String entityId,
    required String state,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       state = Value(state);
  static Insertable<MaterializationStateData> custom({
    Expression<String>? workspaceId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterializationStateCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return MaterializationStateCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterializationStateCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class OriginProgress extends Table
    with TableInfo<OriginProgress, OriginProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OriginProgress(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _maxContiguousSeqMeta = const VerificationMeta(
    'maxContiguousSeq',
  );
  late final GeneratedColumn<int> maxContiguousSeq = GeneratedColumn<int>(
    'max_contiguous_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (max_contiguous_seq >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    workspaceId,
    originDeviceId,
    maxContiguousSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'origin_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<OriginProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('max_contiguous_seq')) {
      context.handle(
        _maxContiguousSeqMeta,
        maxContiguousSeq.isAcceptableOrUnknown(
          data['max_contiguous_seq']!,
          _maxContiguousSeqMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxContiguousSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, originDeviceId};
  @override
  OriginProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OriginProgressData(
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      maxContiguousSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_contiguous_seq'],
      )!,
    );
  }

  @override
  OriginProgress createAlias(String alias) {
    return OriginProgress(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(workspace_id, origin_device_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class OriginProgressData extends DataClass
    implements Insertable<OriginProgressData> {
  final String workspaceId;
  final String originDeviceId;
  final int maxContiguousSeq;
  const OriginProgressData({
    required this.workspaceId,
    required this.originDeviceId,
    required this.maxContiguousSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['workspace_id'] = Variable<String>(workspaceId);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['max_contiguous_seq'] = Variable<int>(maxContiguousSeq);
    return map;
  }

  OriginProgressCompanion toCompanion(bool nullToAbsent) {
    return OriginProgressCompanion(
      workspaceId: Value(workspaceId),
      originDeviceId: Value(originDeviceId),
      maxContiguousSeq: Value(maxContiguousSeq),
    );
  }

  factory OriginProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OriginProgressData(
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      originDeviceId: serializer.fromJson<String>(json['origin_device_id']),
      maxContiguousSeq: serializer.fromJson<int>(json['max_contiguous_seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workspace_id': serializer.toJson<String>(workspaceId),
      'origin_device_id': serializer.toJson<String>(originDeviceId),
      'max_contiguous_seq': serializer.toJson<int>(maxContiguousSeq),
    };
  }

  OriginProgressData copyWith({
    String? workspaceId,
    String? originDeviceId,
    int? maxContiguousSeq,
  }) => OriginProgressData(
    workspaceId: workspaceId ?? this.workspaceId,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    maxContiguousSeq: maxContiguousSeq ?? this.maxContiguousSeq,
  );
  OriginProgressData copyWithCompanion(OriginProgressCompanion data) {
    return OriginProgressData(
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      maxContiguousSeq: data.maxContiguousSeq.present
          ? data.maxContiguousSeq.value
          : this.maxContiguousSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OriginProgressData(')
          ..write('workspaceId: $workspaceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('maxContiguousSeq: $maxContiguousSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(workspaceId, originDeviceId, maxContiguousSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OriginProgressData &&
          other.workspaceId == this.workspaceId &&
          other.originDeviceId == this.originDeviceId &&
          other.maxContiguousSeq == this.maxContiguousSeq);
}

class OriginProgressCompanion extends UpdateCompanion<OriginProgressData> {
  final Value<String> workspaceId;
  final Value<String> originDeviceId;
  final Value<int> maxContiguousSeq;
  final Value<int> rowid;
  const OriginProgressCompanion({
    this.workspaceId = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.maxContiguousSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OriginProgressCompanion.insert({
    required String workspaceId,
    required String originDeviceId,
    required int maxContiguousSeq,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       originDeviceId = Value(originDeviceId),
       maxContiguousSeq = Value(maxContiguousSeq);
  static Insertable<OriginProgressData> custom({
    Expression<String>? workspaceId,
    Expression<String>? originDeviceId,
    Expression<int>? maxContiguousSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (maxContiguousSeq != null) 'max_contiguous_seq': maxContiguousSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OriginProgressCompanion copyWith({
    Value<String>? workspaceId,
    Value<String>? originDeviceId,
    Value<int>? maxContiguousSeq,
    Value<int>? rowid,
  }) {
    return OriginProgressCompanion(
      workspaceId: workspaceId ?? this.workspaceId,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      maxContiguousSeq: maxContiguousSeq ?? this.maxContiguousSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (maxContiguousSeq.present) {
      map['max_contiguous_seq'] = Variable<int>(maxContiguousSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OriginProgressCompanion(')
          ..write('workspaceId: $workspaceId, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('maxContiguousSeq: $maxContiguousSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Oplog oplog = Oplog(this);
  late final Index idxOplogOrigin = Index(
    'idx_oplog_origin',
    'CREATE INDEX idx_oplog_origin ON oplog (workspace_id, origin_device_id, origin_seq)',
  );
  late final Index idxOplogEntity = Index(
    'idx_oplog_entity',
    'CREATE INDEX idx_oplog_entity ON oplog (workspace_id, entity_type, entity_id)',
  );
  late final Trigger oplogImmutable = Trigger(
    'CREATE TRIGGER oplog_immutable BEFORE UPDATE OF op_id, workspace_id, origin_device_id, origin_seq, wire_version, hlc_wall_ms, hlc_counter, entity_type, entity_id, "action", payload_schema_version, envelope_bytes, signature ON oplog BEGIN SELECT RAISE (ABORT, \'Operation content is immutable\');END',
    'oplog_immutable',
  );
  late final Trigger oplogNoDelete = Trigger(
    'CREATE TRIGGER oplog_no_delete BEFORE DELETE ON oplog BEGIN SELECT RAISE (ABORT, \'V1 retains all operations\');END',
    'oplog_no_delete',
  );
  late final Trigger oplogNoReplace = Trigger(
    'CREATE TRIGGER oplog_no_replace BEFORE INSERT ON oplog WHEN EXISTS (SELECT 1 FROM oplog WHERE op_id = NEW.op_id OR(workspace_id = NEW.workspace_id AND origin_device_id = NEW.origin_device_id AND origin_seq = NEW.origin_seq)) BEGIN SELECT RAISE (ABORT, \'Operation identity already exists\');END',
    'oplog_no_replace',
  );
  late final WorkspaceClockState workspaceClockState = WorkspaceClockState(
    this,
  );
  late final ObservedOrigins observedOrigins = ObservedOrigins(this);
  late final SyncQuarantine syncQuarantine = SyncQuarantine(this);
  late final Workspaces workspaces = Workspaces(this);
  late final TrustedDevices trustedDevices = TrustedDevices(this);
  late final ExamProfiles examProfiles = ExamProfiles(this);
  late final Subjects subjects = Subjects(this);
  late final Tasks tasks = Tasks(this);
  late final DailyReviews dailyReviews = DailyReviews(this);
  late final StudySessions studySessions = StudySessions(this);
  late final StudySessionSegments studySessionSegments = StudySessionSegments(
    this,
  );
  late final Index oneOpenSegment = Index(
    'one_open_segment',
    'CREATE UNIQUE INDEX one_open_segment ON study_session_segments (workspace_id, session_id) WHERE ended_at_ms IS NULL',
  );
  late final SessionDurations sessionDurations = SessionDurations(this);
  late final EntityFieldClock entityFieldClock = EntityFieldClock(this);
  late final Tombstones tombstones = Tombstones(this);
  late final TextFieldVersions textFieldVersions = TextFieldVersions(this);
  late final MaterializationState materializationState = MaterializationState(
    this,
  );
  late final OriginProgress originProgress = OriginProgress(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    oplog,
    idxOplogOrigin,
    idxOplogEntity,
    oplogImmutable,
    oplogNoDelete,
    oplogNoReplace,
    workspaceClockState,
    observedOrigins,
    syncQuarantine,
    workspaces,
    trustedDevices,
    examProfiles,
    subjects,
    tasks,
    dailyReviews,
    studySessions,
    studySessionSegments,
    oneOpenSegment,
    sessionDurations,
    entityFieldClock,
    tombstones,
    textFieldVersions,
    materializationState,
    originProgress,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'oplog',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'oplog',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'oplog',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
  ]);
}

typedef $OplogCreateCompanionBuilder = OplogCompanion Function({
  required String opId,
  required String workspaceId,
  required String originDeviceId,
  required int originSeq,
  required int wireVersion,
  required int hlcWallMs,
  required int hlcCounter,
  required String entityType,
  required String entityId,
  required String action,
  required int payloadSchemaVersion,
  required Uint8List envelopeBytes,
  required Uint8List signature,
  Value<String?> receivedFromDeviceId,
  Value<int?> receivedAtMs,
  Value<String> applyState,
  Value<int> retryCount,
  Value<String?> localError,
  Value<int> rowid,
});
typedef $OplogUpdateCompanionBuilder = OplogCompanion Function({
  Value<String> opId,
  Value<String> workspaceId,
  Value<String> originDeviceId,
  Value<int> originSeq,
  Value<int> wireVersion,
  Value<int> hlcWallMs,
  Value<int> hlcCounter,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> action,
  Value<int> payloadSchemaVersion,
  Value<Uint8List> envelopeBytes,
  Value<Uint8List> signature,
  Value<String?> receivedFromDeviceId,
  Value<int?> receivedAtMs,
  Value<String> applyState,
  Value<int> retryCount,
  Value<String?> localError,
  Value<int> rowid,
});

final class $OplogReferences
    extends BaseReferences<_$AppDatabase, Oplog, OplogData> {
  $OplogReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<EntityFieldClock, List<EntityFieldClockData>>
  _entityFieldClockRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entityFieldClock,
    aliasName: 'oplog__op_id__entity_field_clock__winner_op_id',
  );

  $EntityFieldClockProcessedTableManager get entityFieldClockRefs {
    final manager = $EntityFieldClockTableManager($_db, $_db.entityFieldClock)
        .filter(
          (f) => f.winnerOpId.opId.sqlEquals($_itemColumn<String>('op_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _entityFieldClockRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Tombstones, List<Tombstone>> _tombstonesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tombstones,
    aliasName: 'oplog__op_id__tombstones__delete_op_id',
  );

  $TombstonesProcessedTableManager get tombstonesRefs {
    final manager = $TombstonesTableManager($_db, $_db.tombstones).filter(
      (f) => f.deleteOpId.opId.sqlEquals($_itemColumn<String>('op_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tombstonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<TextFieldVersions, List<TextFieldVersion>>
  _textFieldVersionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.textFieldVersions,
        aliasName: 'oplog__op_id__text_field_versions__op_id',
      );

  $TextFieldVersionsProcessedTableManager get textFieldVersionsRefs {
    final manager = $TextFieldVersionsTableManager(
      $_db,
      $_db.textFieldVersions,
    ).filter((f) => f.opId.opId.sqlEquals($_itemColumn<String>('op_id')!));

    final cache = $_typedResult.readTableOrNull(
      _textFieldVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $OplogFilterComposer extends Composer<_$AppDatabase, Oplog> {
  $OplogFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wireVersion => $composableBuilder(
    column: $table.wireVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadSchemaVersion => $composableBuilder(
    column: $table.payloadSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get envelopeBytes => $composableBuilder(
    column: $table.envelopeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedFromDeviceId => $composableBuilder(
    column: $table.receivedFromDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applyState => $composableBuilder(
    column: $table.applyState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localError => $composableBuilder(
    column: $table.localError,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entityFieldClockRefs(
    Expression<bool> Function($EntityFieldClockFilterComposer f) f,
  ) {
    final $EntityFieldClockFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.entityFieldClock,
      getReferencedColumn: (t) => t.winnerOpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntityFieldClockFilterComposer(
            $db: $db,
            $table: $db.entityFieldClock,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tombstonesRefs(
    Expression<bool> Function($TombstonesFilterComposer f) f,
  ) {
    final $TombstonesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.tombstones,
      getReferencedColumn: (t) => t.deleteOpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TombstonesFilterComposer(
            $db: $db,
            $table: $db.tombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> textFieldVersionsRefs(
    Expression<bool> Function($TextFieldVersionsFilterComposer f) f,
  ) {
    final $TextFieldVersionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.textFieldVersions,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TextFieldVersionsFilterComposer(
            $db: $db,
            $table: $db.textFieldVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OplogOrderingComposer extends Composer<_$AppDatabase, Oplog> {
  $OplogOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wireVersion => $composableBuilder(
    column: $table.wireVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadSchemaVersion => $composableBuilder(
    column: $table.payloadSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get envelopeBytes => $composableBuilder(
    column: $table.envelopeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedFromDeviceId => $composableBuilder(
    column: $table.receivedFromDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applyState => $composableBuilder(
    column: $table.applyState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localError => $composableBuilder(
    column: $table.localError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OplogAnnotationComposer extends Composer<_$AppDatabase, Oplog> {
  $OplogAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originSeq =>
      $composableBuilder(column: $table.originSeq, builder: (column) => column);

  GeneratedColumn<int> get wireVersion => $composableBuilder(
    column: $table.wireVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hlcWallMs =>
      $composableBuilder(column: $table.hlcWallMs, builder: (column) => column);

  GeneratedColumn<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get payloadSchemaVersion => $composableBuilder(
    column: $table.payloadSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get envelopeBytes => $composableBuilder(
    column: $table.envelopeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get receivedFromDeviceId => $composableBuilder(
    column: $table.receivedFromDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get applyState => $composableBuilder(
    column: $table.applyState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localError => $composableBuilder(
    column: $table.localError,
    builder: (column) => column,
  );

  Expression<T> entityFieldClockRefs<T extends Object>(
    Expression<T> Function($EntityFieldClockAnnotationComposer a) f,
  ) {
    final $EntityFieldClockAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.entityFieldClock,
      getReferencedColumn: (t) => t.winnerOpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntityFieldClockAnnotationComposer(
            $db: $db,
            $table: $db.entityFieldClock,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tombstonesRefs<T extends Object>(
    Expression<T> Function($TombstonesAnnotationComposer a) f,
  ) {
    final $TombstonesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.tombstones,
      getReferencedColumn: (t) => t.deleteOpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TombstonesAnnotationComposer(
            $db: $db,
            $table: $db.tombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> textFieldVersionsRefs<T extends Object>(
    Expression<T> Function($TextFieldVersionsAnnotationComposer a) f,
  ) {
    final $TextFieldVersionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.textFieldVersions,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TextFieldVersionsAnnotationComposer(
            $db: $db,
            $table: $db.textFieldVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OplogTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Oplog,
          OplogData,
          $OplogFilterComposer,
          $OplogOrderingComposer,
          $OplogAnnotationComposer,
          $OplogCreateCompanionBuilder,
          $OplogUpdateCompanionBuilder,
          (OplogData, $OplogReferences),
          OplogData,
          PrefetchHooks Function({
            bool entityFieldClockRefs,
            bool tombstonesRefs,
            bool textFieldVersionsRefs,
          })
        > {
  $OplogTableManager(_$AppDatabase db, Oplog table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OplogFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OplogOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OplogAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> originSeq = const Value.absent(),
                Value<int> wireVersion = const Value.absent(),
                Value<int> hlcWallMs = const Value.absent(),
                Value<int> hlcCounter = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<int> payloadSchemaVersion = const Value.absent(),
                Value<Uint8List> envelopeBytes = const Value.absent(),
                Value<Uint8List> signature = const Value.absent(),
                Value<String?> receivedFromDeviceId = const Value.absent(),
                Value<int?> receivedAtMs = const Value.absent(),
                Value<String> applyState = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> localError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OplogCompanion(
                opId: opId,
                workspaceId: workspaceId,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                wireVersion: wireVersion,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadSchemaVersion: payloadSchemaVersion,
                envelopeBytes: envelopeBytes,
                signature: signature,
                receivedFromDeviceId: receivedFromDeviceId,
                receivedAtMs: receivedAtMs,
                applyState: applyState,
                retryCount: retryCount,
                localError: localError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String workspaceId,
                required String originDeviceId,
                required int originSeq,
                required int wireVersion,
                required int hlcWallMs,
                required int hlcCounter,
                required String entityType,
                required String entityId,
                required String action,
                required int payloadSchemaVersion,
                required Uint8List envelopeBytes,
                required Uint8List signature,
                Value<String?> receivedFromDeviceId = const Value.absent(),
                Value<int?> receivedAtMs = const Value.absent(),
                Value<String> applyState = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> localError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OplogCompanion.insert(
                opId: opId,
                workspaceId: workspaceId,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                wireVersion: wireVersion,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadSchemaVersion: payloadSchemaVersion,
                envelopeBytes: envelopeBytes,
                signature: signature,
                receivedFromDeviceId: receivedFromDeviceId,
                receivedAtMs: receivedAtMs,
                applyState: applyState,
                retryCount: retryCount,
                localError: localError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Oplog, OplogData>(table),
                  $OplogReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entityFieldClockRefs = false,
                tombstonesRefs = false,
                textFieldVersionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entityFieldClockRefs) db.entityFieldClock,
                    if (tombstonesRefs) db.tombstones,
                    if (textFieldVersionsRefs) db.textFieldVersions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entityFieldClockRefs)
                        await $_getPrefetchedData<
                          OplogData,
                          Oplog,
                          EntityFieldClockData
                        >(
                          currentTable: table,
                          referencedTable: $OplogReferences
                              ._entityFieldClockRefsTable(db),
                          managerFromTypedResult: (p0) => $OplogReferences(
                            db,
                            table,
                            p0,
                          ).entityFieldClockRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.winnerOpId == item.opId,
                              ),
                          typedResults: items,
                        ),
                      if (tombstonesRefs)
                        await $_getPrefetchedData<OplogData, Oplog, Tombstone>(
                          currentTable: table,
                          referencedTable: $OplogReferences
                              ._tombstonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $OplogReferences(db, table, p0).tombstonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deleteOpId == item.opId,
                              ),
                          typedResults: items,
                        ),
                      if (textFieldVersionsRefs)
                        await $_getPrefetchedData<
                          OplogData,
                          Oplog,
                          TextFieldVersion
                        >(
                          currentTable: table,
                          referencedTable: $OplogReferences
                              ._textFieldVersionsRefsTable(db),
                          managerFromTypedResult: (p0) => $OplogReferences(
                            db,
                            table,
                            p0,
                          ).textFieldVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.opId == item.opId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $OplogProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Oplog,
      OplogData,
      $OplogFilterComposer,
      $OplogOrderingComposer,
      $OplogAnnotationComposer,
      $OplogCreateCompanionBuilder,
      $OplogUpdateCompanionBuilder,
      (OplogData, $OplogReferences),
      OplogData,
      PrefetchHooks Function({
        bool entityFieldClockRefs,
        bool tombstonesRefs,
        bool textFieldVersionsRefs,
      })
    >;
typedef $WorkspaceClockStateCreateCompanionBuilder =
    WorkspaceClockStateCompanion Function({
      required String workspaceId,
      required String deviceId,
      Value<int> nextOriginSeq,
      Value<int> lastHlcWallMs,
      Value<int> lastHlcCounter,
      Value<int> rowid,
    });
typedef $WorkspaceClockStateUpdateCompanionBuilder =
    WorkspaceClockStateCompanion Function({
      Value<String> workspaceId,
      Value<String> deviceId,
      Value<int> nextOriginSeq,
      Value<int> lastHlcWallMs,
      Value<int> lastHlcCounter,
      Value<int> rowid,
    });

class $WorkspaceClockStateFilterComposer
    extends Composer<_$AppDatabase, WorkspaceClockState> {
  $WorkspaceClockStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextOriginSeq => $composableBuilder(
    column: $table.nextOriginSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastHlcWallMs => $composableBuilder(
    column: $table.lastHlcWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastHlcCounter => $composableBuilder(
    column: $table.lastHlcCounter,
    builder: (column) => ColumnFilters(column),
  );
}

class $WorkspaceClockStateOrderingComposer
    extends Composer<_$AppDatabase, WorkspaceClockState> {
  $WorkspaceClockStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextOriginSeq => $composableBuilder(
    column: $table.nextOriginSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastHlcWallMs => $composableBuilder(
    column: $table.lastHlcWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastHlcCounter => $composableBuilder(
    column: $table.lastHlcCounter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $WorkspaceClockStateAnnotationComposer
    extends Composer<_$AppDatabase, WorkspaceClockState> {
  $WorkspaceClockStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get nextOriginSeq => $composableBuilder(
    column: $table.nextOriginSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastHlcWallMs => $composableBuilder(
    column: $table.lastHlcWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastHlcCounter => $composableBuilder(
    column: $table.lastHlcCounter,
    builder: (column) => column,
  );
}

class $WorkspaceClockStateTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          WorkspaceClockState,
          WorkspaceClockStateData,
          $WorkspaceClockStateFilterComposer,
          $WorkspaceClockStateOrderingComposer,
          $WorkspaceClockStateAnnotationComposer,
          $WorkspaceClockStateCreateCompanionBuilder,
          $WorkspaceClockStateUpdateCompanionBuilder,
          (
            WorkspaceClockStateData,
            BaseReferences<
              _$AppDatabase,
              WorkspaceClockState,
              WorkspaceClockStateData
            >,
          ),
          WorkspaceClockStateData,
          PrefetchHooks Function()
        > {
  $WorkspaceClockStateTableManager(_$AppDatabase db, WorkspaceClockState table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceClockStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceClockStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceClockStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> nextOriginSeq = const Value.absent(),
                Value<int> lastHlcWallMs = const Value.absent(),
                Value<int> lastHlcCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceClockStateCompanion(
                workspaceId: workspaceId,
                deviceId: deviceId,
                nextOriginSeq: nextOriginSeq,
                lastHlcWallMs: lastHlcWallMs,
                lastHlcCounter: lastHlcCounter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String deviceId,
                Value<int> nextOriginSeq = const Value.absent(),
                Value<int> lastHlcWallMs = const Value.absent(),
                Value<int> lastHlcCounter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceClockStateCompanion.insert(
                workspaceId: workspaceId,
                deviceId: deviceId,
                nextOriginSeq: nextOriginSeq,
                lastHlcWallMs: lastHlcWallMs,
                lastHlcCounter: lastHlcCounter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<WorkspaceClockState, WorkspaceClockStateData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    WorkspaceClockState,
                    WorkspaceClockStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $WorkspaceClockStateProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      WorkspaceClockState,
      WorkspaceClockStateData,
      $WorkspaceClockStateFilterComposer,
      $WorkspaceClockStateOrderingComposer,
      $WorkspaceClockStateAnnotationComposer,
      $WorkspaceClockStateCreateCompanionBuilder,
      $WorkspaceClockStateUpdateCompanionBuilder,
      (
        WorkspaceClockStateData,
        BaseReferences<
          _$AppDatabase,
          WorkspaceClockState,
          WorkspaceClockStateData
        >,
      ),
      WorkspaceClockStateData,
      PrefetchHooks Function()
    >;
typedef $ObservedOriginsCreateCompanionBuilder =
    ObservedOriginsCompanion Function({
      required String workspaceId,
      required String deviceId,
      required String originDeviceId,
      required int maxObservedSeq,
      Value<int> rowid,
    });
typedef $ObservedOriginsUpdateCompanionBuilder =
    ObservedOriginsCompanion Function({
      Value<String> workspaceId,
      Value<String> deviceId,
      Value<String> originDeviceId,
      Value<int> maxObservedSeq,
      Value<int> rowid,
    });

class $ObservedOriginsFilterComposer
    extends Composer<_$AppDatabase, ObservedOrigins> {
  $ObservedOriginsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxObservedSeq => $composableBuilder(
    column: $table.maxObservedSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $ObservedOriginsOrderingComposer
    extends Composer<_$AppDatabase, ObservedOrigins> {
  $ObservedOriginsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxObservedSeq => $composableBuilder(
    column: $table.maxObservedSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ObservedOriginsAnnotationComposer
    extends Composer<_$AppDatabase, ObservedOrigins> {
  $ObservedOriginsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxObservedSeq => $composableBuilder(
    column: $table.maxObservedSeq,
    builder: (column) => column,
  );
}

class $ObservedOriginsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ObservedOrigins,
          ObservedOrigin,
          $ObservedOriginsFilterComposer,
          $ObservedOriginsOrderingComposer,
          $ObservedOriginsAnnotationComposer,
          $ObservedOriginsCreateCompanionBuilder,
          $ObservedOriginsUpdateCompanionBuilder,
          (
            ObservedOrigin,
            BaseReferences<_$AppDatabase, ObservedOrigins, ObservedOrigin>,
          ),
          ObservedOrigin,
          PrefetchHooks Function()
        > {
  $ObservedOriginsTableManager(_$AppDatabase db, ObservedOrigins table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ObservedOriginsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ObservedOriginsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ObservedOriginsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> maxObservedSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObservedOriginsCompanion(
                workspaceId: workspaceId,
                deviceId: deviceId,
                originDeviceId: originDeviceId,
                maxObservedSeq: maxObservedSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String deviceId,
                required String originDeviceId,
                required int maxObservedSeq,
                Value<int> rowid = const Value.absent(),
              }) => ObservedOriginsCompanion.insert(
                workspaceId: workspaceId,
                deviceId: deviceId,
                originDeviceId: originDeviceId,
                maxObservedSeq: maxObservedSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ObservedOrigins, ObservedOrigin>(table),
                  BaseReferences<
                    _$AppDatabase,
                    ObservedOrigins,
                    ObservedOrigin
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ObservedOriginsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ObservedOrigins,
      ObservedOrigin,
      $ObservedOriginsFilterComposer,
      $ObservedOriginsOrderingComposer,
      $ObservedOriginsAnnotationComposer,
      $ObservedOriginsCreateCompanionBuilder,
      $ObservedOriginsUpdateCompanionBuilder,
      (
        ObservedOrigin,
        BaseReferences<_$AppDatabase, ObservedOrigins, ObservedOrigin>,
      ),
      ObservedOrigin,
      PrefetchHooks Function()
    >;
typedef $SyncQuarantineCreateCompanionBuilder =
    SyncQuarantineCompanion Function({
      Value<int> id,
      required String reason,
      required int receivedAtMs,
    });
typedef $SyncQuarantineUpdateCompanionBuilder =
    SyncQuarantineCompanion Function({
      Value<int> id,
      Value<String> reason,
      Value<int> receivedAtMs,
    });

class $SyncQuarantineFilterComposer
    extends Composer<_$AppDatabase, SyncQuarantine> {
  $SyncQuarantineFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncQuarantineOrderingComposer
    extends Composer<_$AppDatabase, SyncQuarantine> {
  $SyncQuarantineOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncQuarantineAnnotationComposer
    extends Composer<_$AppDatabase, SyncQuarantine> {
  $SyncQuarantineAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => column,
  );
}

class $SyncQuarantineTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncQuarantine,
          SyncQuarantineData,
          $SyncQuarantineFilterComposer,
          $SyncQuarantineOrderingComposer,
          $SyncQuarantineAnnotationComposer,
          $SyncQuarantineCreateCompanionBuilder,
          $SyncQuarantineUpdateCompanionBuilder,
          (
            SyncQuarantineData,
            BaseReferences<_$AppDatabase, SyncQuarantine, SyncQuarantineData>,
          ),
          SyncQuarantineData,
          PrefetchHooks Function()
        > {
  $SyncQuarantineTableManager(_$AppDatabase db, SyncQuarantine table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncQuarantineFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncQuarantineOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncQuarantineAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> receivedAtMs = const Value.absent(),
              }) => SyncQuarantineCompanion(
                id: id,
                reason: reason,
                receivedAtMs: receivedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String reason,
                required int receivedAtMs,
              }) => SyncQuarantineCompanion.insert(
                id: id,
                reason: reason,
                receivedAtMs: receivedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncQuarantine, SyncQuarantineData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    SyncQuarantine,
                    SyncQuarantineData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncQuarantineProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncQuarantine,
      SyncQuarantineData,
      $SyncQuarantineFilterComposer,
      $SyncQuarantineOrderingComposer,
      $SyncQuarantineAnnotationComposer,
      $SyncQuarantineCreateCompanionBuilder,
      $SyncQuarantineUpdateCompanionBuilder,
      (
        SyncQuarantineData,
        BaseReferences<_$AppDatabase, SyncQuarantine, SyncQuarantineData>,
      ),
      SyncQuarantineData,
      PrefetchHooks Function()
    >;
typedef $WorkspacesCreateCompanionBuilder = WorkspacesCompanion Function({
  required String id,
  required String name,
  required String statsTimezone,
  required int createdAtMs,
  required String createdByDeviceId,
  Value<int> rowid,
});
typedef $WorkspacesUpdateCompanionBuilder = WorkspacesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> statsTimezone,
  Value<int> createdAtMs,
  Value<String> createdByDeviceId,
  Value<int> rowid,
});

final class $WorkspacesReferences
    extends BaseReferences<_$AppDatabase, Workspaces, Workspace> {
  $WorkspacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ExamProfiles, List<ExamProfile>>
  _examProfilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.examProfiles,
    aliasName: 'workspaces__id__exam_profiles__workspace_id',
  );

  $ExamProfilesProcessedTableManager get examProfilesRefs {
    final manager = $ExamProfilesTableManager(
      $_db,
      $_db.examProfiles,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examProfilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Subjects, List<Subject>> _subjectsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subjects,
    aliasName: 'workspaces__id__subjects__workspace_id',
  );

  $SubjectsProcessedTableManager get subjectsRefs {
    final manager = $SubjectsTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Tasks, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'workspaces__id__tasks__workspace_id',
  );

  $TasksProcessedTableManager get tasksRefs {
    final manager = $TasksTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<DailyReviews, List<DailyReview>>
  _dailyReviewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailyReviews,
    aliasName: 'workspaces__id__daily_reviews__workspace_id',
  );

  $DailyReviewsProcessedTableManager get dailyReviewsRefs {
    final manager = $DailyReviewsTableManager(
      $_db,
      $_db.dailyReviews,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<StudySessions, List<StudySession>>
  _studySessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studySessions,
    aliasName: 'workspaces__id__study_sessions__workspace_id',
  );

  $StudySessionsProcessedTableManager get studySessionsRefs {
    final manager = $StudySessionsTableManager(
      $_db,
      $_db.studySessions,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_studySessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $WorkspacesFilterComposer extends Composer<_$AppDatabase, Workspaces> {
  $WorkspacesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statsTimezone => $composableBuilder(
    column: $table.statsTimezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByDeviceId => $composableBuilder(
    column: $table.createdByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> examProfilesRefs(
    Expression<bool> Function($ExamProfilesFilterComposer f) f,
  ) {
    final $ExamProfilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examProfiles,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExamProfilesFilterComposer(
            $db: $db,
            $table: $db.examProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> subjectsRefs(
    Expression<bool> Function($SubjectsFilterComposer f) f,
  ) {
    final $SubjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SubjectsFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($TasksFilterComposer f) f,
  ) {
    final $TasksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dailyReviewsRefs(
    Expression<bool> Function($DailyReviewsFilterComposer f) f,
  ) {
    final $DailyReviewsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyReviews,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DailyReviewsFilterComposer(
            $db: $db,
            $table: $db.dailyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> studySessionsRefs(
    Expression<bool> Function($StudySessionsFilterComposer f) f,
  ) {
    final $StudySessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studySessions,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StudySessionsFilterComposer(
            $db: $db,
            $table: $db.studySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspacesOrderingComposer extends Composer<_$AppDatabase, Workspaces> {
  $WorkspacesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statsTimezone => $composableBuilder(
    column: $table.statsTimezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByDeviceId => $composableBuilder(
    column: $table.createdByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $WorkspacesAnnotationComposer
    extends Composer<_$AppDatabase, Workspaces> {
  $WorkspacesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get statsTimezone => $composableBuilder(
    column: $table.statsTimezone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdByDeviceId => $composableBuilder(
    column: $table.createdByDeviceId,
    builder: (column) => column,
  );

  Expression<T> examProfilesRefs<T extends Object>(
    Expression<T> Function($ExamProfilesAnnotationComposer a) f,
  ) {
    final $ExamProfilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.examProfiles,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExamProfilesAnnotationComposer(
            $db: $db,
            $table: $db.examProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> subjectsRefs<T extends Object>(
    Expression<T> Function($SubjectsAnnotationComposer a) f,
  ) {
    final $SubjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SubjectsAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($TasksAnnotationComposer a) f,
  ) {
    final $TasksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TasksAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dailyReviewsRefs<T extends Object>(
    Expression<T> Function($DailyReviewsAnnotationComposer a) f,
  ) {
    final $DailyReviewsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyReviews,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DailyReviewsAnnotationComposer(
            $db: $db,
            $table: $db.dailyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> studySessionsRefs<T extends Object>(
    Expression<T> Function($StudySessionsAnnotationComposer a) f,
  ) {
    final $StudySessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studySessions,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StudySessionsAnnotationComposer(
            $db: $db,
            $table: $db.studySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspacesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Workspaces,
          Workspace,
          $WorkspacesFilterComposer,
          $WorkspacesOrderingComposer,
          $WorkspacesAnnotationComposer,
          $WorkspacesCreateCompanionBuilder,
          $WorkspacesUpdateCompanionBuilder,
          (Workspace, $WorkspacesReferences),
          Workspace,
          PrefetchHooks Function({
            bool examProfilesRefs,
            bool subjectsRefs,
            bool tasksRefs,
            bool dailyReviewsRefs,
            bool studySessionsRefs,
          })
        > {
  $WorkspacesTableManager(_$AppDatabase db, Workspaces table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspacesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspacesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspacesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> statsTimezone = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<String> createdByDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                statsTimezone: statsTimezone,
                createdAtMs: createdAtMs,
                createdByDeviceId: createdByDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String statsTimezone,
                required int createdAtMs,
                required String createdByDeviceId,
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                statsTimezone: statsTimezone,
                createdAtMs: createdAtMs,
                createdByDeviceId: createdByDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Workspaces, Workspace>(table),
                  $WorkspacesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                examProfilesRefs = false,
                subjectsRefs = false,
                tasksRefs = false,
                dailyReviewsRefs = false,
                studySessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (examProfilesRefs) db.examProfiles,
                    if (subjectsRefs) db.subjects,
                    if (tasksRefs) db.tasks,
                    if (dailyReviewsRefs) db.dailyReviews,
                    if (studySessionsRefs) db.studySessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (examProfilesRefs)
                        await $_getPrefetchedData<
                          Workspace,
                          Workspaces,
                          ExamProfile
                        >(
                          currentTable: table,
                          referencedTable: $WorkspacesReferences
                              ._examProfilesRefsTable(db),
                          managerFromTypedResult: (p0) => $WorkspacesReferences(
                            db,
                            table,
                            p0,
                          ).examProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (subjectsRefs)
                        await $_getPrefetchedData<
                          Workspace,
                          Workspaces,
                          Subject
                        >(
                          currentTable: table,
                          referencedTable: $WorkspacesReferences
                              ._subjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspacesReferences(db, table, p0).subjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<Workspace, Workspaces, Task>(
                          currentTable: table,
                          referencedTable: $WorkspacesReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspacesReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dailyReviewsRefs)
                        await $_getPrefetchedData<
                          Workspace,
                          Workspaces,
                          DailyReview
                        >(
                          currentTable: table,
                          referencedTable: $WorkspacesReferences
                              ._dailyReviewsRefsTable(db),
                          managerFromTypedResult: (p0) => $WorkspacesReferences(
                            db,
                            table,
                            p0,
                          ).dailyReviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (studySessionsRefs)
                        await $_getPrefetchedData<
                          Workspace,
                          Workspaces,
                          StudySession
                        >(
                          currentTable: table,
                          referencedTable: $WorkspacesReferences
                              ._studySessionsRefsTable(db),
                          managerFromTypedResult: (p0) => $WorkspacesReferences(
                            db,
                            table,
                            p0,
                          ).studySessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $WorkspacesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Workspaces,
      Workspace,
      $WorkspacesFilterComposer,
      $WorkspacesOrderingComposer,
      $WorkspacesAnnotationComposer,
      $WorkspacesCreateCompanionBuilder,
      $WorkspacesUpdateCompanionBuilder,
      (Workspace, $WorkspacesReferences),
      Workspace,
      PrefetchHooks Function({
        bool examProfilesRefs,
        bool subjectsRefs,
        bool tasksRefs,
        bool dailyReviewsRefs,
        bool studySessionsRefs,
      })
    >;
typedef $TrustedDevicesCreateCompanionBuilder =
    TrustedDevicesCompanion Function({
      required String workspaceId,
      required String deviceId,
      required Uint8List identityPublicKey,
      required String trustState,
      Value<int?> maxAllowedOriginSeq,
      Value<int> rowid,
    });
typedef $TrustedDevicesUpdateCompanionBuilder =
    TrustedDevicesCompanion Function({
      Value<String> workspaceId,
      Value<String> deviceId,
      Value<Uint8List> identityPublicKey,
      Value<String> trustState,
      Value<int?> maxAllowedOriginSeq,
      Value<int> rowid,
    });

class $TrustedDevicesFilterComposer
    extends Composer<_$AppDatabase, TrustedDevices> {
  $TrustedDevicesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAllowedOriginSeq => $composableBuilder(
    column: $table.maxAllowedOriginSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $TrustedDevicesOrderingComposer
    extends Composer<_$AppDatabase, TrustedDevices> {
  $TrustedDevicesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAllowedOriginSeq => $composableBuilder(
    column: $table.maxAllowedOriginSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TrustedDevicesAnnotationComposer
    extends Composer<_$AppDatabase, TrustedDevices> {
  $TrustedDevicesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<Uint8List> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxAllowedOriginSeq => $composableBuilder(
    column: $table.maxAllowedOriginSeq,
    builder: (column) => column,
  );
}

class $TrustedDevicesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TrustedDevices,
          TrustedDevice,
          $TrustedDevicesFilterComposer,
          $TrustedDevicesOrderingComposer,
          $TrustedDevicesAnnotationComposer,
          $TrustedDevicesCreateCompanionBuilder,
          $TrustedDevicesUpdateCompanionBuilder,
          (
            TrustedDevice,
            BaseReferences<_$AppDatabase, TrustedDevices, TrustedDevice>,
          ),
          TrustedDevice,
          PrefetchHooks Function()
        > {
  $TrustedDevicesTableManager(_$AppDatabase db, TrustedDevices table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TrustedDevicesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TrustedDevicesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TrustedDevicesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<Uint8List> identityPublicKey = const Value.absent(),
                Value<String> trustState = const Value.absent(),
                Value<int?> maxAllowedOriginSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrustedDevicesCompanion(
                workspaceId: workspaceId,
                deviceId: deviceId,
                identityPublicKey: identityPublicKey,
                trustState: trustState,
                maxAllowedOriginSeq: maxAllowedOriginSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String deviceId,
                required Uint8List identityPublicKey,
                required String trustState,
                Value<int?> maxAllowedOriginSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrustedDevicesCompanion.insert(
                workspaceId: workspaceId,
                deviceId: deviceId,
                identityPublicKey: identityPublicKey,
                trustState: trustState,
                maxAllowedOriginSeq: maxAllowedOriginSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TrustedDevices, TrustedDevice>(table),
                  BaseReferences<_$AppDatabase, TrustedDevices, TrustedDevice>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TrustedDevicesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TrustedDevices,
      TrustedDevice,
      $TrustedDevicesFilterComposer,
      $TrustedDevicesOrderingComposer,
      $TrustedDevicesAnnotationComposer,
      $TrustedDevicesCreateCompanionBuilder,
      $TrustedDevicesUpdateCompanionBuilder,
      (
        TrustedDevice,
        BaseReferences<_$AppDatabase, TrustedDevices, TrustedDevice>,
      ),
      TrustedDevice,
      PrefetchHooks Function()
    >;
typedef $ExamProfilesCreateCompanionBuilder = ExamProfilesCompanion Function({
  required String id,
  required String workspaceId,
  Value<String?> examName,
  Value<String?> examDate,
  Value<String?> targetSchool,
  Value<String?> targetMajor,
  Value<int?> targetTotalScoreX100,
  Value<int> rowid,
});
typedef $ExamProfilesUpdateCompanionBuilder = ExamProfilesCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String?> examName,
  Value<String?> examDate,
  Value<String?> targetSchool,
  Value<String?> targetMajor,
  Value<int?> targetTotalScoreX100,
  Value<int> rowid,
});

final class $ExamProfilesReferences
    extends BaseReferences<_$AppDatabase, ExamProfiles, ExamProfile> {
  $ExamProfilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('exam_profiles__workspace_id__workspaces__id');

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExamProfilesFilterComposer
    extends Composer<_$AppDatabase, ExamProfiles> {
  $ExamProfilesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examName => $composableBuilder(
    column: $table.examName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examDate => $composableBuilder(
    column: $table.examDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetSchool => $composableBuilder(
    column: $table.targetSchool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetMajor => $composableBuilder(
    column: $table.targetMajor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetTotalScoreX100 => $composableBuilder(
    column: $table.targetTotalScoreX100,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExamProfilesOrderingComposer
    extends Composer<_$AppDatabase, ExamProfiles> {
  $ExamProfilesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examName => $composableBuilder(
    column: $table.examName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examDate => $composableBuilder(
    column: $table.examDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetSchool => $composableBuilder(
    column: $table.targetSchool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetMajor => $composableBuilder(
    column: $table.targetMajor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetTotalScoreX100 => $composableBuilder(
    column: $table.targetTotalScoreX100,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExamProfilesAnnotationComposer
    extends Composer<_$AppDatabase, ExamProfiles> {
  $ExamProfilesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get examName =>
      $composableBuilder(column: $table.examName, builder: (column) => column);

  GeneratedColumn<String> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<String> get targetSchool => $composableBuilder(
    column: $table.targetSchool,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetMajor => $composableBuilder(
    column: $table.targetMajor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetTotalScoreX100 => $composableBuilder(
    column: $table.targetTotalScoreX100,
    builder: (column) => column,
  );

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExamProfilesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ExamProfiles,
          ExamProfile,
          $ExamProfilesFilterComposer,
          $ExamProfilesOrderingComposer,
          $ExamProfilesAnnotationComposer,
          $ExamProfilesCreateCompanionBuilder,
          $ExamProfilesUpdateCompanionBuilder,
          (ExamProfile, $ExamProfilesReferences),
          ExamProfile,
          PrefetchHooks Function({bool workspaceId})
        > {
  $ExamProfilesTableManager(_$AppDatabase db, ExamProfiles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExamProfilesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExamProfilesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExamProfilesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> examName = const Value.absent(),
                Value<String?> examDate = const Value.absent(),
                Value<String?> targetSchool = const Value.absent(),
                Value<String?> targetMajor = const Value.absent(),
                Value<int?> targetTotalScoreX100 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamProfilesCompanion(
                id: id,
                workspaceId: workspaceId,
                examName: examName,
                examDate: examDate,
                targetSchool: targetSchool,
                targetMajor: targetMajor,
                targetTotalScoreX100: targetTotalScoreX100,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String?> examName = const Value.absent(),
                Value<String?> examDate = const Value.absent(),
                Value<String?> targetSchool = const Value.absent(),
                Value<String?> targetMajor = const Value.absent(),
                Value<int?> targetTotalScoreX100 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamProfilesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                examName: examName,
                examDate: examDate,
                targetSchool: targetSchool,
                targetMajor: targetMajor,
                targetTotalScoreX100: targetTotalScoreX100,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExamProfiles, ExamProfile>(table),
                  $ExamProfilesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $ExamProfilesReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $ExamProfilesReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ExamProfilesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ExamProfiles,
      ExamProfile,
      $ExamProfilesFilterComposer,
      $ExamProfilesOrderingComposer,
      $ExamProfilesAnnotationComposer,
      $ExamProfilesCreateCompanionBuilder,
      $ExamProfilesUpdateCompanionBuilder,
      (ExamProfile, $ExamProfilesReferences),
      ExamProfile,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $SubjectsCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String workspaceId,
  required String name,
  Value<String?> category,
  Value<int?> targetScoreX100,
  Value<int?> maxScoreX100,
  Value<int> sortOrder,
  Value<int> archived,
  Value<int> rowid,
});
typedef $SubjectsUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> name,
  Value<String?> category,
  Value<int?> targetScoreX100,
  Value<int?> maxScoreX100,
  Value<int> sortOrder,
  Value<int> archived,
  Value<int> rowid,
});

final class $SubjectsReferences
    extends BaseReferences<_$AppDatabase, Subjects, Subject> {
  $SubjectsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('subjects__workspace_id__workspaces__id');

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SubjectsFilterComposer extends Composer<_$AppDatabase, Subjects> {
  $SubjectsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetScoreX100 => $composableBuilder(
    column: $table.targetScoreX100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxScoreX100 => $composableBuilder(
    column: $table.maxScoreX100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SubjectsOrderingComposer extends Composer<_$AppDatabase, Subjects> {
  $SubjectsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetScoreX100 => $composableBuilder(
    column: $table.targetScoreX100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxScoreX100 => $composableBuilder(
    column: $table.maxScoreX100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SubjectsAnnotationComposer extends Composer<_$AppDatabase, Subjects> {
  $SubjectsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get targetScoreX100 => $composableBuilder(
    column: $table.targetScoreX100,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxScoreX100 => $composableBuilder(
    column: $table.maxScoreX100,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SubjectsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Subjects,
          Subject,
          $SubjectsFilterComposer,
          $SubjectsOrderingComposer,
          $SubjectsAnnotationComposer,
          $SubjectsCreateCompanionBuilder,
          $SubjectsUpdateCompanionBuilder,
          (Subject, $SubjectsReferences),
          Subject,
          PrefetchHooks Function({bool workspaceId})
        > {
  $SubjectsTableManager(_$AppDatabase db, Subjects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SubjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SubjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SubjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> targetScoreX100 = const Value.absent(),
                Value<int?> maxScoreX100 = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                category: category,
                targetScoreX100: targetScoreX100,
                maxScoreX100: maxScoreX100,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                Value<String?> category = const Value.absent(),
                Value<int?> targetScoreX100 = const Value.absent(),
                Value<int?> maxScoreX100 = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                category: category,
                targetScoreX100: targetScoreX100,
                maxScoreX100: maxScoreX100,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Subjects, Subject>(table),
                  $SubjectsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $SubjectsReferences._workspaceIdTable(
                          db,
                        ),
                        referencedColumn: $SubjectsReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SubjectsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Subjects,
      Subject,
      $SubjectsFilterComposer,
      $SubjectsOrderingComposer,
      $SubjectsAnnotationComposer,
      $SubjectsCreateCompanionBuilder,
      $SubjectsUpdateCompanionBuilder,
      (Subject, $SubjectsReferences),
      Subject,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $TasksCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String workspaceId,
  required String title,
  Value<String?> subjectId,
  Value<String?> knowledgeNodeId,
  Value<String?> scheduledDate,
  Value<int?> dueAtMs,
  Value<int?> estimatedSeconds,
  Value<int> priority,
  Value<int> sortOrder,
  required String status,
  Value<int?> completedAtMs,
  Value<String?> note,
  Value<int> rowid,
});
typedef $TasksUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> title,
  Value<String?> subjectId,
  Value<String?> knowledgeNodeId,
  Value<String?> scheduledDate,
  Value<int?> dueAtMs,
  Value<int?> estimatedSeconds,
  Value<int> priority,
  Value<int> sortOrder,
  Value<String> status,
  Value<int?> completedAtMs,
  Value<String?> note,
  Value<int> rowid,
});

final class $TasksReferences
    extends BaseReferences<_$AppDatabase, Tasks, Task> {
  $TasksReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('tasks__workspace_id__workspaces__id');

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TasksFilterComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAtMs => $composableBuilder(
    column: $table.dueAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedSeconds => $composableBuilder(
    column: $table.estimatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TasksOrderingComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAtMs => $composableBuilder(
    column: $table.dueAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedSeconds => $composableBuilder(
    column: $table.estimatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TasksAnnotationComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueAtMs =>
      $composableBuilder(column: $table.dueAtMs, builder: (column) => column);

  GeneratedColumn<int> get estimatedSeconds => $composableBuilder(
    column: $table.estimatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TasksTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tasks,
          Task,
          $TasksFilterComposer,
          $TasksOrderingComposer,
          $TasksAnnotationComposer,
          $TasksCreateCompanionBuilder,
          $TasksUpdateCompanionBuilder,
          (Task, $TasksReferences),
          Task,
          PrefetchHooks Function({bool workspaceId})
        > {
  $TasksTableManager(_$AppDatabase db, Tasks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TasksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TasksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TasksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> knowledgeNodeId = const Value.absent(),
                Value<String?> scheduledDate = const Value.absent(),
                Value<int?> dueAtMs = const Value.absent(),
                Value<int?> estimatedSeconds = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> completedAtMs = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                workspaceId: workspaceId,
                title: title,
                subjectId: subjectId,
                knowledgeNodeId: knowledgeNodeId,
                scheduledDate: scheduledDate,
                dueAtMs: dueAtMs,
                estimatedSeconds: estimatedSeconds,
                priority: priority,
                sortOrder: sortOrder,
                status: status,
                completedAtMs: completedAtMs,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String title,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> knowledgeNodeId = const Value.absent(),
                Value<String?> scheduledDate = const Value.absent(),
                Value<int?> dueAtMs = const Value.absent(),
                Value<int?> estimatedSeconds = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required String status,
                Value<int?> completedAtMs = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                title: title,
                subjectId: subjectId,
                knowledgeNodeId: knowledgeNodeId,
                scheduledDate: scheduledDate,
                dueAtMs: dueAtMs,
                estimatedSeconds: estimatedSeconds,
                priority: priority,
                sortOrder: sortOrder,
                status: status,
                completedAtMs: completedAtMs,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tasks, Task>(table),
                  $TasksReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $TasksReferences._workspaceIdTable(db),
                        referencedColumn: $TasksReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $TasksProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tasks,
      Task,
      $TasksFilterComposer,
      $TasksOrderingComposer,
      $TasksAnnotationComposer,
      $TasksCreateCompanionBuilder,
      $TasksUpdateCompanionBuilder,
      (Task, $TasksReferences),
      Task,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $DailyReviewsCreateCompanionBuilder = DailyReviewsCompanion Function({
  required String id,
  required String workspaceId,
  required String reviewDate,
  required String content,
  Value<int> rowid,
});
typedef $DailyReviewsUpdateCompanionBuilder = DailyReviewsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> reviewDate,
  Value<String> content,
  Value<int> rowid,
});

final class $DailyReviewsReferences
    extends BaseReferences<_$AppDatabase, DailyReviews, DailyReview> {
  $DailyReviewsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('daily_reviews__workspace_id__workspaces__id');

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DailyReviewsFilterComposer
    extends Composer<_$AppDatabase, DailyReviews> {
  $DailyReviewsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DailyReviewsOrderingComposer
    extends Composer<_$AppDatabase, DailyReviews> {
  $DailyReviewsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DailyReviewsAnnotationComposer
    extends Composer<_$AppDatabase, DailyReviews> {
  $DailyReviewsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DailyReviewsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DailyReviews,
          DailyReview,
          $DailyReviewsFilterComposer,
          $DailyReviewsOrderingComposer,
          $DailyReviewsAnnotationComposer,
          $DailyReviewsCreateCompanionBuilder,
          $DailyReviewsUpdateCompanionBuilder,
          (DailyReview, $DailyReviewsReferences),
          DailyReview,
          PrefetchHooks Function({bool workspaceId})
        > {
  $DailyReviewsTableManager(_$AppDatabase db, DailyReviews table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DailyReviewsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DailyReviewsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DailyReviewsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> reviewDate = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReviewsCompanion(
                id: id,
                workspaceId: workspaceId,
                reviewDate: reviewDate,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String reviewDate,
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => DailyReviewsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                reviewDate: reviewDate,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DailyReviews, DailyReview>(table),
                  $DailyReviewsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $DailyReviewsReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $DailyReviewsReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $DailyReviewsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DailyReviews,
      DailyReview,
      $DailyReviewsFilterComposer,
      $DailyReviewsOrderingComposer,
      $DailyReviewsAnnotationComposer,
      $DailyReviewsCreateCompanionBuilder,
      $DailyReviewsUpdateCompanionBuilder,
      (DailyReview, $DailyReviewsReferences),
      DailyReview,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $StudySessionsCreateCompanionBuilder = StudySessionsCompanion Function({
  required String id,
  required String workspaceId,
  required String subjectId,
  Value<String?> taskId,
  Value<String?> knowledgeNodeId,
  required String ownerDeviceId,
  required String status,
  required int startedAtMs,
  Value<int?> endedAtMs,
  required String mode,
  Value<String?> note,
  Value<int> rowid,
});
typedef $StudySessionsUpdateCompanionBuilder = StudySessionsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> subjectId,
  Value<String?> taskId,
  Value<String?> knowledgeNodeId,
  Value<String> ownerDeviceId,
  Value<String> status,
  Value<int> startedAtMs,
  Value<int?> endedAtMs,
  Value<String> mode,
  Value<String?> note,
  Value<int> rowid,
});

final class $StudySessionsReferences
    extends BaseReferences<_$AppDatabase, StudySessions, StudySession> {
  $StudySessionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('study_sessions__workspace_id__workspaces__id');

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $StudySessionsFilterComposer
    extends Composer<_$AppDatabase, StudySessions> {
  $StudySessionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StudySessionsOrderingComposer
    extends Composer<_$AppDatabase, StudySessions> {
  $StudySessionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StudySessionsAnnotationComposer
    extends Composer<_$AppDatabase, StudySessions> {
  $StudySessionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get knowledgeNodeId => $composableBuilder(
    column: $table.knowledgeNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerDeviceId => $composableBuilder(
    column: $table.ownerDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StudySessionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StudySessions,
          StudySession,
          $StudySessionsFilterComposer,
          $StudySessionsOrderingComposer,
          $StudySessionsAnnotationComposer,
          $StudySessionsCreateCompanionBuilder,
          $StudySessionsUpdateCompanionBuilder,
          (StudySession, $StudySessionsReferences),
          StudySession,
          PrefetchHooks Function({bool workspaceId})
        > {
  $StudySessionsTableManager(_$AppDatabase db, StudySessions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StudySessionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StudySessionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StudySessionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> knowledgeNodeId = const Value.absent(),
                Value<String> ownerDeviceId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySessionsCompanion(
                id: id,
                workspaceId: workspaceId,
                subjectId: subjectId,
                taskId: taskId,
                knowledgeNodeId: knowledgeNodeId,
                ownerDeviceId: ownerDeviceId,
                status: status,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                mode: mode,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String subjectId,
                Value<String?> taskId = const Value.absent(),
                Value<String?> knowledgeNodeId = const Value.absent(),
                required String ownerDeviceId,
                required String status,
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
                required String mode,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySessionsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                subjectId: subjectId,
                taskId: taskId,
                knowledgeNodeId: knowledgeNodeId,
                ownerDeviceId: ownerDeviceId,
                status: status,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                mode: mode,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<StudySessions, StudySession>(table),
                  $StudySessionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $StudySessionsReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $StudySessionsReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $StudySessionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StudySessions,
      StudySession,
      $StudySessionsFilterComposer,
      $StudySessionsOrderingComposer,
      $StudySessionsAnnotationComposer,
      $StudySessionsCreateCompanionBuilder,
      $StudySessionsUpdateCompanionBuilder,
      (StudySession, $StudySessionsReferences),
      StudySession,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $StudySessionSegmentsCreateCompanionBuilder =
    StudySessionSegmentsCompanion Function({
      required String id,
      required String workspaceId,
      required String sessionId,
      required int startedAtMs,
      Value<int?> endedAtMs,
      Value<int> rowid,
    });
typedef $StudySessionSegmentsUpdateCompanionBuilder =
    StudySessionSegmentsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> sessionId,
      Value<int> startedAtMs,
      Value<int?> endedAtMs,
      Value<int> rowid,
    });

class $StudySessionSegmentsFilterComposer
    extends Composer<_$AppDatabase, StudySessionSegments> {
  $StudySessionSegmentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $StudySessionSegmentsOrderingComposer
    extends Composer<_$AppDatabase, StudySessionSegments> {
  $StudySessionSegmentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $StudySessionSegmentsAnnotationComposer
    extends Composer<_$AppDatabase, StudySessionSegments> {
  $StudySessionSegmentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);
}

class $StudySessionSegmentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StudySessionSegments,
          StudySessionSegment,
          $StudySessionSegmentsFilterComposer,
          $StudySessionSegmentsOrderingComposer,
          $StudySessionSegmentsAnnotationComposer,
          $StudySessionSegmentsCreateCompanionBuilder,
          $StudySessionSegmentsUpdateCompanionBuilder,
          (
            StudySessionSegment,
            BaseReferences<
              _$AppDatabase,
              StudySessionSegments,
              StudySessionSegment
            >,
          ),
          StudySessionSegment,
          PrefetchHooks Function()
        > {
  $StudySessionSegmentsTableManager(
    _$AppDatabase db,
    StudySessionSegments table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StudySessionSegmentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StudySessionSegmentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StudySessionSegmentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySessionSegmentsCompanion(
                id: id,
                workspaceId: workspaceId,
                sessionId: sessionId,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String sessionId,
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySessionSegmentsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                sessionId: sessionId,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<StudySessionSegments, StudySessionSegment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    StudySessionSegments,
                    StudySessionSegment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $StudySessionSegmentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StudySessionSegments,
      StudySessionSegment,
      $StudySessionSegmentsFilterComposer,
      $StudySessionSegmentsOrderingComposer,
      $StudySessionSegmentsAnnotationComposer,
      $StudySessionSegmentsCreateCompanionBuilder,
      $StudySessionSegmentsUpdateCompanionBuilder,
      (
        StudySessionSegment,
        BaseReferences<
          _$AppDatabase,
          StudySessionSegments,
          StudySessionSegment
        >,
      ),
      StudySessionSegment,
      PrefetchHooks Function()
    >;
typedef $EntityFieldClockCreateCompanionBuilder =
    EntityFieldClockCompanion Function({
      required String workspaceId,
      required String entityType,
      required String entityId,
      required String fieldName,
      required String winnerOpId,
      required int hlcWallMs,
      required int hlcCounter,
      required String originDeviceId,
      required int originSeq,
      required Uint8List valueBytes,
      Value<int> rowid,
    });
typedef $EntityFieldClockUpdateCompanionBuilder =
    EntityFieldClockCompanion Function({
      Value<String> workspaceId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> fieldName,
      Value<String> winnerOpId,
      Value<int> hlcWallMs,
      Value<int> hlcCounter,
      Value<String> originDeviceId,
      Value<int> originSeq,
      Value<Uint8List> valueBytes,
      Value<int> rowid,
    });

final class $EntityFieldClockReferences
    extends
        BaseReferences<_$AppDatabase, EntityFieldClock, EntityFieldClockData> {
  $EntityFieldClockReferences(super.$_db, super.$_table, super.$_typedResult);

  static Oplog _winnerOpIdTable(_$AppDatabase db) =>
      db.oplog.createAlias('entity_field_clock__winner_op_id__oplog__op_id');

  $OplogProcessedTableManager get winnerOpId {
    final $_column = $_itemColumn<String>('winner_op_id')!;

    final manager = $OplogTableManager(
      $_db,
      $_db.oplog,
    ).filter((f) => f.opId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_winnerOpIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EntityFieldClockFilterComposer
    extends Composer<_$AppDatabase, EntityFieldClock> {
  $EntityFieldClockFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get valueBytes => $composableBuilder(
    column: $table.valueBytes,
    builder: (column) => ColumnFilters(column),
  );

  $OplogFilterComposer get winnerOpId {
    final $OplogFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.winnerOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogFilterComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntityFieldClockOrderingComposer
    extends Composer<_$AppDatabase, EntityFieldClock> {
  $EntityFieldClockOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get valueBytes => $composableBuilder(
    column: $table.valueBytes,
    builder: (column) => ColumnOrderings(column),
  );

  $OplogOrderingComposer get winnerOpId {
    final $OplogOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.winnerOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogOrderingComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntityFieldClockAnnotationComposer
    extends Composer<_$AppDatabase, EntityFieldClock> {
  $EntityFieldClockAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<int> get hlcWallMs =>
      $composableBuilder(column: $table.hlcWallMs, builder: (column) => column);

  GeneratedColumn<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originSeq =>
      $composableBuilder(column: $table.originSeq, builder: (column) => column);

  GeneratedColumn<Uint8List> get valueBytes => $composableBuilder(
    column: $table.valueBytes,
    builder: (column) => column,
  );

  $OplogAnnotationComposer get winnerOpId {
    final $OplogAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.winnerOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogAnnotationComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntityFieldClockTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          EntityFieldClock,
          EntityFieldClockData,
          $EntityFieldClockFilterComposer,
          $EntityFieldClockOrderingComposer,
          $EntityFieldClockAnnotationComposer,
          $EntityFieldClockCreateCompanionBuilder,
          $EntityFieldClockUpdateCompanionBuilder,
          (EntityFieldClockData, $EntityFieldClockReferences),
          EntityFieldClockData,
          PrefetchHooks Function({bool winnerOpId})
        > {
  $EntityFieldClockTableManager(_$AppDatabase db, EntityFieldClock table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntityFieldClockFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntityFieldClockOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntityFieldClockAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> winnerOpId = const Value.absent(),
                Value<int> hlcWallMs = const Value.absent(),
                Value<int> hlcCounter = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> originSeq = const Value.absent(),
                Value<Uint8List> valueBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntityFieldClockCompanion(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                fieldName: fieldName,
                winnerOpId: winnerOpId,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                valueBytes: valueBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String entityType,
                required String entityId,
                required String fieldName,
                required String winnerOpId,
                required int hlcWallMs,
                required int hlcCounter,
                required String originDeviceId,
                required int originSeq,
                required Uint8List valueBytes,
                Value<int> rowid = const Value.absent(),
              }) => EntityFieldClockCompanion.insert(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                fieldName: fieldName,
                winnerOpId: winnerOpId,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                valueBytes: valueBytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EntityFieldClock, EntityFieldClockData>(table),
                  $EntityFieldClockReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({winnerOpId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (winnerOpId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.winnerOpId,
                        referencedTable: $EntityFieldClockReferences
                            ._winnerOpIdTable(db),
                        referencedColumn: $EntityFieldClockReferences
                            ._winnerOpIdTable(db)
                            .opId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EntityFieldClockProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      EntityFieldClock,
      EntityFieldClockData,
      $EntityFieldClockFilterComposer,
      $EntityFieldClockOrderingComposer,
      $EntityFieldClockAnnotationComposer,
      $EntityFieldClockCreateCompanionBuilder,
      $EntityFieldClockUpdateCompanionBuilder,
      (EntityFieldClockData, $EntityFieldClockReferences),
      EntityFieldClockData,
      PrefetchHooks Function({bool winnerOpId})
    >;
typedef $TombstonesCreateCompanionBuilder = TombstonesCompanion Function({
  required String workspaceId,
  required String entityType,
  required String entityId,
  required String deleteOpId,
  required int hlcWallMs,
  required int hlcCounter,
  required String originDeviceId,
  required int originSeq,
  Value<int> rowid,
});
typedef $TombstonesUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> workspaceId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> deleteOpId,
  Value<int> hlcWallMs,
  Value<int> hlcCounter,
  Value<String> originDeviceId,
  Value<int> originSeq,
  Value<int> rowid,
});

final class $TombstonesReferences
    extends BaseReferences<_$AppDatabase, Tombstones, Tombstone> {
  $TombstonesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Oplog _deleteOpIdTable(_$AppDatabase db) =>
      db.oplog.createAlias('tombstones__delete_op_id__oplog__op_id');

  $OplogProcessedTableManager get deleteOpId {
    final $_column = $_itemColumn<String>('delete_op_id')!;

    final manager = $OplogTableManager(
      $_db,
      $_db.oplog,
    ).filter((f) => f.opId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deleteOpIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TombstonesFilterComposer extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnFilters(column),
  );

  $OplogFilterComposer get deleteOpId {
    final $OplogFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deleteOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogFilterComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TombstonesOrderingComposer extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcWallMs => $composableBuilder(
    column: $table.hlcWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnOrderings(column),
  );

  $OplogOrderingComposer get deleteOpId {
    final $OplogOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deleteOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogOrderingComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TombstonesAnnotationComposer
    extends Composer<_$AppDatabase, Tombstones> {
  $TombstonesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get hlcWallMs =>
      $composableBuilder(column: $table.hlcWallMs, builder: (column) => column);

  GeneratedColumn<int> get hlcCounter => $composableBuilder(
    column: $table.hlcCounter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originSeq =>
      $composableBuilder(column: $table.originSeq, builder: (column) => column);

  $OplogAnnotationComposer get deleteOpId {
    final $OplogAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deleteOpId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogAnnotationComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TombstonesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tombstones,
          Tombstone,
          $TombstonesFilterComposer,
          $TombstonesOrderingComposer,
          $TombstonesAnnotationComposer,
          $TombstonesCreateCompanionBuilder,
          $TombstonesUpdateCompanionBuilder,
          (Tombstone, $TombstonesReferences),
          Tombstone,
          PrefetchHooks Function({bool deleteOpId})
        > {
  $TombstonesTableManager(_$AppDatabase db, Tombstones table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TombstonesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TombstonesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TombstonesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> deleteOpId = const Value.absent(),
                Value<int> hlcWallMs = const Value.absent(),
                Value<int> hlcCounter = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> originSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                deleteOpId: deleteOpId,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String entityType,
                required String entityId,
                required String deleteOpId,
                required int hlcWallMs,
                required int hlcCounter,
                required String originDeviceId,
                required int originSeq,
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                deleteOpId: deleteOpId,
                hlcWallMs: hlcWallMs,
                hlcCounter: hlcCounter,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tombstones, Tombstone>(table),
                  $TombstonesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deleteOpId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deleteOpId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.deleteOpId,
                        referencedTable: $TombstonesReferences._deleteOpIdTable(
                          db,
                        ),
                        referencedColumn: $TombstonesReferences
                            ._deleteOpIdTable(db)
                            .opId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $TombstonesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tombstones,
      Tombstone,
      $TombstonesFilterComposer,
      $TombstonesOrderingComposer,
      $TombstonesAnnotationComposer,
      $TombstonesCreateCompanionBuilder,
      $TombstonesUpdateCompanionBuilder,
      (Tombstone, $TombstonesReferences),
      Tombstone,
      PrefetchHooks Function({bool deleteOpId})
    >;
typedef $TextFieldVersionsCreateCompanionBuilder =
    TextFieldVersionsCompanion Function({
      required String workspaceId,
      required String entityType,
      required String entityId,
      required String fieldName,
      required String opId,
      required String originDeviceId,
      required int originSeq,
      required String value,
      required int isActive,
      Value<int> rowid,
    });
typedef $TextFieldVersionsUpdateCompanionBuilder =
    TextFieldVersionsCompanion Function({
      Value<String> workspaceId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> fieldName,
      Value<String> opId,
      Value<String> originDeviceId,
      Value<int> originSeq,
      Value<String> value,
      Value<int> isActive,
      Value<int> rowid,
    });

final class $TextFieldVersionsReferences
    extends BaseReferences<_$AppDatabase, TextFieldVersions, TextFieldVersion> {
  $TextFieldVersionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Oplog _opIdTable(_$AppDatabase db) =>
      db.oplog.createAlias('text_field_versions__op_id__oplog__op_id');

  $OplogProcessedTableManager get opId {
    final $_column = $_itemColumn<String>('op_id')!;

    final manager = $OplogTableManager(
      $_db,
      $_db.oplog,
    ).filter((f) => f.opId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_opIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TextFieldVersionsFilterComposer
    extends Composer<_$AppDatabase, TextFieldVersions> {
  $TextFieldVersionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $OplogFilterComposer get opId {
    final $OplogFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogFilterComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TextFieldVersionsOrderingComposer
    extends Composer<_$AppDatabase, TextFieldVersions> {
  $TextFieldVersionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originSeq => $composableBuilder(
    column: $table.originSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $OplogOrderingComposer get opId {
    final $OplogOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogOrderingComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TextFieldVersionsAnnotationComposer
    extends Composer<_$AppDatabase, TextFieldVersions> {
  $TextFieldVersionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originSeq =>
      $composableBuilder(column: $table.originSeq, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $OplogAnnotationComposer get opId {
    final $OplogAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opId,
      referencedTable: $db.oplog,
      getReferencedColumn: (t) => t.opId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OplogAnnotationComposer(
            $db: $db,
            $table: $db.oplog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TextFieldVersionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TextFieldVersions,
          TextFieldVersion,
          $TextFieldVersionsFilterComposer,
          $TextFieldVersionsOrderingComposer,
          $TextFieldVersionsAnnotationComposer,
          $TextFieldVersionsCreateCompanionBuilder,
          $TextFieldVersionsUpdateCompanionBuilder,
          (TextFieldVersion, $TextFieldVersionsReferences),
          TextFieldVersion,
          PrefetchHooks Function({bool opId})
        > {
  $TextFieldVersionsTableManager(_$AppDatabase db, TextFieldVersions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TextFieldVersionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TextFieldVersionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TextFieldVersionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> originSeq = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TextFieldVersionsCompanion(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                fieldName: fieldName,
                opId: opId,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                value: value,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String entityType,
                required String entityId,
                required String fieldName,
                required String opId,
                required String originDeviceId,
                required int originSeq,
                required String value,
                required int isActive,
                Value<int> rowid = const Value.absent(),
              }) => TextFieldVersionsCompanion.insert(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                fieldName: fieldName,
                opId: opId,
                originDeviceId: originDeviceId,
                originSeq: originSeq,
                value: value,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TextFieldVersions, TextFieldVersion>(table),
                  $TextFieldVersionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({opId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (opId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.opId,
                        referencedTable: $TextFieldVersionsReferences
                            ._opIdTable(db),
                        referencedColumn: $TextFieldVersionsReferences
                            ._opIdTable(db)
                            .opId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $TextFieldVersionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TextFieldVersions,
      TextFieldVersion,
      $TextFieldVersionsFilterComposer,
      $TextFieldVersionsOrderingComposer,
      $TextFieldVersionsAnnotationComposer,
      $TextFieldVersionsCreateCompanionBuilder,
      $TextFieldVersionsUpdateCompanionBuilder,
      (TextFieldVersion, $TextFieldVersionsReferences),
      TextFieldVersion,
      PrefetchHooks Function({bool opId})
    >;
typedef $MaterializationStateCreateCompanionBuilder =
    MaterializationStateCompanion Function({
      required String workspaceId,
      required String entityType,
      required String entityId,
      required String state,
      Value<int> rowid,
    });
typedef $MaterializationStateUpdateCompanionBuilder =
    MaterializationStateCompanion Function({
      Value<String> workspaceId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> state,
      Value<int> rowid,
    });

class $MaterializationStateFilterComposer
    extends Composer<_$AppDatabase, MaterializationState> {
  $MaterializationStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $MaterializationStateOrderingComposer
    extends Composer<_$AppDatabase, MaterializationState> {
  $MaterializationStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MaterializationStateAnnotationComposer
    extends Composer<_$AppDatabase, MaterializationState> {
  $MaterializationStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $MaterializationStateTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          MaterializationState,
          MaterializationStateData,
          $MaterializationStateFilterComposer,
          $MaterializationStateOrderingComposer,
          $MaterializationStateAnnotationComposer,
          $MaterializationStateCreateCompanionBuilder,
          $MaterializationStateUpdateCompanionBuilder,
          (
            MaterializationStateData,
            BaseReferences<
              _$AppDatabase,
              MaterializationState,
              MaterializationStateData
            >,
          ),
          MaterializationStateData,
          PrefetchHooks Function()
        > {
  $MaterializationStateTableManager(
    _$AppDatabase db,
    MaterializationState table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MaterializationStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MaterializationStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MaterializationStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterializationStateCompanion(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String entityType,
                required String entityId,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => MaterializationStateCompanion.insert(
                workspaceId: workspaceId,
                entityType: entityType,
                entityId: entityId,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MaterializationState, MaterializationStateData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    MaterializationState,
                    MaterializationStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MaterializationStateProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      MaterializationState,
      MaterializationStateData,
      $MaterializationStateFilterComposer,
      $MaterializationStateOrderingComposer,
      $MaterializationStateAnnotationComposer,
      $MaterializationStateCreateCompanionBuilder,
      $MaterializationStateUpdateCompanionBuilder,
      (
        MaterializationStateData,
        BaseReferences<
          _$AppDatabase,
          MaterializationState,
          MaterializationStateData
        >,
      ),
      MaterializationStateData,
      PrefetchHooks Function()
    >;
typedef $OriginProgressCreateCompanionBuilder =
    OriginProgressCompanion Function({
      required String workspaceId,
      required String originDeviceId,
      required int maxContiguousSeq,
      Value<int> rowid,
    });
typedef $OriginProgressUpdateCompanionBuilder =
    OriginProgressCompanion Function({
      Value<String> workspaceId,
      Value<String> originDeviceId,
      Value<int> maxContiguousSeq,
      Value<int> rowid,
    });

class $OriginProgressFilterComposer
    extends Composer<_$AppDatabase, OriginProgress> {
  $OriginProgressFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxContiguousSeq => $composableBuilder(
    column: $table.maxContiguousSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $OriginProgressOrderingComposer
    extends Composer<_$AppDatabase, OriginProgress> {
  $OriginProgressOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxContiguousSeq => $composableBuilder(
    column: $table.maxContiguousSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OriginProgressAnnotationComposer
    extends Composer<_$AppDatabase, OriginProgress> {
  $OriginProgressAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxContiguousSeq => $composableBuilder(
    column: $table.maxContiguousSeq,
    builder: (column) => column,
  );
}

class $OriginProgressTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          OriginProgress,
          OriginProgressData,
          $OriginProgressFilterComposer,
          $OriginProgressOrderingComposer,
          $OriginProgressAnnotationComposer,
          $OriginProgressCreateCompanionBuilder,
          $OriginProgressUpdateCompanionBuilder,
          (
            OriginProgressData,
            BaseReferences<_$AppDatabase, OriginProgress, OriginProgressData>,
          ),
          OriginProgressData,
          PrefetchHooks Function()
        > {
  $OriginProgressTableManager(_$AppDatabase db, OriginProgress table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OriginProgressFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OriginProgressOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OriginProgressAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workspaceId = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> maxContiguousSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OriginProgressCompanion(
                workspaceId: workspaceId,
                originDeviceId: originDeviceId,
                maxContiguousSeq: maxContiguousSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workspaceId,
                required String originDeviceId,
                required int maxContiguousSeq,
                Value<int> rowid = const Value.absent(),
              }) => OriginProgressCompanion.insert(
                workspaceId: workspaceId,
                originDeviceId: originDeviceId,
                maxContiguousSeq: maxContiguousSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<OriginProgress, OriginProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    OriginProgress,
                    OriginProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $OriginProgressProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      OriginProgress,
      OriginProgressData,
      $OriginProgressFilterComposer,
      $OriginProgressOrderingComposer,
      $OriginProgressAnnotationComposer,
      $OriginProgressCreateCompanionBuilder,
      $OriginProgressUpdateCompanionBuilder,
      (
        OriginProgressData,
        BaseReferences<_$AppDatabase, OriginProgress, OriginProgressData>,
      ),
      OriginProgressData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $OplogTableManager get oplog => $OplogTableManager(_db, _db.oplog);
  $WorkspaceClockStateTableManager get workspaceClockState =>
      $WorkspaceClockStateTableManager(_db, _db.workspaceClockState);
  $ObservedOriginsTableManager get observedOrigins =>
      $ObservedOriginsTableManager(_db, _db.observedOrigins);
  $SyncQuarantineTableManager get syncQuarantine =>
      $SyncQuarantineTableManager(_db, _db.syncQuarantine);
  $WorkspacesTableManager get workspaces =>
      $WorkspacesTableManager(_db, _db.workspaces);
  $TrustedDevicesTableManager get trustedDevices =>
      $TrustedDevicesTableManager(_db, _db.trustedDevices);
  $ExamProfilesTableManager get examProfiles =>
      $ExamProfilesTableManager(_db, _db.examProfiles);
  $SubjectsTableManager get subjects =>
      $SubjectsTableManager(_db, _db.subjects);
  $TasksTableManager get tasks => $TasksTableManager(_db, _db.tasks);
  $DailyReviewsTableManager get dailyReviews =>
      $DailyReviewsTableManager(_db, _db.dailyReviews);
  $StudySessionsTableManager get studySessions =>
      $StudySessionsTableManager(_db, _db.studySessions);
  $StudySessionSegmentsTableManager get studySessionSegments =>
      $StudySessionSegmentsTableManager(_db, _db.studySessionSegments);
  $EntityFieldClockTableManager get entityFieldClock =>
      $EntityFieldClockTableManager(_db, _db.entityFieldClock);
  $TombstonesTableManager get tombstones =>
      $TombstonesTableManager(_db, _db.tombstones);
  $TextFieldVersionsTableManager get textFieldVersions =>
      $TextFieldVersionsTableManager(_db, _db.textFieldVersions);
  $MaterializationStateTableManager get materializationState =>
      $MaterializationStateTableManager(_db, _db.materializationState);
  $OriginProgressTableManager get originProgress =>
      $OriginProgressTableManager(_db, _db.originProgress);
}
