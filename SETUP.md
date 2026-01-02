# Focura Setup Guide

## Prerequisites

- Node.js >= 18.0.0
- Flutter SDK >= 3.0.0
- Docker (for local PostgreSQL)
- PostgreSQL client (optional)

## Backend Setup

1. Navigate to backend directory:

```bash
cd packages/backend
```

2. Install dependencies:

```bash
npm install
```

3. Set up environment variables:

```bash
# Create .env file (copy from example if it exists, or create manually)
# The DATABASE_URL should match your docker-compose.yml PostgreSQL setup:
DATABASE_URL="postgresql://focura_user:password@localhost:5432/focura?schema=public"

# Add your API keys:
# - GEMINI_API_KEY
# - PINECONE_API_KEY
# - PINECONE_ENVIRONMENT
# - PINECONE_INDEX_NAME
# - JWT_SECRET
```

Or create `.env` file manually with:

```
DATABASE_URL="postgresql://user:password@localhost:5432/focura?schema=public"
GEMINI_API_KEY=your-gemini-api-key
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENVIRONMENT=your-pinecone-environment
PINECONE_INDEX_NAME=focura-reflections
JWT_SECRET=your-super-secret-jwt-key-change-in-production
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

4. Start PostgreSQL with Docker:

```bash
docker-compose up -d
```

5. Generate Prisma Client:

```bash
npm run db:generate
```

6. Run database migrations:

```bash
npm run db:migrate
```

Another method:

```bash
cd packages/backend
   npx prisma migrate dev --name add_yearly_goal_dates
   npx prisma generate
   # Deployment
   npx prisma db pull
   npx prisma migrate deploy
   $env:DATABASE_URL="postgresql://focuradb_user:I7ChpSAGUJOQC0oEY0ZjskhiHlxy0W7L@dpg-d5b881ngi27c738no9v0-a.oregon-postgres.render.com/focuradb"
```

7. Start the backend server:

```bash
npm run dev
```

The backend will be running on `http://localhost:3000`

## Frontend Setup

1. Navigate to mobile directory:

```bash
cd packages/mobile
```

2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Update API base URL in `lib/services/api_service.dart` if needed (default: `http://localhost:3000/api`)

4. Run the app:

```bash
flutter run
```

## Environment Variables

### Backend (.env)

Required:

- `DATABASE_URL` - PostgreSQL connection string
- `GEMINI_API_KEY` - Google Gemini API key
- `PINECONE_API_KEY` - Pinecone API key
- `PINECONE_ENVIRONMENT` - Pinecone environment
- `PINECONE_INDEX_NAME` - Pinecone index name
- `JWT_SECRET` - Secret for JWT token signing

Optional:

- `PORT` - Server port (default: 3000)
- `CORS_ORIGIN` - CORS origin (default: http://localhost:3000)
- `PRISMA_ACCELERATE_URL` - Prisma Accelerate URL for production scaling

## Database Schema

The Prisma schema includes:

- Users (with OAuth support)
- Goals (with feasibility scoring)
- Tasks (with subtasks and implementation intentions)
- Reflections (stored in both PostgreSQL and Pinecone)
- Snaps (photo processing history)
- Schedules (daily AI-generated schedules)
- DailyBioSync (circadian anchor data)
- MomentumScores (1% Better tracking)
- EnergyPatterns (user chronotype data)

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register with email/password
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/oauth/google` - Google OAuth (placeholder)
- `POST /api/auth/oauth/apple` - Apple OAuth (placeholder)
- `GET /api/auth/me` - Get current user

### Snap Processing

- `POST /api/snap/upload` - Upload and process image
- `GET /api/snap/:snapId/status` - Get snap processing status

### Goals

- `POST /api/goals` - Create goal (with feasibility analysis)
- `GET /api/goals` - Get all goals
- `GET /api/goals/:id` - Get goal by ID
- `PUT /api/goals/:id` - Update goal
- `DELETE /api/goals/:id` - Delete goal

### Tasks

- `POST /api/tasks` - Create task
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get task by ID
- `PUT /api/tasks/:id` - Update task
- `POST /api/tasks/:id/subtasks/:subtaskId/complete` - Complete subtask
- `DELETE /api/tasks/:id` - Delete task

### Morning Sync

- `POST /api/morning-sync` - Submit morning sync data
- `GET /api/morning-sync/today` - Get today's morning sync
- `POST /api/morning-sync/peaks` - Record actual energy peak

### Schedule

- `POST /api/schedule/generate` - Generate daily schedule
- `GET /api/schedule/today` - Get today's schedule

### PFC Shield

- `POST /api/pfc-shield/restructure` - Restructure schedule due to interruption

### Momentum

- `GET /api/momentum/today` - Get today's momentum score
- `POST /api/momentum/store` - Store momentum score

### Weekly Strategy

- `POST /api/weekly-strategy/generate` - Generate weekly strategy analysis

## Features Implemented

✅ Monorepo structure with shared types
✅ Backend API with Express and TypeScript
✅ Prisma ORM with PostgreSQL schema
✅ Authentication (email/password + OAuth placeholders)
✅ Snap processing with Gemini 3 Flash (MINIMAL thinking)
✅ Instant Pinecone vectorization
✅ Goal management with feasibility scoring (HIGH thinking)
✅ Task management with subtasks
✅ Daily Morning Sync with circadian anchor
✅ Daily schedule generation with dynamic weighting
✅ PFC Shield for unplanned events
✅ Momentum tracking (1% Better)
✅ Weekly strategy analysis (HIGH thinking)
✅ Flutter app with Riverpod
✅ FutureProvider for snap processing
✅ Adaptive UI with energy-based colors
✅ Paper-like theme

## Next Steps

- Implement full OAuth (Google/Apple)
- Complete Flutter screen implementations
- Add neuro-nudge notification system
- Implement voice analysis features
- Add accountability system (social features)
- Deploy to production
