import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class MomentumService {
  /**
   * Calculate 1% Better Momentum Score
   */
  async calculateMomentumScore(userId: string, date: Date): Promise<{
    consistency: boolean;
    energyAlignment: number;
    recovery: number;
    overallScore: number;
  }> {
    try {
      // Consistency: Did user complete ≥1 subtask?
      const completedSubtasks = await prisma.subtask.count({
        where: {
          task: {
            userId,
          },
          status: 'completed',
          completedAt: {
            gte: new Date(date.setHours(0, 0, 0, 0)),
            lt: new Date(date.setHours(23, 59, 59, 999)),
          },
        },
      });
      const consistency = completedSubtasks >= 1;

      // Energy Alignment: Task completion vs Energy Peak sync
      const energyAlignment = await this.calculateEnergyAlignment(userId, date);

      // Recovery: Sleep/Wake consistency
      const recovery = await this.calculateRecovery(userId, date);

      // Overall Score (0-100)
      const overallScore = this.calculateOverallScore(consistency, energyAlignment, recovery);

      return {
        consistency,
        energyAlignment,
        recovery,
        overallScore,
      };
  } catch (error) {
      logger.error('Momentum score calculation error:', error);
      throw error;
    }
  }

  /**
   * Calculate energy alignment score
   */
  private async calculateEnergyAlignment(userId: string, date: Date): Promise<number> {
    // Get tasks completed during peak energy windows
    const peakTasks = await prisma.task.count({
      where: {
        userId,
        status: 'completed',
        scheduledEnergyWindow: 'morning_peak',
        completedAt: {
          gte: new Date(date.setHours(0, 0, 0, 0)),
          lt: new Date(date.setHours(23, 59, 59, 999)),
        },
      },
    });

    // Get total completed tasks
    const totalCompleted = await prisma.task.count({
      where: {
        userId,
        status: 'completed',
        completedAt: {
          gte: new Date(date.setHours(0, 0, 0, 0)),
          lt: new Date(date.setHours(23, 59, 59, 999)),
        },
      },
    });

    if (totalCompleted === 0) {
      return 0;
    }

    // Score: ratio of peak tasks to total tasks
    return peakTasks / totalCompleted;
  }

  /**
   * Calculate recovery score (sleep/wake consistency)
   */
  private async calculateRecovery(userId: string, date: Date): Promise<number> {
    // Get today's bio sync
    const today = new Date(date);
    today.setHours(0, 0, 0, 0);

    const bioSync = await prisma.dailyBioSync.findUnique({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
    });

    if (!bioSync) {
      return 0.5; // Default if no data
    }

    // Get average sleep hours from energy patterns
    const energyPattern = await prisma.energyPattern.findFirst({
      where: { userId },
    });

    const targetSleepHours = energyPattern?.averageSleepHours || 8;
    const actualSleepHours = (bioSync.wakeTime.getTime() - bioSync.sleepTime.getTime()) / (1000 * 60 * 60);

    // Score based on how close actual sleep is to target (0-1)
    const sleepDiff = Math.abs(actualSleepHours - targetSleepHours);
    const recovery = Math.max(0, 1 - (sleepDiff / targetSleepHours));

    return recovery;
  }

  /**
   * Calculate overall momentum score
   */
  private calculateOverallScore(
    consistency: boolean,
    energyAlignment: number,
    recovery: number
  ): number {
    // Weighted average
    const consistencyScore = consistency ? 1 : 0;
    const weights = {
      consistency: 0.4,
      energyAlignment: 0.4,
      recovery: 0.2,
    };

    const overallScore = (
      consistencyScore * weights.consistency +
      energyAlignment * weights.energyAlignment +
      recovery * weights.recovery
    ) * 100;

    return Math.round(overallScore);
  }

  /**
   * Store momentum score
   */
  async storeMomentumScore(userId: string, date: Date): Promise<void> {
    try {
      const score = await this.calculateMomentumScore(userId, date);

      const today = new Date(date);
      today.setHours(0, 0, 0, 0);

      await prisma.momentumScore.upsert({
        where: {
          userId_date: {
            userId,
            date: today,
          },
        },
        create: {
          userId,
          date: today,
          consistency: score.consistency,
          energyAlignment: score.energyAlignment,
          recovery: score.recovery,
          overallScore: score.overallScore,
        },
        update: {
          consistency: score.consistency,
          energyAlignment: score.energyAlignment,
          recovery: score.recovery,
          overallScore: score.overallScore,
        },
      });
    } catch (error) {
      logger.error('Store momentum score error:', error);
      throw error;
    }
  }

  /**
   * Get neuro-feedback message
   */
  getNeuroFeedback(score: {
    consistency: boolean;
    energyAlignment: number;
    recovery: number;
    overallScore: number;
  }): string {
    if (score.consistency) {
      return `Streak maintained. You are 1% closer to your goals.`;
    }
    if (score.energyAlignment > 0.7) {
      return `Efficiency +20%. You mastered your rhythm today.`;
    }
    if (score.recovery > 0.8) {
      return `Focus score rising. Tomorrow is a 'Power Day'.`;
    }
    return `Keep going. Every small step counts.`;
  }
}

export const momentumService = new MomentumService();

