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
  startDate: z.string().optional().nullable(), // relaxed: allow plain ISO without offset
  endDate: z.string().optional().nullable(),   // relaxed
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

    logger.info('Create yearly goal request', { userId: req.userId, body: req.body });
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

    logger.info('Update yearly goal request', { userId: req.userId, body: req.body, id: req.params.id });
    const payload = yearlyGoalSchema.partial().extend({
      status: z.enum(['draft', 'analyzed', 'finalized']).optional(),
      feasibilityScore: z.number().optional(),
      feasibilityComment: z.string().optional(),
      strategicPivot: z.string().optional(),
      estimatedHours: z.number().optional(),
      priorityOrder: z.number().int().optional(),
    }).parse(req.body);

    const updated = await prisma.yearlyGoal.updateMany({
      where: { id: req.params.id, userId: req.userId },
      data: {
        ...('title' in payload ? { title: payload.title } : {}),
        ...('why' in payload ? { why: payload.why } : {}),
        ...('startDate' in payload
            ? { startDate: payload.startDate ? new Date(payload.startDate) : null }
            : {}),
        ...('endDate' in payload
            ? { endDate: payload.endDate ? new Date(payload.endDate) : null }
            : {}),
        ...('status' in payload ? { status: payload.status } : {}),
        ...('feasibilityScore' in payload ? { feasibilityScore: payload.feasibilityScore } : {}),
        ...('feasibilityComment' in payload ? { feasibilityComment: payload.feasibilityComment } : {}),
        ...('strategicPivot' in payload ? { strategicPivot: payload.strategicPivot } : {}),
        ...('estimatedHours' in payload ? { estimatedHours: payload.estimatedHours } : {}),
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

    logger.info('Batch feasibility request', { userId: req.userId, body: req.body });

    const { goals } = batchSchema.parse(req.body);

    const now = new Date();
    const defaultEnd = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);

    try {
      // Perform holistic portfolio analysis in a single AI request
      const { results: portfolioResults, summary } = await geminiService.analyzeGoalPortfolio(
        goals.map(g => ({
          title: g.title,
          why: g.why,
          deadline: g.endDate ? new Date(g.endDate) : defaultEnd,
        })),
        {
          currentLoad: 0, // Could be fetched from DB if needed
          weeklyHours: 40,
        }
      );

      // Map portfolio results back to the requested goals to maintain original metadata
      const results = goals.map(originalGoal => {
        const analysis = portfolioResults.find(r => r.title === originalGoal.title);
        
        return {
          title: originalGoal.title,
          why: originalGoal.why,
          startDate: originalGoal.startDate,
          endDate: originalGoal.endDate,
          feasibilityScore: analysis?.score ?? 0,
          feasibilityComment: analysis?.analysis ?? 'Analysis missing for this goal.',
          strategicPivot: analysis?.pivot || null,
          estimatedHours: analysis?.estimatedHours,
        };
      });

      res.json({ results, summary });
    } catch (error) {
      logger.error('Yearly goals portfolio analysis error:', error);
      res.status(500).json({ error: 'Failed to analyze goal portfolio' });
    }
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Yearly goals feasibility route error:', error);
    res.status(500).json({ error: 'Internal server error during analysis' });
  }
});

export default router;

