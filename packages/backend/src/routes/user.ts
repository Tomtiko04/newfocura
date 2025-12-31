import express from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();
const prisma = new PrismaClient();

const onboardingSchema = z.object({
  weekdayFocusHours: z.number().min(0).max(24),
  weekendFocusHours: z.number().min(0).max(24),
  energyChronotype: z.enum(['morning', 'afternoon', 'night']),
  lifeSeason: z.enum(['push', 'sustainability']),
  reliabilityScore: z.number().min(1).max(5),
  antiGoals: z.array(z.string()),
});

// Update onboarding profile
router.put('/onboarding', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const payload = onboardingSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...payload,
        onboardingCompleted: true,
      },
    });

    res.json({
      message: 'Onboarding completed successfully',
      user: {
        id: user.id,
        onboardingCompleted: user.onboardingCompleted,
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Onboarding update error:', error);
    res.status(500).json({ error: 'Failed to update onboarding profile' });
  }
});

// Get current reality context
router.get('/reality', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: {
        weekdayFocusHours: true,
        weekendFocusHours: true,
        energyChronotype: true,
        lifeSeason: true,
        reliabilityScore: true,
        antiGoals: true,
        onboardingCompleted: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    logger.error('Fetch reality context error:', error);
    res.status(500).json({ error: 'Failed to fetch reality context' });
  }
});

export default router;

