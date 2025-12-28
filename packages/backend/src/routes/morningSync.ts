import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { geminiService } from '../services/geminiService';
import { logger } from '../utils/logger';
import { z } from 'zod';

const router = express.Router();
const prisma = new PrismaClient();

const morningSyncSchema = z.object({
  sleepTime: z.string().datetime(),
  wakeTime: z.string().datetime(),
  initialFocus: z.number().min(1).max(5),
});

// Submit morning sync
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { sleepTime, wakeTime, initialFocus } = morningSyncSchema.parse(req.body);

    // Get user's average sleep hours from energy patterns
    const energyPattern = await prisma.energyPattern.findFirst({
      where: { userId: req.userId },
    });

    // Analyze with Gemini
    const analysis = await geminiService.analyzeMorningSync({
      sleepTime: new Date(sleepTime),
      wakeTime: new Date(wakeTime),
      initialFocus,
      averageSleepHours: energyPattern?.averageSleepHours,
    });

    // Store in DailyBioSync
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bioSync = await prisma.dailyBioSync.upsert({
      where: {
        userId_date: {
          userId: req.userId,
          date: today,
        },
      },
      create: {
        userId: req.userId,
        date: today,
        sleepTime: new Date(sleepTime),
        wakeTime: new Date(wakeTime),
        initialFocus,
        sleepDebt: analysis.sleepDebt,
        sleepInertia: analysis.sleepInertia,
        energyBaseline: analysis.energyBaseline,
      },
      update: {
        sleepTime: new Date(sleepTime),
        wakeTime: new Date(wakeTime),
        initialFocus,
        sleepDebt: analysis.sleepDebt,
        sleepInertia: analysis.sleepInertia,
        energyBaseline: analysis.energyBaseline,
      },
    });

    res.json({
      bioSync,
      analysis: analysis.recommendedSchedule,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Morning sync error:', error);
    res.status(500).json({ error: 'Failed to process morning sync' });
  }
});

// Get today's morning sync
router.get('/today', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bioSync = await prisma.dailyBioSync.findUnique({
      where: {
        userId_date: {
          userId: req.userId,
          date: today,
        },
      },
    });

    res.json(bioSync || null);
  } catch (error) {
    logger.error('Get morning sync error:', error);
    res.status(500).json({ error: 'Failed to get morning sync' });
  }
});

// Record actual peak
router.post('/peaks', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { timestamp } = req.body;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bioSync = await prisma.dailyBioSync.findUnique({
      where: {
        userId_date: {
          userId: req.userId,
          date: today,
        },
      },
    });

    if (!bioSync) {
      return res.status(404).json({ error: 'Morning sync not found. Please complete morning sync first.' });
    }

    const actualPeaks = (bioSync.actualPeaks as Date[] || []) as any[];
    actualPeaks.push(new Date(timestamp));

    await prisma.dailyBioSync.update({
      where: { id: bioSync.id },
      data: {
        actualPeaks: actualPeaks,
      },
    });

    res.json({ success: true });
  } catch (error) {
    logger.error('Record peak error:', error);
    res.status(500).json({ error: 'Failed to record peak' });
  }
});

export default router;

