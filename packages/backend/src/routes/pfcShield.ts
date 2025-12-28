import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { geminiService } from '../services/geminiService';
import { planningService } from '../services/planningService';
import { logger } from '../utils/logger';
import { z } from 'zod';

const router = express.Router();
const prisma = new PrismaClient();

const restructureSchema = z.object({
  interruption: z.object({
    nature: z.string(),
    duration: z.number(), // minutes
  }),
});

// Restructure today's schedule (PFC Shield)
router.post('/restructure', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { interruption } = restructureSchema.parse(req.body);

    // Get remaining tasks for today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const remainingTasks = await prisma.task.findMany({
      where: {
        userId: req.userId,
        status: { in: ['pending', 'in_progress'] },
        scheduledTime: {
          gte: today,
          lt: tomorrow,
        },
      },
      include: {
        subtasks: true,
      },
    });

    // Get priority goal
    const priorityGoal = await prisma.goal.findFirst({
      where: {
        userId: req.userId,
        status: 'active',
      },
      orderBy: {
        feasibilityScore: 'desc',
      },
    });

    // Calculate remaining hours
    const currentTime = new Date();
    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59);
    const remainingHours = (endOfDay.getTime() - currentTime.getTime()) / (1000 * 60 * 60);

    // Get restructure recommendation from Gemini
    const restructure = await geminiService.restructureSchedule({
      remainingTasks: remainingTasks.map(t => ({
        id: t.id,
        title: t.title,
        energyRequirement: t.energyRequirement,
        priority: t.priority,
      })),
      interruption,
      currentTime,
      remainingHours,
      priorityGoal: priorityGoal ? {
        id: priorityGoal.id,
        title: priorityGoal.title,
      } : undefined,
    });

    // Update tasks with new schedule
    for (const restructuredTask of restructure.restructuredTasks) {
      await prisma.task.update({
        where: { id: restructuredTask.taskId },
        data: {
          scheduledTime: new Date(restructuredTask.newTime),
          scheduledEnergyWindow: restructuredTask.energyWindow,
        },
      });
    }

    // Mark dropped tasks as cancelled
    if (restructure.droppedTasks.length > 0) {
      await prisma.task.updateMany({
        where: {
          id: { in: restructure.droppedTasks },
        },
        data: {
          status: 'cancelled',
        },
      });
    }

    // Create micro-win task if suggested
    if (restructure.microWin) {
      const microWinTask = await prisma.task.create({
        data: {
          userId: req.userId,
          title: restructure.microWin.description,
          priority: 5, // Highest priority
          energyRequirement: 'High',
          implementationIntention: `If it is ${currentTime.toLocaleTimeString()}, then I will spend ${restructure.microWin.duration} minutes on this micro-win.`,
          scheduledTime: currentTime,
          scheduledEnergyWindow: 'morning_peak',
        },
      });

      restructure.microWin.taskId = microWinTask.id;
    }

    res.json({
      success: true,
      restructuredTasks: restructure.restructuredTasks,
      droppedTasks: restructure.droppedTasks,
      microWin: restructure.microWin,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('PFC Shield restructure error:', error);
    res.status(500).json({ error: 'Failed to restructure schedule' });
  }
});

export default router;

