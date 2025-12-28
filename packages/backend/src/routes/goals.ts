import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { geminiService } from '../services/geminiService';
import { logger } from '../utils/logger';
import { z } from 'zod';

const router = express.Router();
const prisma = new PrismaClient();

const createGoalSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  deadline: z.string().datetime(),
});

// Create goal with feasibility analysis (HIGH thinking level)
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { title, description, deadline } = createGoalSchema.parse(req.body);

    // Get user's current load for feasibility analysis
    const taskCount = await prisma.task.count({
      where: {
        userId: req.userId,
        status: { in: ['pending', 'in_progress'] },
      },
    });

    // Analyze feasibility with HIGH thinking level
    const feasibility = await geminiService.analyzeGoalFeasibility(
      {
        title,
        description: description || '',
        deadline: new Date(deadline),
      },
      {
        currentLoad: taskCount,
        weeklyHours: 40, // Default, could be stored in user profile
      }
    );

    // Create goal
    const goal = await prisma.goal.create({
      data: {
        userId: req.userId,
        title,
        description,
        deadline: new Date(deadline),
        feasibilityScore: feasibility.score,
        feasibilityAnalysis: feasibility.analysis,
        strategicPivot: feasibility.pivot || null,
      },
    });

    res.status(201).json(goal);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Create goal error:', error);
    res.status(500).json({ error: 'Failed to create goal' });
  }
});

// Get all goals
router.get('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const goals = await prisma.goal.findMany({
      where: { userId: req.userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json(goals);
  } catch (error) {
    logger.error('Get goals error:', error);
    res.status(500).json({ error: 'Failed to get goals' });
  }
});

// Get goal by ID
router.get('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const goal = await prisma.goal.findFirst({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (!goal) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    res.json(goal);
  } catch (error) {
    logger.error('Get goal error:', error);
    res.status(500).json({ error: 'Failed to get goal' });
  }
});

// Update goal
router.put('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { title, description, deadline, status } = req.body;

    const goal = await prisma.goal.updateMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      data: {
        ...(title && { title }),
        ...(description !== undefined && { description }),
        ...(deadline && { deadline: new Date(deadline) }),
        ...(status && { status }),
      },
    });

    if (goal.count === 0) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    const updatedGoal = await prisma.goal.findUnique({
      where: { id: req.params.id },
    });

    res.json(updatedGoal);
  } catch (error) {
    logger.error('Update goal error:', error);
    res.status(500).json({ error: 'Failed to update goal' });
  }
});

// Delete goal
router.delete('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const goal = await prisma.goal.deleteMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (goal.count === 0) {
      return res.status(404).json({ error: 'Goal not found' });
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Delete goal error:', error);
    res.status(500).json({ error: 'Failed to delete goal' });
  }
});

export default router;

