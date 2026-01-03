import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { logger } from '../utils/logger';
import { z } from 'zod';

const router = Router();
const prisma = new PrismaClient();

const letterSchema = z.object({
  content: z.string().min(10),
  openAt: z.string().datetime().optional().nullable(),
});

/**
 * Create a letter to future self
 */
router.post('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { content, openAt } = letterSchema.parse(req.body);
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ error: 'User ID not found' });
    }

    // Default open date: end of current year
    const defaultOpenAt = new Date(new Date().getFullYear(), 11, 31, 23, 59, 59);
    
    const letter = await prisma.futureLetter.create({
      data: {
        userId,
        content,
        openAt: openAt ? new Date(openAt) : defaultOpenAt,
      },
    });

    res.status(201).json(letter);
  } catch (error) {
    logger.error('Create letter error:', error);
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid input', details: error.errors });
    }
    res.status(500).json({ error: 'Failed to create letter' });
  }
});

/**
 * Get user's letters (only those ready to open)
 */
router.get('/', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ error: 'User ID not found' });
    }

    const now = new Date();

    const letters = await prisma.futureLetter.findMany({
      where: {
        userId,
        openAt: {
          lte: now,
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.json(letters);
  } catch (error) {
    logger.error('Get letters error:', error);
    res.status(500).json({ error: 'Failed to fetch letters' });
  }
});

export default router;

