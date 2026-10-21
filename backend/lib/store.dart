import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Persistência JSON em ficheiro único, atómica (tmp + rename).
///
/// Sem dependências nativas: serve tanto em Linux/VPS como local.
class JsonStore {
  final String filePath;
  final _Lock _lock = _Lock();
  Map<String, dynamic> _cache = <String, dynamic>{};
  bool _loaded = false;

  JsonStore(this.filePath);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final file = File(filePath);
    if (!await file.exists()) {
      _cache = <String, dynamic>{};
      _loaded = true;
      return;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      _cache = <String, dynamic>{};
    } else {
      final decoded = jsonDecode(raw);
      _cache = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }
    _loaded = true;
  }

  Future<void> _flush() async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final tmp = File('$filePath.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_cache),
      flush: true,
    );
    await tmp.rename(filePath);
  }

  Future<Map<String, dynamic>> readMap(String bucket) async {
    await _ensureLoaded();
    final value = _cache[bucket];
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  Future<List<dynamic>> readList(String bucket) async {
    await _ensureLoaded();
    final value = _cache[bucket];
    if (value is List) return value;
    return <dynamic>[];
  }

  Future<void> writeMap(String bucket, Map<String, dynamic> value) async {
    await _ensureLoaded();
    _cache[bucket] = value;
    await _flush();
  }

  Future<void> writeList(String bucket, List<dynamic> value) async {
    await _ensureLoaded();
    _cache[bucket] = value;
    await _flush();
  }

  /// Executa uma mutação serializada sobre um bucket-lista.
  ///
  /// O lock em memória evita lost updates quando dois pedidos chegam juntos.
  Future<T> mutateList<T>(
    String bucket,
    Future<T> Function(List<dynamic> items) action,
  ) async {
    return _lock.run(() async {
      await _ensureLoaded();
      final current = _cache[bucket];
      final items = current is List ? List<dynamic>.from(current) : <dynamic>[];
      final result = await action(items);
      _cache[bucket] = items;
      await _flush();
      return result;
    });
  }
}

/// Lock assíncrono simples (fila de execução).
class _Lock {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) async {
    final previous = _tail;
    final gate = Completer<void>();
    _tail = gate.future;
    await previous;
    try {
      return await action();
    } finally {
      gate.complete();
    }
  }
}
