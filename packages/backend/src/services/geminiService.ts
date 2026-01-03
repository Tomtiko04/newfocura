import { GoogleGenerativeAI } from '@google/generative-ai';
import { logger } from '../utils/logger';
// Local SnapResponse shape to avoid shared dependency
type SnapSubtask = {
  title: string;
  duration_estimate: number;
};

type SnapItem = {
  type: 'task' | 'goal' | 'reflection';
  original_text: string;
  priority?: number;
  energy_requirement?: string;
  implementation_intention?: string;
  subtasks: SnapSubtask[];
  feasibility_warning?: string;
};

type SnapResponse = {
  summary: string;
  extracted_items: SnapItem[];
  daily_structure: {
    morning_peak: string[];
    afternoon_admin: string[];
    evening_reflection: string[];
  };
};

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
    // @ts-ignore apiVersion supported in v1beta but may be missing in types
    this.client = new GoogleGenerativeAI(apiKey, { apiVersion: 'v1beta' });
    this.model = this.client.getGenerativeModel({
      model: 'gemini-3-flash-preview',
    }, { apiVersion: 'v1beta' }); // Force apiVersion in requestOptions as well
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
          temperature: 0.7,
        },
        // MINIMAL thinking level for low latency
      });

      const response = result.response;
      const text = response.text();
      
      // Parse JSON response
      const parsed = this.extractJSON(text) as SnapResponse;
      
      // Validate response structure
      this.validateSnapResponse(parsed);
      
      return parsed;
    } catch (error) {
      logger.error('Gemini snap processing error:', error);
      throw new Error(`Failed to process snap image: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Analyze goal portfolio holistically with HIGH thinking level for deep reasoning
   */
  async analyzeGoalPortfolio(
    goals: Array<{ title: string; why?: string; deadline: Date; skillLevel?: string }>,
    userContext: { 
      currentLoad: number; 
      weekdayFocusHours: number;
      weekendFocusHours: number;
      lifeSeason: string;
      reliabilityScore: number;
      antiGoals: string[];
    }
  ): Promise<{
    summary: string;
    results: Array<{ 
      title: string; 
      score: number; 
      analysis: string; 
      pivot?: string; 
      estimatedHours?: number;
      impactScore: number;
      priorityBucket: string;
      suggestedQuarter: number;
    }>
  }> {
    const prompt = this.getPortfolioPrompt(goals, userContext);
    
    try {
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 1.0, 
          responseMimeType: 'application/json',
          // @ts-ignore Gemini 3 thinking config
          thinkingConfig: {
            includeThoughts: false,
            thinkingLevel: 'high',
          },
        },
      });

      const responseText = result.response.text();
      const parsed = this.extractJSON(responseText);
      
      if (!parsed.results || !Array.isArray(parsed.results)) {
        throw new Error('Invalid portfolio analysis structure');
      }

      const results = parsed.results.map((r: any) => {
        let analysisText = '';
        if (typeof r.analysis === 'object') {
          analysisText = r.analysis.summary || '';
          if (r.analysis.challenges?.length) {
            analysisText += '\n\nChallenges:\n- ' + r.analysis.challenges.join('\n- ');
          }
          if (r.analysis.opportunities?.length) {
            analysisText += '\n\nOpportunities:\n- ' + r.analysis.opportunities.join('\n- ');
          }
        } else {
          analysisText = r.analysis || '';
        }

        return {
          title: r.title,
          score: r.feasibilityScore ?? 0,
          analysis: analysisText,
          pivot: r.strategicPivot,
          estimatedHours: r.estimatedHoursRequired,
          impactScore: r.impactScore ?? 5,
          priorityBucket: r.priorityBucket ?? 'C',
          suggestedQuarter: r.suggestedQuarter ?? 1,
        };
      });

      return {
        summary: parsed.portfolioSummary || '',
        results
      };
    } catch (error) {
      logger.error('Gemini portfolio reasoning error:', error);
      throw new Error(`Failed to analyze goal portfolio: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  private getPortfolioPrompt(
    goals: Array<{ title: string; why?: string; deadline: Date; skillLevel?: string }>,
    userContext: { 
      currentLoad: number; 
      weekdayFocusHours: number;
      weekendFocusHours: number;
      lifeSeason: string;
      reliabilityScore: number;
      antiGoals: string[];
    }
  ): string {
    const goalsXml = goals.map((g, i) => `
<goal id="${i + 1}">
  <title>${g.title}</title>
  <reasoning>${g.why ?? 'Not provided'}</reasoning>
  <deadline>${g.deadline.toISOString()}</deadline>
  <skillLevel>${g.skillLevel ?? 'beginner'}</skillLevel>
</goal>`).join('');

    const weeklyCapacity = (userContext.weekdayFocusHours * 5) + userContext.weekendFocusHours;

    return `System: You are an expert productivity coach and project portfolio analyst. Your task is to perform a "Holistic Portfolio Pass" on a user's yearly goals.

User "Current Reality" Context:
- Available Deep Work: ${userContext.weekdayFocusHours} hrs/weekday, ${userContext.weekendFocusHours} hrs/weekend.
- Total Weekly Capacity: ${weeklyCapacity} hours/week.
- Life Season: ${userContext.lifeSeason} (push = aggressive, sustainability = balanced).
- Reliability Score: ${userContext.reliabilityScore}/5 (1 = high volatility/disruptions, 5 = very stable).
- Anti-Goals (Constraints): ${userContext.antiGoals.join(', ')}.

Goal Portfolio:
${goalsXml}

Task:
1. IMPACT WEIGHTING: Assign an "Impact Score" (1-10) to each goal based on the user's "Why" reasoning.
2. RESOURCE ALLOCATION: Estimate total hours required. If skillLevel is "beginner", add a 30% "Newbie Tax" to the estimate.
3. PORTFOLIO TRIAGE: Categorize goals into buckets:
   - Bucket A (The Big 3): Max 3 goals. High impact, high priority. 60% of capacity.
   - Bucket B (Supporters): Up to 5 goals. 30% of capacity.
   - Bucket C (Backlog): Lower priority or queued.
4. QUARTERLY SEQUENCING: Suggest which Quarter (1-4) to start each goal to prevent burnout and respect prerequisites.
5. BASELINE SETTING: For Bucket A goals, suggest a "Day 1" benchmark question (e.g. "What is your current bench press?" or "1-10 comfort with TS?").
6. REALITY CHECK: If total hours exceed capacity (adjusted for reliabilityScore), lower feasibility scores and suggest pivots.

Output Requirements:
Return ONLY a valid JSON object with this structure:
{
  "portfolioSummary": "Overall assessment of the entire goal set",
  "results": [
    {
      "title": "exact title from input",
      "feasibilityScore": number (0-100),
      "estimatedHoursRequired": number,
      "impactScore": number (1-10),
      "priorityBucket": "A | B | C",
      "suggestedQuarter": 1 | 2 | 3 | 4,
      "aiBaselinePrompt": "A specific question to ask the user about their starting point",
      "identityTitle": "An identity-based reframe of the goal (e.g. 'I am a Writer' for a writing goal)",
      "analysis": {
         "summary": "How this fits into the user's reality",
         "challenges": ["string"],
         "opportunities": ["string"]
      },
      "strategicPivot": "string or null"
    }
  ]
}

IMPORTANT: Total capacity reasoning MUST inform the buckets and suggested quarters. Do not put more than 3 high-effort goals in Bucket A.`;
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
          temperature: 0.5,
        },
        // HIGH thinking level for deep reasoning
      });

      const response = result.response.text();
      const parsed = this.extractJSON(response);
      
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
      const parsed = this.extractJSON(response);
      
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
      const parsed = this.extractJSON(response);
      
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

  private extractJSON(text: string): any {
    try {
      // Try direct parse first
      return JSON.parse(text);
    } catch (e) {
      // Look for the largest block starting with '{' and ending with '}'
      // We start from the beginning for the first brace and end for the last
      const firstBrace = text.indexOf('{');
      const lastBrace = text.lastIndexOf('}');

      if (firstBrace === -1 || lastBrace === -1 || lastBrace <= firstBrace) {
        logger.error('No JSON block found in text', { text });
        throw new Error('No valid JSON structure found');
      }

      // We try to find the longest substring that is a valid JSON
      // Sometimes models output multiple { } blocks, we want the one that matches our expected structure
      // For now, we take the outer-most braces
      const jsonCandidate = text.substring(firstBrace, lastBrace + 1);
      try {
        return JSON.parse(jsonCandidate);
      } catch (innerError) {
        // If outer-most fails, try to find a valid block by narrowing down
        // (common if model adds markdown around JSON)
        const lines = text.split('\n');
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim();
          if (line.startsWith('{')) {
            let potentialJson = '';
            for (let j = i; j < lines.length; j++) {
              potentialJson += lines[j];
              if (lines[j].trim().endsWith('}')) {
                try {
                  return JSON.parse(potentialJson);
                } catch (err) {
                  // Keep going
                }
              }
            }
          }
        }
        logger.error('JSON extraction failed after multiple attempts', { text });
        throw new Error('Failed to parse response as JSON');
      }
    }
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

