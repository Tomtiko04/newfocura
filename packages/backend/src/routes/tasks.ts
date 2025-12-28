import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';
import { z } from 'zod';

const router = express.Router();
const prisma = new PrismaClient();

const createTaskSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  priority: z.number().min(1).max(5).optional(),
  energyRequirement: z.enum(['High', 'Medium', 'Low']).optional(),
  implementationIntention: z.string().optional(),
  goalId: z.string().optional(),
  subtasks: z.array(z.object({
    title: z.string(),
    durationEstimate: z.number().max(15),
  })).optional(),
});

// Create task
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const data = createTaskSchema.parse(req.body);
    const { subtasks, ...taskData } = data;

    const task = await prisma.task.create({
      data: {
        ...taskData,
        userId: req.userId,
        priority: data.priority || 3,
        energyRequirement: data.energyRequirement || 'Medium',
        implementationIntention: data.implementationIntention || '',
      },
    });

    // Create subtasks if provided
    if (subtasks && subtasks.length > 0) {
      await prisma.subtask.createMany({
        data: subtasks.map(st => ({
          taskId: task.id,
          title: st.title,
          durationEstimate: st.durationEstimate,
        })),
      });
    }

    const taskWithSubtasks = await prisma.task.findUnique({
      where: { id: task.id },
      include: { subtasks: true },
    });

    res.status(201).json(taskWithSubtasks);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    logger.error('Create task error:', error);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// Get all tasks
router.get('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { status, energyRequirement } = req.query;

    const tasks = await prisma.task.findMany({
      where: {
        userId: req.userId,
        ...(status && { status: status as string }),
        ...(energyRequirement && { energyRequirement: energyRequirement as string }),
      },
      include: {
        subtasks: true,
      },
      orderBy: [
        { priority: 'desc' },
        { createdAt: 'desc' },
      ],
    });

    res.json(tasks);
  } catch (error) {
    logger.error('Get tasks error:', error);
    res.status(500).json({ error: 'Failed to get tasks' });
  }
});

// Get task by ID
router.get('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      include: {
        subtasks: true,
      },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.json(task);
  } catch (error) {
    logger.error('Get task error:', error);
    res.status(500).json({ error: 'Failed to get task' });
  }
});

// Update task
router.put('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { title, description, priority, status, energyRequirement, implementationIntention } = req.body;

    const task = await prisma.task.updateMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
      data: {
        ...(title && { title }),
        ...(description !== undefined && { description }),
        ...(priority && { priority }),
        ...(status && { status, ...(status === 'completed' && { completedAt: new Date() }) }),
        ...(energyRequirement && { energyRequirement }),
        ...(implementationIntention && { implementationIntention }),
      },
    });

    if (task.count === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const updatedTask = await prisma.task.findUnique({
      where: { id: req.params.id },
      include: { subtasks: true },
    });

    res.json(updatedTask);
  } catch (error) {
    logger.error('Update task error:', error);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// Complete subtask
router.post('/:id/subtasks/:subtaskId/complete', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Verify task belongs to user
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const subtask = await prisma.subtask.update({
      where: {
        id: req.params.subtaskId,
        taskId: req.params.id,
      },
      data: {
        status: 'completed',
        completedAt: new Date(),
      },
    });

    res.json(subtask);
  } catch (error) {
    logger.error('Complete subtask error:', error);
    res.status(500).json({ error: 'Failed to complete subtask' });
  }
});

// Delete task
router.delete('/:id', authenticateToken, async (req: AuthRequest, res) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const task = await prisma.task.deleteMany({
      where: {
        id: req.params.id,
        userId: req.userId,
      },
    });

    if (task.count === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Delete task error:', error);
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

export default router;

