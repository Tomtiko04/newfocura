import express from 'express';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { planningService } from '../services/planningService';
import { logger } from '../utils/logger';

const router = express.Router();

// Generate daily schedule
router.post('/generate', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { date } = req.body;
    const targetDate = date ? new Date(date) : new Date();

    const schedule = await planningService.generateDailySchedule(req.userId, targetDate);

    res.json(schedule);
  } catch (error) {
    logger.error('Generate schedule error:', error);
    res.status(500).json({ error: 'Failed to generate schedule' });
  }
});

// Get today's schedule
router.get('/today', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const schedule = await planningService.generateDailySchedule(req.userId, today);

    res.json(schedule);
  } catch (error) {
    logger.error('Get schedule error:', error);
    res.status(500).json({ error: 'Failed to get schedule' });
  }
});

export default router;

