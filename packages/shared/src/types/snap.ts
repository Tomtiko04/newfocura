export interface SnapExtractedItem {
  type: 'task' | 'goal' | 'reflection';
  original_text: string;
  priority: number; // 1-5
  energy_requirement: 'High' | 'Medium' | 'Low';
  implementation_intention: string; // Peter Gollwitzer format: "[Trigger Situation] + [Planned Action]"
  subtasks: Array<{
    title: string;
    duration_estimate: number; // in minutes
  }>;
  feasibility_warning: string | null;
}

export interface SnapResponse {
  summary: string;
  extracted_items: SnapExtractedItem[];
  daily_structure: {
    morning_peak: string[];
    afternoon_admin: string[];
    evening_reflection: string[];
  };
}

export interface SnapProcessingStatus {
  status: 'uploading' | 'processing' | 'completed' | 'error';
  progress?: number;
  result?: SnapResponse;
  error?: string;
  vectorSyncStatus?: 'pending' | 'syncing' | 'completed' | 'failed';
}

