# Flutter Quest — Backend (Dart)

API REST em Dart puro com [`shelf`](https://pub.dev/packages/shelf). Sem Docker, sem
base de dados externa: dados num único ficheiro JSON com escrita atómica.

## Arrancar

```bash
cd backend
dart pub get
dart run bin/server.dart
# > Flutter Quest API a correr em http://0.0.0.0:8080
```

Variáveis de ambiente:

| Variável | Default | Descrição |
|---|---|---|
| `PORT` | `8080` | Porta HTTP |
| `HOST` | `0.0.0.0` | Interface |
| `DATA_DIR` | `data` | Pasta do `db.json` |
| `LESSONS_FILE` | `../assets/lessons/lessons.json` | Lições servidas pela API |

Exemplo:

```bash
PORT=9000 DATA_DIR=/var/lib/flutterquest dart run bin/server.dart
```

## Endpoints

### Públicos

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/health` | Estado do serviço + uptime |
| `GET` | `/lessons` | Todas as lições + `totalXp` |
| `GET` | `/lessons/:index` | Lição por índice |
| `POST` | `/auth/register` | `{username, email, password}` → `{token, user}` |
| `POST` | `/auth/login` | `{email, password}` → `{token, user}` |
| `POST` | `/auth/logout` | Revoga o token do header |

### Autenticados (`Authorization: Bearer <token>`)

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/auth/me` | Utilizador da sessão |
| `GET` | `/transactions` | Transações + resumo (`income`, `expense`, `balance`) |
| `POST` | `/transactions` | `{description, amount, type: income\|expense, category?, date?}` |
| `DELETE` | `/transactions/:id` | Remove uma transação |
| `DELETE` | `/transactions` | Limpa as transações do utilizador |
| `GET` | `/progress` | `xp`, `totalXp`, `level`, `lessonsAvailable` |
| `POST` | `/progress/xp` | `{xp: 1..500}` soma XP (limitado ao total disponível) |

### Exemplo rápido

```bash
TOKEN=$(curl -s -X POST localhost:8080/auth/register \
  -H 'content-type: application/json' \
  -d '{"username":"matheus","email":"matheus@teste.com","password":"senha123"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

curl -s localhost:8080/transactions -H "authorization: Bearer $TOKEN"
```

## Segurança

- Senhas: SHA-256 sobre `senha + salt` (16 chars hex aleatórios), igual ao
  `AuthService` do cliente. Nunca guardadas em claro.
- Tokens de sessão opacos (32 bytes `Random.secure`, base64url), TTL de 30 dias,
  persistidos em disco e revogáveis. Sessões expiradas são limpas no arranque.
- Comparação de hashes em tempo constante.
- Todas as transações são filtradas por `userId` — um utilizador não vê nem apaga
  dados de outro.
- CORS aberto (`access-control-allow-origin: *`) — restringir antes de produção.

## Estrutura

```
backend/
├── bin/server.dart          # arranque + config por env
├── lib/app.dart             # rotas shelf_router, middleware, CORS
├── lib/services.dart        # UserService, TokenService, LessonService, validadores
├── lib/store.dart           # JsonStore (JSON atómico + lock assíncrono)
└── lib/user_record.dart     # UserRecord + PasswordHasher
```
