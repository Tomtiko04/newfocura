# Focura - Your Personal Planning Assistant

A neuro-optimized productivity app that bridges paper planning with AI intelligence.

## Architecture

Monorepo structure with three main packages:
- `packages/mobile` - Flutter app (iOS/Android)
- `packages/backend` - Node.js/TypeScript API server
- `packages/shared` - Shared types and utilities

## Technology Stack

- **Frontend**: Flutter with Riverpod
- **Backend**: Node.js with TypeScript, Express
- **Database**: PostgreSQL (Prisma ORM) + Pinecone (vector embeddings)
- **AI**: Google Gemini 3 Flash API
- **Auth**: JWT tokens + OAuth (Google/Apple)

## Getting Started

### Prerequisites

- Node.js >= 18.0.0
- Flutter SDK >= 3.0.0
- Docker (for local PostgreSQL)
- PostgreSQL client (optional, for direct DB access)

### Installation

1. Install root dependencies:
```bash
npm install
```

2. Set up backend:
```bash
cd packages/backend
npm install
cp .env.example .env
# Edit .env with your API keys
```

3. Start PostgreSQL with Docker:
```bash
cd packages/backend
docker-compose up -d
```

4. Run database migrations:
```bash
npm run db:migrate
```

5. Set up Flutter app:
```bash
cd packages/mobile
flutter pub get
```

### Development

Start backend server:
```bash
npm run dev:backend
```

Run Flutter app:
```bash
npm run dev:mobile
```

## Environment Variables

See `packages/backend/.env.example` for required environment variables.

## Project Structure

```
.
├── packages/
│   ├── mobile/          # Flutter app
│   ├── backend/         # Node.js API server
│   └── shared/          # Shared TypeScript types
├── package.json         # Workspace configuration
└── README.md
```

## Features

- **Snap Engine**: Photo capture → AI extraction → Task/Goal/Reflection parsing
- **Goal Hierarchy**: 1-year goals with feasibility scoring
- **Daily Planning Loop**: AI-generated schedules with circadian recalibration
- **Daily Morning Sync**: Circadian anchor with sleep debt analysis
- **PFC Shield**: Unplanned event handling with strategic sacrifice
- **1% Better Momentum**: Consistency tracking and neuro-feedback loops

