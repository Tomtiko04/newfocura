export interface MorningSyncInput {
  sleepTime: Date;
  wakeTime: Date;
  initialFocus: number; // 1-5 scale
}

export interface MorningSyncAnalysis {
  sleepDebt: number; // hours of deficit
  sleepInertia: number; // minutes until first peak focus
  energyBaseline: number; // 1-5 scale
  recommendedSchedule: {
    firstPeakStart: Date;
    deepWorkDuration: number; // minutes
    sprintMode: boolean; // true if sleep-deprived
  };
}

export interface DailyBioSync {
  id: string;
  userId: string;
  date: Date;
  sleepTime: Date;
  wakeTime: Date;
  initialFocus: number;
  actualPeaks?: Date[];
}

