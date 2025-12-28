export enum EnergyState {
  PEAK = 'peak',
  ADMIN = 'admin',
  REFLECTIVE = 'reflective',
}

export enum EnergyLevel {
  HIGH = 'High',
  MEDIUM = 'Medium',
  LOW = 'Low',
}

export interface EnergyWindow {
  start: string; // HH:mm format
  end: string; // HH:mm format
  state: EnergyState;
}

