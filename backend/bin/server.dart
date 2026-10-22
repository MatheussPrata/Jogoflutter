import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:flutter_quest_backend/app.dart';
import 'package:flutter_quest_backend/services.dart';
import 'package:flutter_quest_backend/store.dart';

/// Ponto de entrada da API.
///
/// Variáveis de ambiente:
///   PORT           porta HTTP (default 8080)
///   HOST           interface (default 0.0.0.0)
///   DATA_DIR       pasta de dados (default ./data)
///   LESSONS_FILE   JSON das lições (default ../assets/lessons/lessons.json)
Future<void> main(List<String> args) async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final host = env['HOST'] ?? '0.0.0.0';
  final dataDir = env['DATA_DIR'] ?? 'data';

  final backendDir = File.fromUri(Platform.script).parent.parent.path;
  final lessonsFile = env['LESSONS_FILE'] ??
      '${Directory(backendDir).parent.path}/assets/lessons/lessons.json';

  final store = JsonStore('$dataDir/db.json');
  final tokens = TokenService(store);
  final purged = await tokens.purgeExpired();

  final ctx = AppContext(
    store: store,
    users: UserService(store),
    tokens: tokens,
    lessons: LessonService(lessonsFile),
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(apiMiddleware())
      .addHandler(buildHandler(ctx));

  final server = await shelf_io.serve(handler, host, port);
  server.autoCompress = true;

  stdout.writeln('Flutter Quest API a correr em http://$host:$port');
  stdout.writeln('Dados em: ${File('$dataDir/db.json').absolute.path}');
  stdout.writeln('Lições em: $lessonsFile');
  if (purged > 0) stdout.writeln('Sessões expiradas removidas: $purged');
}