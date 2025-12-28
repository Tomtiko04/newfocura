import express from 'express';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { momentumService } from '../services/momentumService';
import { logger } from '../utils/logger';

const router = express.Router();

// Get momentum score for today
router.get('/today', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const today = new Date();
    const score = await momentumService.calculateMomentumScore(req.userId, today);
    const feedback = momentumService.getNeuroFeedback(score);

    res.json({
      score,
      feedback,
    });
  } catch (error) {
    logger.error('Get momentum score error:', error);
    res.status(500).json({ error: 'Failed to get momentum score' });
  }
});

// Store momentum score (typically called at end of day)
router.post('/store', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { date } = req.body;
    const targetDate = date ? new Date(date) : new Date();

    await momentumService.storeMomentumScore(req.userId, targetDate);

    res.json({ success: true });
  } catch (error) {
    logger.error('Store momentum score error:', error);
    res.status(500).json({ error: 'Failed to store momentum score' });
  }
});

export default router;

