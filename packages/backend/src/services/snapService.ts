import { PrismaClient } from '@prisma/client';
import { geminiService } from './geminiService';
import { pineconeService } from './pineconeService';
import { logger } from '../utils/logger';
import { SnapResponse } from '@focura/shared';

const prisma = new PrismaClient();

export class SnapService {
  /**
   * Process uploaded image and extract tasks/goals/reflections
   */
  async processSnap(
    userId: string,
    imageBuffer: Buffer,
    mimeType: string
  ): Promise<{ snapId: string; result: SnapResponse }> {
    try {
      // Convert buffer to base64
      const imageBase64 = imageBuffer.toString('base64');
      
      // Process with Gemini (MINIMAL thinking level)
      const extractionResult = await geminiService.processSnapImage(imageBase64, mimeType);
      
      // Store snap record
      const snap = await prisma.snap.create({
        data: {
          userId,
          imageUrl: `snaps/${userId}/${Date.now()}.${mimeType.split('/')[1]}`,
          extractedData: extractionResult as any,
          vectorSyncStatus: 'pending',
        },
      });

      // Extract text for vectorization
      const extractedText = this.extractTextFromSnapResponse(extractionResult);
      
      // Instant vectorization to Pinecone
      let vectorId: string | null = null;
      try {
        vectorId = await pineconeService.vectorizeSnapText(
          snap.id,
          extractedText,
          {
            userId,
            date: new Date(),
            type: 'snap',
          }
        );
        
        // Update snap with vector ID
        await prisma.snap.update({
          where: { id: snap.id },
          data: {
            vectorId,
            vectorSyncStatus: 'completed',
          },
        });
      } catch (vectorError) {
        logger.error('Vector sync failed:', vectorError);
        await prisma.snap.update({
          where: { id: snap.id },
          data: {
            vectorSyncStatus: 'failed',
          },
        });
        // Continue even if vectorization fails
      }

      // Create tasks, goals, and reflections from extracted data
      await this.createItemsFromExtraction(userId, extractionResult, snap.id);

      return {
        snapId: snap.id,
        result: extractionResult,
      };
    } catch (error) {
      logger.error('Snap processing error:', error);
      throw error;
    }
  }

  private extractTextFromSnapResponse(response: SnapResponse): string {
    const texts: string[] = [];
    
    texts.push(response.summary);
    
    for (const item of response.extracted_items) {
      texts.push(item.original_text);
      texts.push(item.implementation_intention);
      for (const subtask of item.subtasks) {
        texts.push(subtask.title);
      }
    }
    
    return texts.join(' ');
  }

  private async createItemsFromExtraction(
    userId: string,
    extraction: SnapResponse,
    snapId: string
  ): Promise<void> {
    for (const item of extraction.extracted_items) {
      if (item.type === 'task') {
        // Create task
        const task = await prisma.task.create({
          data: {
            userId,
            title: item.original_text,
            priority: item.priority,
            energyRequirement: item.energy_requirement,
            implementationIntention: item.implementation_intention,
            scheduledEnergyWindow: this.mapEnergyToWindow(item.energy_requirement),
          },
        });

        // Create subtasks
        for (const subtask of item.subtasks) {
          await prisma.subtask.create({
            data: {
              taskId: task.id,
              title: subtask.title,
              durationEstimate: subtask.duration_estimate,
            },
          });
        }
      } else if (item.type === 'goal') {
        // Create goal
        await prisma.goal.create({
          data: {
            userId,
            title: item.original_text,
            description: item.feasibility_warning || undefined,
            deadline: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // Default 1 year
          },
        });
      } else if (item.type === 'reflection') {
        // Create reflection
        const reflection = await prisma.reflection.create({
          data: {
            userId,
            content: item.original_text,
            date: new Date(),
          },
        });

        // Vectorize reflection
        try {
          const vectorId = await pineconeService.vectorizeReflection(
            reflection.id,
            item.original_text,
            {
              userId,
              date: new Date(),
              type: 'reflection',
            }
          );
          
          await prisma.reflection.update({
            where: { id: reflection.id },
            data: { vectorId },
          });
        } catch (error) {
          logger.error('Failed to vectorize reflection:', error);
        }
      }
    }
  }

  private mapEnergyToWindow(energy: string): string {
    switch (energy.toLowerCase()) {
      case 'high':
        return 'morning_peak';
      case 'medium':
        return 'afternoon_admin';
      case 'low':
        return 'evening_reflection';
      default:
        return 'afternoon_admin';
    }
  }

  /**
   * Get snap processing status
   */
  async getSnapStatus(snapId: string, userId: string): Promise<{
    id: string;
    status: string;
    vectorSyncStatus: string;
    createdAt: Date;
  } | null> {
    const snap = await prisma.snap.findFirst({
      where: {
        id: snapId,
        userId,
      },
      select: {
        id: true,
        vectorSyncStatus: true,
        createdAt: true,
      },
    });

    if (!snap) {
      return null;
    }

    return {
      id: snap.id,
      status: 'completed',
      vectorSyncStatus: snap.vectorSyncStatus,
      createdAt: snap.createdAt,
    };
  }
}

export const snapService = new SnapService();

