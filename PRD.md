Give every user a personalized planning experience that feels designed specifically for them.

# **2. Target User**

- Students
- Founders
- Busy professionals
- Self-improvement enthusiasts
- People who use notebooks + digital tools
- People who want personalized planning and reflection

### **Focura = Your personal planning assistant**

It does the planning _for_ you by understanding:

- your notes
- your voice
- your goals
- your habits
- your patterns

### **A. Mood + Energy Pattern Tracking**

AI builds personal patterns:

- when user is productive
- when they skip tasks
- days of high stress
- sleep or energy signals based on voice

### **C. Accountability System (Improved Unlike Atoms)**

- Users add friends
- App notifies when a friend **misses** their habit
- You can see **missed vs done**
- Real check-in reminders (“Check on Fatima’s habit today.”)
- Weekly accountability summary

Monorepo Monolithic Architecture

Product Requirements Document: Ink & Intellect (V1.0)1. Product Vision & GoalsVision: To create a "living" productivity partner that respects the tactile focus of paper planning while providing the strategic intelligence of AI.Primary Goal: Enable users to move from "scattered ideas" to "scientific execution" via a seamless Snap-to-System workflow.Success Metric: $70\%$ goal achievement rate for active users within the first 6 months.2. Target AudienceTactile High-Achievers: Professionals who love the cognitive benefits of writing by hand but struggle with digital organization.Self-Development Enthusiasts: Users focused on long-term growth (1-year goals) who need accountability and "feasibility" checks.3. Core Functional Requirements3.1 Multimodal "Snap" Engine (The Bridge)Feature: Users take a photo of their handwritten journal, planner, or sticky note.AI Logic (Gemini 3 Flash): _ Structure-Aware Extraction: Recognize bullets as tasks, stars as priorities, and paragraphs as reflections.Intent Parsing: Differentiate between a task ("Call Sam") and an implementation intention ("If I am at the desk at 9 AM, I will call Sam").Output: Automatically populates the digital task list and journal history.3.2 Strategic Goal Hierarchy & FeasibilityFeature: A dedicated "North Star" module for 1-year goals.Requirement: Users input "The Why" and "The Deadline."AI Feasibility Test: The AI calculates a Feasibility Score based on the user's current load and the complexity of the goal.Logic: If the goal is "Learn Mandarin in 3 months" while working 50 hours/week, the AI suggests a "Strategic Pivot" (e.g., aiming for HSK 1 instead).3.3 The Recursive Planning LoopDaily: AI generates a "Scientific Schedule" based on the user’s chronotype (Energy peaks).Weekly/Monthly: AI reviews completed tasks and reflections to auto-suggest the next sprint's milestones.Reflection Feedback: At 9:00 PM, the app prompts for a "Submission." The AI uses this data to refine tomorrow's plan.4. Scientific Framework (The "Brain" Logic)The app doesn't just list tasks; it arranges them using Chronobiology:Deep Work Slots: Scheduled during the user's identified "Peak Energy" (e.g., 8:00 AM – 11:00 AM).Administrative Buffers: Scheduled during "Low Energy" dips (e.g., 2:00 PM – 4:00 PM).Implementation Intentions: Every task snapped from paper is converted into an "If-Then" statement to increase the likelihood of completion by $2x$.5. Technical ArchitectureFrontend: FlutterWhy: Cross-platform (iOS/Android) with high-performance camera integration for the "Snap" feature.State Management: Riverpod for real-time UI updates when AI processes a photo.Backend: Node.js (TypeScript)Why: Scalable, non-blocking I/O ideal for handling multiple AI API calls.Database: PostgreSQL (for structured user data) + Vector Database (Pinecone) to store long-term "Reflections" so Gemini 3 can "remember" your life patterns.Intelligence: Gemini 3 FlashVision Capability: Handles OCR and layout analysis in a single pass.Thinking Level: _ Daily Snaps: Use minimal thinking level (Low latency).Weekly Strategy: Use high thinking level (Deep reasoning).6. User Experience (UX) DesignThe "Hybrid" Feel: The UI should use warm, paper-like textures (cream/parchment) with modern, minimalist digital typography.The "Live" Notification: Instead of "Task Due," use: "You're in your peak energy window. Ready to tackle 'Project Alpha'?"

# GOAL

Process images of handwritten notes or typed text. Extract tasks, goals, and reflections. Rearrange and decompose them based on "Cognitive Load Theory" to ensure the user's Prefrontal Cortex (PFC) remains focused and not overwhelmed.

# SCIENTIFIC CONSTRAINTS

1. TASK DECOMPOSITION: Every primary task must be broken into 3-5 "Micro-Subtasks" (max 15 mins each). This bypasses procrastination.
2. IMPLEMENTATION INTENTIONS: For every task, generate an "If-Then" trigger (e.g., "If it is 9 AM and I am at my desk, then I will [Task]").
3. ENERGY MAPPING: Categorize tasks into "Peak" (High focus), "Administrative" (Low energy), or "Reflective."
4. STRUCTURED OCR: Recognize symbols (Stars = Priority, Circles = Habit, Arrows = Migration).

# OUTPUT FORMAT (Strict JSON)

Return ONLY a valid JSON object. Do not include prose or conversational filler.
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
}

2. Technical Implementation Detail (Flutter/Node)
   When your Node.js backend sends the image to Gemini 3 Flash, ensure you set the response_mime_type to application/json and the media_resolution to ultra_high to capture fine ink strokes.

Why this works for the Brain:
Reduced Cognitive Load: The AI does the heavy lifting of "figuring out the first step." Instead of seeing "Write Report," the user sees "Open doc and title it."

Dopamine Looping: By checking off 3 subtasks quickly, the brain receives small dopamine hits, creating momentum for the larger goal.

Decision Fatigue Prevention: The "Implementation Intentions" remove the need for the user to "decide" when to start. The trigger (time/place) decides for them.

3. Example Response Logic
   If a user snaps a photo that says: "Work on Project X - Important!!" The AI (following your instructions) will transform it into:

Task: Deep Work on Project X Subtasks:

Clear desk and open Project X folder (2 mins)

Outline the first 3 sections (10 mins)

Write 200 words for the intro (15 mins) Implementation Intention: "If it is 10:00 AM and I have finished my coffee, then I will open my laptop to Project X."
