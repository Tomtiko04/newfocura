import { Pinecone } from '@pinecone-database/pinecone';
import { logger } from '../utils/logger';

export class PineconeService {
  private client: Pinecone;
  private indexName: string;

  constructor() {
    const apiKey = process.env.PINECONE_API_KEY;
    if (!apiKey) {
      throw new Error('PINECONE_API_KEY is not configured');
    }
    
    this.client = new Pinecone({ apiKey });
    this.indexName = process.env.PINECONE_INDEX_NAME || 'focura-reflections';
  }

  /**
   * Generate embedding for text (using Gemini embedding model)
   * Note: In production, you might want to use a dedicated embedding model
   */
  private async generateEmbedding(text: string): Promise<number[]> {
    // For now, we'll use a simple text-based hash as placeholder
    // In production, integrate with an embedding API (OpenAI, Cohere, or Gemini embedding)
    // This is a simplified version - replace with actual embedding API call
    const { GoogleGenerativeAI } = await import('@google/generative-ai');
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
    
    // Using Gemini's embedding model if available, otherwise fallback
    // Note: Gemini 1.5 Flash doesn't have a dedicated embedding endpoint
    // You may need to use OpenAI's text-embedding-ada-002 or similar
    // For MVP, we'll create a simple vector representation
    
    // Placeholder: In production, replace with actual embedding API
    logger.warn('Using placeholder embedding - replace with actual embedding API in production');
    
    // Simple hash-based vector (not ideal, but works for MVP)
    const vector: number[] = [];
    for (let i = 0; i < 1536; i++) {
      const hash = this.simpleHash(text + i.toString());
      vector.push((hash % 2000 - 1000) / 1000); // Normalize to -1 to 1
    }
    
    return vector;
  }

  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
  }

  /**
   * Instant vectorization on snap processing
   */
  async vectorizeSnapText(
    snapId: string,
    text: string,
    metadata: { userId: string; date: Date; type: 'snap' }
  ): Promise<string> {
    try {
      const embedding = await this.generateEmbedding(text);
      
      const index = this.client.index(this.indexName);
      
      await index.upsert([{
        id: `snap-${snapId}`,
        values: embedding,
        metadata: {
          userId: metadata.userId,
          date: metadata.date.toISOString(),
          type: metadata.type,
          text: text.substring(0, 1000), // Store first 1000 chars for reference
        },
      }]);

      logger.info(`Vectorized snap ${snapId} in Pinecone`);
      return `snap-${snapId}`;
    } catch (error) {
      logger.error('Pinecone vectorization error:', error);
      throw new Error(`Failed to vectorize snap text: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Vectorize reflection text
   */
  async vectorizeReflection(
    reflectionId: string,
    text: string,
    metadata: { userId: string; date: Date; type: 'reflection' }
  ): Promise<string> {
    try {
      const embedding = await this.generateEmbedding(text);
      
      const index = this.client.index(this.indexName);
      
      await index.upsert([{
        id: `reflection-${reflectionId}`,
        values: embedding,
        metadata: {
          userId: metadata.userId,
          date: metadata.date.toISOString(),
          type: metadata.type,
          text: text.substring(0, 1000),
        },
      }]);

      logger.info(`Vectorized reflection ${reflectionId} in Pinecone`);
      return `reflection-${reflectionId}`;
    } catch (error) {
      logger.error('Pinecone reflection vectorization error:', error);
      throw new Error(`Failed to vectorize reflection: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Search for similar vectors (for weekly reflection comparison)
   */
  async findSimilarVectors(
    queryText: string,
    userId: string,
    limit: number = 10
  ): Promise<Array<{ id: string; score: number; metadata: any }>> {
    try {
      const queryEmbedding = await this.generateEmbedding(queryText);
      
      const index = this.client.index(this.indexName);
      
      const results = await index.query({
        vector: queryEmbedding,
        topK: limit,
        includeMetadata: true,
        filter: {
          userId: { $eq: userId },
        },
      });

      return results.matches.map(match => ({
        id: match.id,
        score: match.score || 0,
        metadata: match.metadata || {},
      }));
    } catch (error) {
      logger.error('Pinecone similarity search error:', error);
      throw new Error(`Failed to search similar vectors: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get planned items from snap vectors for weekly comparison
   */
  async getPlannedItems(userId: string, startDate: Date, endDate: Date): Promise<string[]> {
    try {
      const index = this.client.index(this.indexName);
      
      // Query for snap vectors in date range
      // Note: Pinecone doesn't support date range queries directly
      // We'll need to fetch and filter, or use metadata filtering if supported
      const results = await index.query({
        vector: new Array(1536).fill(0), // Dummy vector for metadata-only query
        topK: 100,
        includeMetadata: true,
        filter: {
          userId: { $eq: userId },
          type: { $eq: 'snap' },
        },
      });

      const plannedItems: string[] = [];
      for (const match of results.matches) {
        if (match.metadata?.date) {
          const date = new Date(match.metadata.date);
          if (date >= startDate && date <= endDate) {
            plannedItems.push(match.metadata.text || '');
          }
        }
      }

      return plannedItems;
    } catch (error) {
      logger.error('Pinecone get planned items error:', error);
      throw new Error(`Failed to get planned items: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

export const pineconeService = new PineconeService();

