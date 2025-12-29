import express from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { geminiService } from '../services/geminiService';
import { logger } from '../utils/logger';

const router = express.Router();
const prisma = new PrismaClient();

const yearlyGoalSchema = z.object({
  title: z.string().min(1),
  why: z.string().optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
});

const batchSchema = z.object({
  goals: z.array(yearlyGoalSchema).min(1),
});

// Create yearly goal (draft)
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const payload = yearlyGoalSchema.parse(req.body);
    const now = new Date();
    const defaultStart = new Date(now.getFullYear(), 0, 1);
    const defaultEnd = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);

    const goal = await prisma.yearlyGoal.create({
      data: {
        userId: req.userId,
        title: payload.title,
        why: payload.why,
        startDate: payload.startDate ? new Date(payload.startDate) : defaultStart,
        endDate: payload.endDate ? new Date(payload.endDate) : defaultEnd,
        status: 'draft',
      },
    });

    res.status(201).json(goal);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Create yearly goal error:', error);
    res.status(500).json({ error: 'Failed to create yearly goal' });
  }
});

// List yearly goals
router.get('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const goals = await prisma.yearlyGoal.findMany({
      where: { userId: req.userId },
      orderBy: [{ priorityOrder: 'asc' }, { createdAt: 'desc' }],
    });

    res.json(goals);
  } catch (error) {
    logger.error('List yearly goals error:', error);
    res.status(500).json({ error: 'Failed to fetch yearly goals' });
  }
});

// Update yearly goal
router.put('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const payload = yearlyGoalSchema.partial().extend({
      status: z.enum(['draft', 'analyzed', 'finalized']).optional(),
      feasibilityScore: z.number().optional(),
      feasibilityComment: z.string().optional(),
      strategicPivot: z.string().optional(),
      priorityOrder: z.number().int().optional(),
    }).parse(req.body);

    const updated = await prisma.yearlyGoal.updateMany({
      where: { id: req.params.id, userId: req.userId },
      data: {
        ...('title' in payload ? { title: payload.title } : {}),
        ...('why' in payload ? { why: payload.why } : {}),
        ...('startDate' in payload && payload.startDate ? { startDate: new Date(payload.startDate) } : {}),
        ...('endDate' in payload && payload.endDate ? { endDate: new Date(payload.endDate) } : {}),
        ...('status' in payload ? { status: payload.status } : {}),
        ...('feasibilityScore' in payload ? { feasibilityScore: payload.feasibilityScore } : {}),
        ...('feasibilityComment' in payload ? { feasibilityComment: payload.feasibilityComment } : {}),
        ...('strategicPivot' in payload ? { strategicPivot: payload.strategicPivot } : {}),
        ...('priorityOrder' in payload ? { priorityOrder: payload.priorityOrder } : {}),
      },
    });

    if (updated.count === 0) {
      return res.status(404).json({ error: 'Yearly goal not found' });
    }

    const goal = await prisma.yearlyGoal.findUnique({ where: { id: req.params.id } });
    res.json(goal);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Update yearly goal error:', error);
    res.status(500).json({ error: 'Failed to update yearly goal' });
  }
});

// Delete yearly goal
router.delete('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const deleted = await prisma.yearlyGoal.deleteMany({
      where: { id: req.params.id, userId: req.userId },
    });

    if (deleted.count === 0) {
      return res.status(404).json({ error: 'Yearly goal not found' });
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Delete yearly goal error:', error);
    res.status(500).json({ error: 'Failed to delete yearly goal' });
  }
});

// Batch feasibility analysis
router.post('/feasibility', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { goals } = batchSchema.parse(req.body);

    const results = [];
    const now = new Date();
    const defaultEnd = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);

    for (const goal of goals) {
      const feasibility = await geminiService.analyzeGoalFeasibility(
        {
          title: goal.title,
          description: '', // description removed; keep empty for model prompt
          deadline: goal.endDate ? new Date(goal.endDate) : defaultEnd,
        },
        {
          currentLoad: 0,
          weeklyHours: 40,
        }
      );

      results.push({
        title: goal.title,
        why: goal.why,
        startDate: goal.startDate,
        endDate: goal.endDate,
        feasibilityScore: feasibility.score,
        feasibilityComment: feasibility.analysis,
        strategicPivot: feasibility.pivot || null,
      });
    }

    res.json({ results });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Yearly goals feasibility error:', error);
    res.status(500).json({ error: 'Failed to analyze yearly goals' });
  }
});

export default router;

