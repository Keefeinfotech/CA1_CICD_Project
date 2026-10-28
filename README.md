# Auxilia

Automates administrative tasks, tracks progress, and delivers timely updates so you can spend less time managing work and more time with the people you love. Built with Flutter, Express.js, MongoDB, Docker, and GitHub Actions.

## Project Structure
- `backend/` - Node.js + Express + TypeScript API
- `frontend/` - Flutter application

## Quick Start

### Backend
```bash
cd backend
npm install
cp .env.example .env  # configure values
npm run dev
```

API: http://localhost:3000, Docs: http://localhost:3000/api-docs, Health: http://localhost:3000/api/health

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## Testing
- Backend: `cd backend && npm test` (Vitest)
- Frontend: `cd frontend && flutter test`

## CI/CD
- GitHub Actions workflow in `.github/workflows/ci.yml` runs on pushes/PRs to `main`, `develop`, `feature/**`, `release/**`, `hotfix/**`
- Use feature branches off `develop`/`main` as appropriate; open PRs to target branches
- Jenkinsfile not present currently - document if added later

## Security
See [SECURITY.md](SECURITY.md). Never commit `.env` files.
