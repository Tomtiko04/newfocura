# Focura Mobile App - First Time User Testing Guide

This guide will walk you through testing the app as a first-time user.

## Prerequisites

1. **Backend Server Running**
   - Make sure the backend is running on `http://localhost:3000` (or `http://10.0.2.2:3000` for Android emulator)
   - Database should be set up and migrations applied
   - Environment variables configured (JWT_SECRET, GEMINI_API_KEY, etc.)

2. **Mobile App Running**
   - Flutter app should be running on your device/emulator
   - Make sure you're connected to the backend

## Step-by-Step Testing Guide

### Step 1: Register a New Account

1. **Launch the app** - You should see the Login screen
2. **Tap "Register"** or navigate to the register screen
3. **Fill in the registration form:**
   - Email: `test@example.com` (or any valid email)
   - Password: `password123` (minimum 8 characters)
   - Name: `Test User` (optional)
4. **Tap "Register"**
5. **Expected Result:** 
   - You should be automatically logged in
   - You should be redirected to the Home screen
   - You should see 6 feature cards: Snap, Goals, Tasks, Schedule, Morning Sync, Momentum

---

### Step 2: Morning Sync (Start Your Day)

**Why this first?** The app uses your morning sync data to generate better schedules and calculate momentum scores.

1. **From Home screen**, tap on **"Morning Sync"** card
2. **Fill in your morning check-in:**
   - Tap "Sleep Time" → Select a time (e.g., 11:00 PM)
   - Tap "Wake Time" → Select a time (e.g., 7:00 AM)
   - Adjust "Initial Focus" slider (1-5 scale)
3. **Tap "Submit Morning Sync"**
4. **Expected Result:**
   - Success message appears
   - Analysis dialog shows:
     - Sleep Debt (hours)
     - Sleep Inertia (minutes until peak focus)
     - Energy Baseline (1-5 scale)
   - Screen shows "Sync completed today" indicator

---

### Step 3: Create Your First Goal

1. **From Home screen**, tap on **"Goals"** card
2. **Tap the floating action button** (FAB) with "+" icon
3. **Fill in goal details:**
   - Title: `Learn Flutter Development`
   - Description: `Master Flutter to build mobile apps` (optional)
   - Deadline: Select a date (e.g., 3 months from now)
4. **Tap "Create"**
5. **Expected Result:**
   - Goal appears in the list
   - Shows feasibility score (calculated by AI)
   - May show strategic pivot suggestion if goal is not feasible
   - Shows days until deadline

**Try creating another goal:**
- Title: `Complete Project X`
- Deadline: 1 week from now (to test feasibility warnings)

---

### Step 4: Create Tasks

1. **From Home screen**, tap on **"Tasks"** card
2. **Tap the floating action button** to create a new task
3. **Fill in task details:**
   - Title: `Set up development environment`
   - Description: `Install Flutter SDK and VS Code` (optional)
   - Related Goal: Select "Learn Flutter Development" (optional)
   - Priority: Slide to 4 (High priority)
   - Energy Requirement: Select "High"
   - Implementation Intention: `If it is 9 AM and I am at my desk, then I will open VS Code and start Flutter setup`
4. **Tap "Create"**
5. **Expected Result:**
   - Task appears in the "All" and "Pending" tabs
   - Task card shows priority badge and energy requirement badge

**Create more tasks:**
- `Read Flutter documentation` (Priority: 3, Energy: Medium)
- `Build first Flutter app` (Priority: 5, Energy: High)
- `Review code` (Priority: 2, Energy: Low)

---

### Step 5: Complete Tasks

1. **In Tasks screen**, find a task you created
2. **Tap on the task card** to view details
3. **Tap "Mark Complete"** button
4. **Expected Result:**
   - Task moves to "Completed" tab
   - Task shows checkmark icon
   - Title is struck through

**Try completing subtasks:**
- If a task has subtasks (from Snap feature), you can complete them individually
- Subtask progress bar updates

---

### Step 6: Generate Daily Schedule

1. **From Home screen**, tap on **"Schedule"** card
2. **If no schedule exists:**
   - Tap "Generate Schedule" button
3. **If schedule exists:**
   - Tap refresh icon in app bar to regenerate
4. **Expected Result:**
   - Schedule displays with three sections:
     - **Morning Peak** (Orange background) - High-energy tasks
     - **Afternoon Admin** (Cream background) - Administrative tasks
     - **Evening Reflection** (Purple background) - Reflection tasks
   - Tasks are organized by energy windows
   - Each task shows priority and implementation intention

**Note:** Schedule generation uses:
- Your morning sync data (energy patterns)
- Your pending tasks
- AI planning service

---

### Step 7: View Momentum Score

1. **From Home screen**, tap on **"Momentum"** card
2. **Expected Result:**
   - Shows "Today's Momentum Score" (0-100)
   - Circular progress indicator with score
   - Score breakdown:
     - **Consistency:** Did you complete ≥1 subtask?
     - **Energy Alignment:** Task completion vs energy peaks
     - **Recovery:** Sleep/wake consistency
   - Neuro-feedback message from AI

**To improve momentum:**
- Complete more tasks
- Complete tasks during your peak energy times
- Maintain consistent sleep schedule

---

### Step 8: Test Snap Feature (Optional)

1. **From Home screen**, tap on **"Snap"** card or the FAB
2. **Tap "Take Photo"** button
3. **Take a photo** of handwritten notes or a task list
4. **Tap "Process Snap"** button
5. **Expected Result:**
   - Image is uploaded and processed
   - AI extracts:
     - Tasks
     - Goals
     - Reflections
   - Shows processing status
   - Extracted items are displayed

**Note:** This requires Gemini API to be configured and working.

---

## Testing Different Scenarios

### Scenario 1: Complete User Flow
1. Register → Morning Sync → Create Goal → Create Tasks → Generate Schedule → Complete Tasks → View Momentum

### Scenario 2: Test Feasibility Analysis
1. Create a goal with very short deadline (e.g., "Learn Mandarin in 1 week")
2. Check if AI suggests a strategic pivot

### Scenario 3: Test Energy Alignment
1. Complete morning sync
2. Create tasks with different energy requirements
3. Generate schedule
4. Complete tasks during their scheduled energy windows
5. Check momentum score - Energy Alignment should improve

### Scenario 4: Test Consistency
1. Complete at least one subtask
2. Check momentum score - Consistency should be 100%

---

## Troubleshooting

### Issue: Can't connect to backend
- **Check:** Backend is running on correct port (3000)
- **Android Emulator:** Use `10.0.2.2:3000` instead of `localhost:3000`
- **iOS Simulator:** Use `localhost:3000`
- **Check:** Network permissions in app

### Issue: Login/Register fails
- **Check:** Backend logs for errors
- **Check:** Database is running and migrations applied
- **Check:** JWT_SECRET is set in backend environment

### Issue: Schedule generation fails
- **Check:** Morning sync is completed
- **Check:** You have pending tasks
- **Check:** Planning service is configured

### Issue: Momentum score is 0
- **Complete at least one subtask** (consistency requirement)
- **Submit morning sync** (recovery calculation)
- **Complete tasks during peak energy** (energy alignment)

### Issue: Goals show no feasibility score
- **Check:** Gemini API is configured
- **Check:** Backend logs for API errors
- **Wait:** Feasibility analysis may take a few seconds

---

## Expected App Behavior

### Navigation Flow
```
Login/Register → Home → [Feature Screens]
```

### Data Flow
1. **Morning Sync** → Feeds into Schedule & Momentum
2. **Goals** → Can be linked to Tasks
3. **Tasks** → Feed into Schedule & Momentum
4. **Schedule** → Uses Morning Sync + Tasks
5. **Momentum** → Calculated from Tasks + Morning Sync

### State Management
- All data is fetched from backend APIs
- Pull-to-refresh available on list screens
- Loading states shown during API calls
- Error states with retry options

---

## Quick Test Checklist

- [ ] Register new account
- [ ] Login with existing account
- [ ] Submit morning sync
- [ ] Create a goal
- [ ] View goal details with feasibility analysis
- [ ] Create multiple tasks
- [ ] Complete a task
- [ ] Generate schedule
- [ ] View momentum score
- [ ] Test Snap feature (if Gemini API configured)
- [ ] Logout and login again
- [ ] Verify data persists after logout/login

---

## Next Steps After Testing

1. **Create more realistic goals** with longer deadlines
2. **Build a daily routine** using morning sync
3. **Use the schedule** to plan your day
4. **Track momentum** over multiple days
5. **Use Snap** to digitize handwritten notes

---

## Support

If you encounter issues:
1. Check backend logs: `packages/backend/logs/`
2. Check mobile app console output
3. Verify all environment variables are set
4. Ensure database migrations are applied
5. Check API endpoints are accessible

Happy testing! 🚀

