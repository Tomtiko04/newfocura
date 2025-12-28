export interface MomentumScore {
  id: string;
  userId: string;
  date: Date;
  consistency: boolean; // did ≥1 subtask?
  energyAlignment: number; // 0-1, task completion vs energy peak sync
  recovery: number; // 0-1, sleep/wake consistency
  overallScore: number; // 0-100, calculated from above metrics
}

export interface NeuroFeedback {
  message: string;
  type: 'consistency' | 'energy_alignment' | 'recovery' | 'general';
  timestamp: Date;
}

