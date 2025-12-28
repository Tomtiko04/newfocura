import { PrismaClient } from '@prisma/client';
import { geminiService } from './geminiService';
import { pineconeService } from './pineconeService';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class WeeklyStrategyService {
  /**
   * Generate weekly strategy comparing planned vs actual (HIGH thinking level)
   */
  async generateWeeklyStrategy(userId: string, weekStart: Date): Promise<{
    insights: string;
    milestones: string[];
  }> {
    try {
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);

      // Get planned items from Pinecone (snap vectors)
      const plannedItems = await pineconeService.getPlannedItems(userId, weekStart, weekEnd);

      // Get actual reflections
      const reflections = await prisma.reflection.findMany({
        where: {
          userId,
          date: {
            gte: weekStart,
            lte: weekEnd,
          },
        },
        orderBy: {
          date: 'asc',
        },
      });

      const actualReflections = reflections.map(r => r.content);

      // Generate strategy with HIGH thinking level
      const strategy = await geminiService.generateWeeklyStrategy(
        plannedItems,
        actualReflections
      );

      return strategy;
    } catch (error) {
      logger.error('Weekly strategy generation error:', error);
      throw error;
    }
  }
}

export const weeklyStrategyService = new WeeklyStrategyService();

