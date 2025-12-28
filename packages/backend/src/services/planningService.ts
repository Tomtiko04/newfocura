import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class PlanningService {
  /**
   * Generate daily schedule with dynamic weighting
   */
  async generateDailySchedule(userId: string, date: Date): Promise<{
    tasks: Array<{ taskId: string; scheduledTime: Date; energyWindow: string }>;
    energyWindows: Array<{ start: string; end: string; state: string }>;
  }> {
    try {
      // Get user's bio sync for the day
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

      // Get energy pattern
      const energyPattern = await prisma.energyPattern.findFirst({
        where: { userId },
      });

      // Get pending tasks
      const tasks = await prisma.task.findMany({
        where: {
          userId,
          status: { in: ['pending', 'in_progress'] },
        },
        include: {
          subtasks: true,
        },
        orderBy: [
          { priority: 'desc' },
          { createdAt: 'asc' },
        ],
      });

      // Determine energy windows based on bio sync
      const energyWindows = this.calculateEnergyWindows(bioSync, energyPattern, date);

      // Schedule tasks using dynamic weighting
      const scheduledTasks = this.scheduleTasks(tasks, energyWindows, bioSync);

      // Update tasks with scheduled times
      for (const scheduledTask of scheduledTasks) {
        await prisma.task.update({
          where: { id: scheduledTask.taskId },
          data: {
            scheduledTime: scheduledTask.scheduledTime,
            scheduledEnergyWindow: scheduledTask.energyWindow,
          },
        });
      }

      // Store schedule
      await prisma.schedule.upsert({
        where: {
          userId_date: {
            userId,
            date: today,
          },
        },
        create: {
          userId,
          date: today,
          tasks: scheduledTasks as any,
          energyWindows: energyWindows as any,
        },
        update: {
          tasks: scheduledTasks as any,
          energyWindows: energyWindows as any,
        },
      });

      return {
        tasks: scheduledTasks,
        energyWindows,
      };
    } catch (error) {
      logger.error('Generate daily schedule error:', error);
      throw error;
    }
  }

  /**
   * Calculate energy windows based on bio sync and patterns
   */
  private calculateEnergyWindows(
    bioSync: any,
    energyPattern: any,
    date: Date
  ): Array<{ start: string; end: string; state: string }> {
    const windows: Array<{ start: string; end: string; state: string }> = [];

    if (bioSync) {
      // Use bio sync data
      const wakeTime = bioSync.wakeTime;
      const sleepInertia = bioSync.sleepInertia || 0;

      // Morning Peak: After sleep inertia
      const morningPeakStart = new Date(wakeTime);
      morningPeakStart.setMinutes(morningPeakStart.getMinutes() + sleepInertia);
      
      const morningPeakEnd = new Date(morningPeakStart);
      morningPeakEnd.setHours(morningPeakEnd.getHours() + 3);

      windows.push({
        start: this.formatTime(morningPeakStart),
        end: this.formatTime(morningPeakEnd),
        state: 'morning_peak',
      });

      // Afternoon Admin: Low energy dip
      windows.push({
        start: '14:00',
        end: '16:00',
        state: 'afternoon_admin',
      });

      // Evening Reflection
      windows.push({
        start: '19:00',
        end: '21:00',
        state: 'evening_reflection',
      });
    } else if (energyPattern) {
      // Use energy pattern defaults
      windows.push({
        start: energyPattern.peakEnergyStart || '08:00',
        end: energyPattern.peakEnergyEnd || '11:00',
        state: 'morning_peak',
      });

      windows.push({
        start: energyPattern.lowEnergyStart || '14:00',
        end: energyPattern.lowEnergyEnd || '16:00',
        state: 'afternoon_admin',
      });

      windows.push({
        start: '19:00',
        end: '21:00',
        state: 'evening_reflection',
      });
    } else {
      // Default windows
      windows.push({
        start: '08:00',
        end: '11:00',
        state: 'morning_peak',
      });

      windows.push({
        start: '14:00',
        end: '16:00',
        state: 'afternoon_admin',
      });

      windows.push({
        start: '19:00',
        end: '21:00',
        state: 'evening_reflection',
      });
    }

    return windows;
  }

  /**
   * Schedule tasks using dynamic weighting
   */
  private scheduleTasks(
    tasks: any[],
    energyWindows: Array<{ start: string; end: string; state: string }>,
    bioSync: any
  ): Array<{ taskId: string; scheduledTime: Date; energyWindow: string }> {
    const scheduled: Array<{ taskId: string; scheduledTime: Date; energyWindow: string }> = [];

    // Group tasks by energy requirement
    const highEnergyTasks = tasks.filter(t => t.energyRequirement === 'High');
    const mediumEnergyTasks = tasks.filter(t => t.energyRequirement === 'Medium');
    const lowEnergyTasks = tasks.filter(t => t.energyRequirement === 'Low');

    // Find peak window
    const peakWindow = energyWindows.find(w => w.state === 'morning_peak');
    const adminWindow = energyWindows.find(w => w.state === 'afternoon_admin');
    const reflectionWindow = energyWindows.find(w => w.state === 'evening_reflection');

    let currentTime = peakWindow ? this.parseTime(peakWindow.start) : new Date();

    // Schedule high energy tasks in peak window
    for (const task of highEnergyTasks) {
      if (peakWindow && currentTime < this.parseTime(peakWindow.end)) {
        scheduled.push({
          taskId: task.id,
          scheduledTime: new Date(currentTime),
          energyWindow: 'morning_peak',
        });
        // Estimate 1 hour per task
        currentTime.setHours(currentTime.getHours() + 1);
      }
    }

    // Schedule medium energy tasks in admin window
    currentTime = adminWindow ? this.parseTime(adminWindow.start) : new Date();
    for (const task of mediumEnergyTasks) {
      if (adminWindow && currentTime < this.parseTime(adminWindow.end)) {
        scheduled.push({
          taskId: task.id,
          scheduledTime: new Date(currentTime),
          energyWindow: 'afternoon_admin',
        });
        currentTime.setHours(currentTime.getHours() + 1);
      }
    }

    // Schedule low energy tasks in reflection window
    currentTime = reflectionWindow ? this.parseTime(reflectionWindow.start) : new Date();
    for (const task of lowEnergyTasks) {
      if (reflectionWindow && currentTime < this.parseTime(reflectionWindow.end)) {
        scheduled.push({
          taskId: task.id,
          scheduledTime: new Date(currentTime),
          energyWindow: 'evening_reflection',
        });
        currentTime.setHours(currentTime.getHours() + 1);
      }
    }

    return scheduled;
  }

  private formatTime(date: Date): string {
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  private parseTime(timeStr: string): Date {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes, 0, 0);
    return date;
  }
}

export const planningService = new PlanningService();

