# Auxilia

Auxilia is an offline-first task manager with optional accounts and an AI
assistant. Tasks, XP, and achievements work without a network connection; the
backend provides authentication and the AI endpoint.

Built with Flutter, Express.js, TypeScript, MongoDB, and GitHub Actions.

## Prerequisites

- Flutter 3.47.8 (Dart 3.13 or newer)
- Node.js 22.12 or newer
- A MongoDB instance for the backend

## Features

- Create, edit, complete, and delete tasks with priority, notes, and due dates.
- Search, filter by status, and page through tasks (20 per page).
- XP and levels based on completed priority; achievements for milestones.
- Guest mode with local tasks; optional sign-up and sign-in for the assistant.
- AI assistant screen backed by the API (mock provider by default).
- Responsive layout, semantic labels, and support for 200% text scaling.

## Architecture

```
Flutter app ── local storage (shared_preferences)  -> tasks, offline-first
     │
     └── HTTPS ── Express API ── MongoDB              -> accounts
                     └────────── AI endpoint          -> assistant replies
```

- Tasks are stored on the device and are never uploaded. Guest data uses the
  owner key `local`; signed-in data uses the account email.
- The backend owns accounts only: signup, login, and the protected AI route.
- Sign-in tokens live in platform secure storage, not in preferences.

## Project structure

```
backend/   Express + TypeScript API (auth, AI, health, Swagger in dev)
frontend/  Flutter application (screens, widgets, services, local storage)
docs/      Release gates, release checklist, privacy, dependencies
.github/   CI workflow
```

## Quick start

### Backend

```bash
cd backend
npm ci
cp .env.example .env    # Windows: Copy-Item .env.example .env
npm run dev
```

Set a `JWT_SECRET` of at least 16 characters in `.env`. The API refuses to
start without it.

- API: http://localhost:3000
- Health: http://localhost:3000/api/health
- Swagger UI (development only): http://localhost:3000/api-docs

`MONGODB_URI` must point at a reachable MongoDB instance.

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

`API_BASE_URL` defaults to `http://localhost:3000`. For a deployed build, pass
the public HTTPS URL. Tasks work without the backend; sign-in and the assistant
need it.

## API

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/health` | No | Liveness check |
| POST | `/api/auth/signup` | No | Create an account; returns `{ token, user }` (201) |
| POST | `/api/auth/login` | No | Sign in; returns `{ token, user }` |
| POST | `/api/ai/chat` | Bearer | Send `{ message }` (1-1000 chars) and receive `{ reply }` |

Errors use `{ error, code, details? }`. Validation failures return `400` with
`code: "VALIDATION_ERROR"`; protected routes return `401` without a valid token.

### Configuration

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | `3000` | HTTP port |
| `NODE_ENV` | `development` | `production` disables Swagger UI |
| `MONGODB_URI` | - | Required to start |
| `JWT_SECRET` | - | Required, at least 16 characters |
| `JWT_EXPIRES_IN` | `1d` | Token lifetime |
| `BCRYPT_ROUNDS` | `10` | Clamped to 10-15 |
| `CORS_ORIGIN` | `http://localhost:3000,http://localhost:5173` | Comma-separated allowlist |
| `AI_PROVIDER` | `mock` | Any other value returns `501` until a provider is implemented |
| `AI_MODEL` | `mock-model` | Echoed in mock responses |
| `AI_MAX_TOKENS` | `512` | Reserved for a future provider |
| `AI_API_KEY` | empty | Reserved for a future provider |
| `AI_RATE_LIMIT_PER_USER` | `20` | AI requests per hour per client |

Auth requests are limited to 10 per 15 minutes per client. Request bodies are
capped at 10 kb.

## Data and privacy

Tasks stay on the device. Accounts store a name (optional), email, and bcrypt
password hash. See [docs/PRIVACY.md](docs/PRIVACY.md) for the full data
inventory, deletion paths, and the AI data flow.

## Testing

```bash
cd backend
npm run typecheck
npm run test:coverage     # 31 tests, coverage thresholds enforced
npm run build

cd ../frontend
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage  # 58 tests, including accessibility checks
flutter build web --release
```

Frontend tests cover the model, validation, XP/levels, repository, store, task
card, dashboard flows, and a 200% text-scale layout. Platform storage is faked
in tests, so no emulator is required.

## CI/CD

`.github/workflows/ci.yml` runs on pushes to `main`, `develop`, `feature/**`,
`release/**`, and `hotfix/**`, and on pull requests to `main`, `develop`, and
`release/**`. Superseded runs are cancelled.

| Job | Checks |
|-----|--------|
| `security-scan` | Trivy filesystem scan (CRITICAL/HIGH), SARIF uploaded to code scanning (report-only) |
| `backend` | `npm ci`, typecheck, tests with coverage, build; coverage artifact |
| `frontend` | Flutter 3.47.8, `pub get`, format check, `flutter analyze`, tests with coverage, web release build; coverage artifact |

Backend coverage gates: 80% statements/lines/functions, 60% branches. Full gate
definitions are in [docs/NFR_RELEASE_GATES.md](docs/NFR_RELEASE_GATES.md); use
[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) before tagging a release.

## Accessibility

- Status is shown with text and icons, never colour alone.
- Task cards expose a summary label and a labelled completion control.
- Icon-only actions have tooltips.
- Layouts are tested at 200% text scaling on a 360 px-wide viewport.

## Limitations

- No account deletion in the app yet; contact the maintainer.
- No server-side task sync; tasks are per-device and per-owner.
- The AI provider is a mock; a real provider must be implemented behind the
  existing endpoint.
- Swagger UI is intentionally unavailable when `NODE_ENV=production`.

## Documentation

- [Release gates](docs/NFR_RELEASE_GATES.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [Privacy notice](docs/PRIVACY.md)
- [Dependencies](docs/DEPENDENCIES.md)
- [Security policy](SECURITY.md)
