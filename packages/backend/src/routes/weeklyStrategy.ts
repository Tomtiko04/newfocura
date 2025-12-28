import express from 'express';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { weeklyStrategyService } from '../services/weeklyStrategyService';
import { logger } from '../utils/logger';

const router = express.Router();

// Generate weekly strategy
router.post('/generate', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { weekStart } = req.body;
    const startDate = weekStart ? new Date(weekStart) : new Date();

    const strategy = await weeklyStrategyService.generateWeeklyStrategy(req.userId, startDate);

    res.json(strategy);
  } catch (error) {
    logger.error('Generate weekly strategy error:', error);
    res.status(500).json({ error: 'Failed to generate weekly strategy' });
  }
});

export default router;

