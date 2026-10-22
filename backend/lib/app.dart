import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'services.dart';
import 'store.dart';
import 'user_record.dart';

/// Contexto partilhado pelos handlers.
class AppContext {
  final JsonStore store;
  final UserService users;
  final TokenService tokens;
  final LessonService lessons;
  final DateTime startedAt = DateTime.now().toUtc();

  AppContext({
    required this.store,
    required this.users,
    required this.tokens,
    required this.lessons,
  });
}

String _bearer(Request request) {
  final header = request.headers['authorization'] ?? '';
  if (header.toLowerCase().startsWith('bearer ')) {
    return header.substring(7).trim();
  }
  return '';
}

Response _json(Object? body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<UserRecord> _requireUser(AppContext ctx, Request request) async {
  final token = _bearer(request);
  final userId = await ctx.tokens.userIdFor(token);
  if (userId == null) {
    throw const ApiException(401, 'Sessão inválida ou expirada.');
  }
  final user = await ctx.users.findById(userId);
  if (user == null) {
    throw const ApiException(401, 'Utilizador não encontrado.');
  }
  return user;
}

/// Middleware que exige utilizador autenticado + admin.
Future<UserRecord> _requireAdmin(AppContext ctx, Request request) async {
  final user = await _requireUser(ctx, request);
  if (!user.isAdmin) {
    throw const ApiException(403, 'Acesso negado: apenas administradores.');
  }
  return user;
}

/// Middleware: CORS + conversão de ApiException em JSON.
Middleware apiMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      try {
        final response = await inner(request);
        return response.change(headers: _corsHeaders);
      } on ApiException catch (e) {
        return _json(e.toJson(), status: e.statusCode).change(
          headers: _corsHeaders,
        );
      } on LessonDataException catch (e) {
        return _json({'error': e.message}, status: 500).change(
          headers: _corsHeaders,
        );
      } catch (e) {
        return _json({'error': 'Erro interno'}, status: 500).change(
          headers: _corsHeaders,
        );
      }
    };
  };
}

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

/// Registo de rotas da API.
Handler buildHandler(AppContext ctx) {
  final router = Router();

  // ---------- health ----------
  router.get('/health', (Request request) {
    return _json({
      'status': 'ok',
      'uptimeSeconds': DateTime.now()
          .toUtc()
          .difference(ctx.startedAt)
          .inSeconds,
      'time': DateTime.now().toUtc().toIso8601String(),
    });
  });

  // ---------- auth ----------
  router.post('/auth/register', (Request request) async {
    final body = await readJsonBody(request.read());
    Validators.requireString(body, 'username', min: 3, max: 40);
    Validators.requireEmail(body);
    Validators.requirePassword(body);

    final email = (body['email'] as String).trim();
    final existing = await ctx.users.findByEmail(email);
    if (existing != null) {
      throw const ApiException(409, 'Email já registado.');
    }

    // Campo opcional: inviteCode para admin
    final inviteCode = (body['inviteCode'] as String?)?.trim();
    final isAdmin = inviteCode == 'FLUTTER_ADMIN_2024';

    final user = await ctx.users.create(
      username: body['username'] as String,
      email: email,
      password: body['password'] as String,
      isAdmin: isAdmin,
    );
    final token = await ctx.tokens.issue(user.id);
    return _json({
      'token': token,
      'user': user.toPublicJson(),
    }, status: 201);
  });

  router.post('/auth/login', (Request request) async {
    final body = await readJsonBody(request.read());
    Validators.requireEmail(body);
    Validators.requirePassword(body);

    final user = await ctx.users.findByEmail(body['email'] as String);
    if (user == null) {
      throw const ApiException(401, 'Email ou senha inválidos.');
    }
    final verified = await ctx.users.verify(user, body['password'] as String);
    if (verified == null) {
      throw const ApiException(401, 'Email ou senha inválidos.');
    }
    final token = await ctx.tokens.issue(user.id);
    return _json({
      'token': token,
      'user': user.toPublicJson(),
    });
  });

  router.post('/auth/logout', (Request request) async {
    final token = _bearer(request);
    if (token.isNotEmpty) await ctx.tokens.revoke(token);
    return _json({'ok': true});
  });

  router.get('/auth/me', (Request request) async {
    final user = await _requireUser(ctx, request);
    return _json({'user': user.toPublicJson()});
  });

  // ---------- lessons (public read) ----------
  router.get('/lessons', (Request request) async {
    final lessons = await ctx.lessons.all();
    return _json({
      'lessons': lessons,
      'totalXp': LessonService.totalXp(lessons),
    });
  });

  router.get('/lessons/<index|[0-9]+>', (Request request, String index) async {
    final lesson = await ctx.lessons.byIndex(int.parse(index));
    if (lesson == null) {
      throw const ApiException(404, 'Lição não encontrada.');
    }
    return _json({'lesson': lesson});
  });

  // ---------- lessons (admin write) ----------
  router.post('/lessons', (Request request) async {
    final admin = await _requireAdmin(ctx, request);
    final body = await readJsonBody(request.read());
    Validators.requireString(body, 'title', min: 1, max: 100);
    Validators.requireString(body, 'concept', min: 1, max: 500);
    // exercises é opcional no create, pode ser vazio
    final exercises = body['exercises'];
    if (exercises != null && exercises is! List) {
      throw const ApiException(400, 'Campo "exercises" deve ser uma lista.');
    }

    final lessons = await ctx.store.readList('lessons');
    final newIndex = lessons.isEmpty ? 1 : (lessons.last['index'] as int) + 1;
    
    final lesson = <String, dynamic>{
      'index': newIndex,
      'title': (body['title'] as String).trim(),
      'concept': (body['concept'] as String).trim(),
      'exercises': exercises ?? [],
      'createdBy': admin.id,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    
    lessons.add(lesson);
    await ctx.store.writeList('lessons', lessons);
    
    return _json({'lesson': lesson}, status: 201);
  });

  router.patch('/lessons/<index|[0-9]+>', (Request request, String index) async {
    await _requireAdmin(ctx, request);
    final body = await readJsonBody(request.read());
    
    final lessons = await ctx.store.readList('lessons');
    final lessonIndex = lessons.indexWhere(
      (l) => l is Map && l['index'] == int.parse(index),
    );
    if (lessonIndex == -1) {
      throw const ApiException(404, 'Lição não encontrada.');
    }
    
    final lesson = Map<String, dynamic>.from(lessons[lessonIndex]);
    
    if (body.containsKey('title')) {
      Validators.requireString(body, 'title', min: 1, max: 100);
      lesson['title'] = (body['title'] as String).trim();
    }
    if (body.containsKey('concept')) {
      Validators.requireString(body, 'concept', min: 1, max: 500);
      lesson['concept'] = (body['concept'] as String).trim();
    }
    if (body.containsKey('exercises')) {
      final exercises = body['exercises'];
      if (exercises is! List) {
        throw const ApiException(400, 'Campo "exercises" deve ser uma lista.');
      }
      lesson['exercises'] = exercises;
    }
    
    lesson['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    lessons[lessonIndex] = lesson;
    await ctx.store.writeList('lessons', lessons);
    
    return _json({'lesson': lesson});
  });

  router.delete('/lessons/<index|[0-9]+>', (Request request, String index) async {
    await _requireAdmin(ctx, request);
    
    final lessons = await ctx.store.readList('lessons');
    final lessonIndex = lessons.indexWhere(
      (l) => l is Map && l['index'] == int.parse(index),
    );
    if (lessonIndex == -1) {
      throw const ApiException(404, 'Lição não encontrada.');
    }
    
    lessons.removeAt(lessonIndex);
    await ctx.store.writeList('lessons', lessons);
    
    return _json({'ok': true});
  });

  // ---------- transactions ----------
  router.get('/transactions', (Request request) async {
    final user = await _requireUser(ctx, request);
    final all = await ctx.store.readList('transactions');
    final mine = all
        .whereType<Map<String, dynamic>>()
        .where((t) => t['userId'] == user.id)
        .toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    var income = 0.0;
    var expense = 0.0;
    for (final t in mine) {
      final amount = (t['amount'] as num).toDouble();
      if (t['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return _json({
      'transactions': mine,
      'summary': {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      },
    });
  });

  router.post('/transactions', (Request request) async {
    final user = await _requireUser(ctx, request);
    final body = await readJsonBody(request.read());
    Validators.requireString(body, 'description', min: 1, max: 120);
    final amount = Validators.requireAmount(body);
    final type = Validators.requireEnum(
      body,
      'type',
      const ['income', 'expense'],
    );
    final category = (body['category'] as String?)?.trim();
    final dateRaw = body['date'] as String?;
    final date = dateRaw == null
        ? DateTime.now().toUtc()
        : DateTime.tryParse(dateRaw)?.toUtc();
    if (date == null) {
      throw const ApiException(400, 'Data inválida.');
    }

    final transaction = await ctx.store.mutateList<Map<String, dynamic>>(
      'transactions',
      (items) async {
        final record = <String, dynamic>{
          'id': 't_${DateTime.now().microsecondsSinceEpoch}',
          'userId': user.id,
          'description': (body['description'] as String).trim(),
          'amount': amount,
          'type': type,
          'category':
              (category == null || category.isEmpty) ? 'Outros' : category,
          'date': date.toIso8601String(),
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        };
        items.add(record);
        return record;
      },
    );
    return _json({'transaction': transaction}, status: 201);
  });

  router.delete('/transactions/<id>', (Request request, String id) async {
    final user = await _requireUser(ctx, request);
    final removed = await ctx.store.mutateList<bool>('transactions', (
      items,
    ) async {
      final before = items.length;
      items.removeWhere(
        (e) =>
            e is Map<String, dynamic> &&
            e['id'] == id &&
            e['userId'] == user.id,
      );
      return items.length != before;
    });
    if (!removed) {
      throw const ApiException(404, 'Transação não encontrada.');
    }
    return _json({'ok': true});
  });

  router.delete('/transactions', (Request request) async {
    final user = await _requireUser(ctx, request);
    await ctx.store.mutateList('transactions', (items) async {
      items.removeWhere(
        (e) => e is Map<String, dynamic> && e['userId'] == user.id,
      );
      return null;
    });
    return _json({'ok': true});
  });

  // ---------- progress (XP) ----------
  router.get('/progress', (Request request) async {
    final user = await _requireUser(ctx, request);
    final lessons = await ctx.lessons.all();
    final totalXp = LessonService.totalXp(lessons);
    return _json({
      'xp': user.xp,
      'totalXp': totalXp,
      'level': (user.xp ~/ 100) + 1,
      'lessonsAvailable': lessons.length,
    });
  });

  router.post('/progress/xp', (Request request) async {
    final user = await _requireUser(ctx, request);
    final body = await readJsonBody(request.read());
    final raw = body['xp'];
    final delta = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (delta == null || delta < 1 || delta > 500) {
      throw const ApiException(400, 'XP deve ser um inteiro entre 1 e 500.');
    }
    final lessons = await ctx.lessons.all();
    final cap = LessonService.totalXp(lessons);
    final newXp = (user.xp + delta).clamp(0, cap);
    await ctx.users.save(user.copyWith(xp: newXp));
    return _json({
      'xp': newXp,
      'totalXp': cap,
      'gained': newXp - user.xp,
    });
  });

  // ---------- fallback ----------
  router.all('/<ignored|.*>', (Request request) {
    throw const ApiException(404, 'Rota não encontrada.');
  });

  return router.call;
}