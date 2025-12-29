import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { logger } from './utils/logger';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
import authRoutes from './routes/auth';
import snapRoutes from './routes/snap';
import goalRoutes from './routes/goals';
import taskRoutes from './routes/tasks';
import morningSyncRoutes from './routes/morningSync';
import pfcShieldRoutes from './routes/pfcShield';
import momentumRoutes from './routes/momentum';
import scheduleRoutes from './routes/schedule';
import weeklyStrategyRoutes from './routes/weeklyStrategy';
import yearlyGoalsRoutes from './routes/yearlyGoals';

// API v1 routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/snap', snapRoutes);
app.use('/api/v1/goals', goalRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/morning-sync', morningSyncRoutes);
app.use('/api/v1/pfc-shield', pfcShieldRoutes);
app.use('/api/v1/momentum', momentumRoutes);
app.use('/api/v1/schedule', scheduleRoutes);
app.use('/api/v1/weekly-strategy', weeklyStrategyRoutes);
app.use('/api/v1/yearly-goals', yearlyGoalsRoutes);

// Error handling middleware
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

