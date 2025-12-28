import { GoogleGenerativeAI } from '@google/generative-ai';
import { logger } from '../utils/logger';
import { SnapResponse } from '@focura/shared';

export enum ThinkingLevel {
  MINIMAL = 'minimal',
  HIGH = 'high',
}

export class GeminiService {
  private client: GoogleGenerativeAI;
  private model: any;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured');
    }
    this.client = new GoogleGenerativeAI(apiKey);
    this.model = this.client.getGenerativeModel({ model: 'gemini-1.5-flash' });
  }

  /**
   * Process snap image with MINIMAL thinking level for low latency
   */
  async processSnapImage(
    imageBase64: string,
    mimeType: string = 'image/jpeg'
  ): Promise<SnapResponse> {
    const prompt = this.getSnapPrompt();
    
    try {
      const result = await this.model.generateContent({
        contents: [{
          role: 'user',
          parts: [
            { text: prompt },
            {
              inlineData: {
                mimeType,
                data: imageBase64,
              },
            },
          ],
        }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.7,
        },
        // MINIMAL thinking level for low latency
      });

      const response = result.response;
      const text = response.text();
      
      // Parse JSON response
      const parsed = JSON.parse(text) as SnapResponse;
      
      // Validate response structure
      this.validateSnapResponse(parsed);
      
      return parsed;
    } catch (error) {
      logger.error('Gemini snap processing error:', error);
      throw new Error(`Failed to process snap image: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Analyze goal feasibility with HIGH thinking level for deep reasoning
   */
  async analyzeGoalFeasibility(
    goal: { title: string; description: string; deadline: Date },
    userContext: { currentLoad: number; weeklyHours: number }
  ): Promise<{ score: number; analysis: string; pivot?: string }> {
    const prompt = this.getFeasibilityPrompt(goal, userContext);
    
    try {
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.3, // Lower temperature for more consistent analysis
        },
        // HIGH thinking level for deep reasoning
      });

      const response = result.response.text();
      const parsed = JSON.parse(response);
      
      return {
        score: parsed.feasibilityScore || 0,
        analysis: parsed.analysis || '',
        pivot: parsed.strategicPivot,
      };
    } catch (error) {
      logger.error('Gemini feasibility analysis error:', error);
      throw new Error(`Failed to analyze goal feasibility: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Generate weekly strategy with HIGH thinking level
   */
  async generateWeeklyStrategy(
    plannedItems: string[],
    actualReflections: string[]
  ): Promise<{ insights: string; milestones: string[] }> {
    const prompt = this.getWeeklyStrategyPrompt(plannedItems, actualReflections);
    
    try {
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.5,
        },
        // HIGH thinking level for deep reasoning
      });

      const response = result.response.text();
      const parsed = JSON.parse(response);
      
      return {
        insights: parsed.insights || '',
        milestones: parsed.milestones || [],
      };
    } catch (error) {
      logger.error('Gemini weekly strategy error:', error);
      throw new Error(`Failed to generate weekly strategy: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Analyze morning sync and generate energy baseline
   */
  async analyzeMorningSync(input: {
    sleepTime: Date;
    wakeTime: Date;
    initialFocus: number;
    averageSleepHours?: number;
  }): Promise<{
    sleepDebt: number;
    sleepInertia: number;
    energyBaseline: number;
    recommendedSchedule: {
      firstPeakStart: Date;
      deepWorkDuration: number;
      sprintMode: boolean;
    };
  }> {
    const prompt = this.getMorningSyncPrompt(input);
    
    try {
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.4,
        },
      });

      const response = result.response.text();
      const parsed = JSON.parse(response);
      
      return {
        sleepDebt: parsed.sleepDebt || 0,
        sleepInertia: parsed.sleepInertia || 0,
        energyBaseline: parsed.energyBaseline || 3,
        recommendedSchedule: {
          firstPeakStart: new Date(parsed.recommendedSchedule.firstPeakStart),
          deepWorkDuration: parsed.recommendedSchedule.deepWorkDuration || 180,
          sprintMode: parsed.recommendedSchedule.sprintMode || false,
        },
      };
    } catch (error) {
      logger.error('Gemini morning sync analysis error:', error);
      throw new Error(`Failed to analyze morning sync: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Restructure schedule with PFC Shield logic
   */
  async restructureSchedule(context: {
    remainingTasks: Array<{ id: string; title: string; energyRequirement: string; priority: number }>;
    interruption: { nature: string; duration: number };
    currentTime: Date;
    remainingHours: number;
    priorityGoal?: { id: string; title: string };
  }): Promise<{
    restructuredTasks: Array<{ taskId: string; newTime: Date; energyWindow: string }>;
    droppedTasks: string[];
    microWin?: { taskId: string; duration: number; description: string };
  }> {
    const prompt = this.getPFCShieldPrompt(context);
    
    try {
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.5,
        },
      });

      const response = result.response.text();
      const parsed = JSON.parse(response);
      
      return {
        restructuredTasks: parsed.restructuredTasks || [],
        droppedTasks: parsed.droppedTasks || [],
        microWin: parsed.microWin,
      };
    } catch (error) {
      logger.error('Gemini PFC Shield error:', error);
      throw new Error(`Failed to restructure schedule: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  private getSnapPrompt(): string {
    return `You are an expert at extracting structured information from handwritten notes and typed text.

Analyze the image and extract tasks, goals, and reflections following these rules:

1. TASK DECOMPOSITION: Every primary task must be broken into 3-5 "Micro-Subtasks" (max 15 mins each).
2. IMPLEMENTATION INTENTIONS: For every task, generate an "If-Then" trigger following Peter Gollwitzer formula: "[Trigger Situation] + [Planned Action]"
   Example: "When I finish my lunch (Trigger), then I will spend 15 minutes on the 'Email Client' subtask (Action)."
3. ENERGY MAPPING: Categorize tasks into "Peak" (High focus), "Administrative" (Low energy), or "Reflective."
4. STRUCTURED OCR: Recognize symbols:
   - Stars (*) = Priority
   - Circles (○) = Habit
   - Arrows (→) = Migration

Return ONLY a valid JSON object matching this structure:
{
  "summary": "Brief analysis of the user's focus today",
  "extracted_items": [
    {
      "type": "task | goal | reflection",
      "original_text": "string",
      "priority": 1-5,
      "energy_requirement": "High | Medium | Low",
      "implementation_intention": "If [trigger], then [action]",
      "subtasks": [
        {"title": "string", "duration_estimate": "mins"}
      ],
      "feasibility_warning": "string | null"
    }
  ],
  "daily_structure": {
    "morning_peak": ["task_ids"],
    "afternoon_admin": ["task_ids"],
    "evening_reflection": ["task_ids"]
  }
}`;
  }

  private getFeasibilityPrompt(
    goal: { title: string; description: string; deadline: Date },
    userContext: { currentLoad: number; weeklyHours: number }
  ): string {
    return `Analyze the feasibility of this goal:

Goal: ${goal.title}
Description: ${goal.description}
Deadline: ${goal.deadline.toISOString()}

User Context:
- Current task load: ${userContext.currentLoad} active tasks
- Weekly working hours: ${userContext.weeklyHours} hours/week

Provide a feasibility analysis with:
1. Feasibility score (0-100)
2. Detailed analysis of challenges and opportunities
3. Strategic pivot suggestion if score < 60

Return JSON:
{
  "feasibilityScore": 0-100,
  "analysis": "Detailed analysis text",
  "strategicPivot": "Suggested pivot or null"
}`;
  }

  private getWeeklyStrategyPrompt(plannedItems: string[], actualReflections: string[]): string {
    return `Compare what was planned vs what actually happened:

PLANNED (from snap photos):
${plannedItems.map((item, i) => `${i + 1}. ${item}`).join('\n')}

ACTUAL REFLECTIONS:
${actualReflections.map((reflection, i) => `${i + 1}. ${reflection}`).join('\n')}

Generate insights and suggest next sprint milestones.

Return JSON:
{
  "insights": "Key insights comparing planned vs actual",
  "milestones": ["milestone1", "milestone2", ...]
}`;
  }

  private getMorningSyncPrompt(input: {
    sleepTime: Date;
    wakeTime: Date;
    initialFocus: number;
    averageSleepHours?: number;
  }): string {
    const sleepDuration = (input.wakeTime.getTime() - input.sleepTime.getTime()) / (1000 * 60 * 60);
    const requiredSleep = input.averageSleepHours || 8;
    
    return `Analyze morning sync data:

Sleep Time: ${input.sleepTime.toISOString()}
Wake Time: ${input.wakeTime.toISOString()}
Sleep Duration: ${sleepDuration.toFixed(1)} hours
Required Sleep: ${requiredSleep} hours
Initial Focus (1-5): ${input.initialFocus}

Calculate:
1. Sleep debt (hours of deficit)
2. Sleep inertia (minutes until first peak focus)
3. Energy baseline (1-5 scale)
4. Recommended schedule adjustments

If sleep-deprived (< 6 hours), convert 3-hour Deep Work → 45-min Sprint.

Return JSON:
{
  "sleepDebt": 0.0,
  "sleepInertia": 0,
  "energyBaseline": 3,
  "recommendedSchedule": {
    "firstPeakStart": "ISO datetime",
    "deepWorkDuration": 180,
    "sprintMode": false
  }
}`;
  }

  private getPFCShieldPrompt(context: {
    remainingTasks: Array<{ id: string; title: string; energyRequirement: string; priority: number }>;
    interruption: { nature: string; duration: number };
    currentTime: Date;
    remainingHours: number;
    priorityGoal?: { id: string; title: string };
  }): string {
    return `The user is experiencing an unplanned interruption.

Current Time: ${context.currentTime.toISOString()}
Remaining Hours: ${context.remainingHours}
Interruption: ${context.interruption.nature} (${context.interruption.duration} minutes)

Remaining Tasks:
${context.remainingTasks.map(t => `- ${t.title} (${t.energyRequirement}, Priority ${t.priority})`).join('\n')}

Priority Goal: ${context.priorityGoal?.title || 'None'}

Constraint: Maintain the '1% Better' rule. Protect Goal Progress.

Requirement: Re-order the day. Shift 'High-Energy' tasks to the next predicted peak or tomorrow. 
Identify a 10-minute 'Micro-Win' for the Priority Goal to ensure the streak is not broken.

Return JSON:
{
  "restructuredTasks": [
    {"taskId": "id", "newTime": "ISO datetime", "energyWindow": "morning_peak|afternoon_admin|evening_reflection"}
  ],
  "droppedTasks": ["taskId1", "taskId2"],
  "microWin": {
    "taskId": "id",
    "duration": 10,
    "description": "Micro-win description"
  }
}`;
  }

  private validateSnapResponse(response: any): void {
    if (!response.summary || typeof response.summary !== 'string') {
      throw new Error('Invalid response: missing or invalid summary');
    }
    if (!Array.isArray(response.extracted_items)) {
      throw new Error('Invalid response: extracted_items must be an array');
    }
    if (!response.daily_structure) {
      throw new Error('Invalid response: missing daily_structure');
    }
  }
}

export const geminiService = new GeminiService();

