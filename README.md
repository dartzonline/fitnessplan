# FitDad — Your Personal 12-Week Cut App

A native iOS SwiftUI app built from your Apple Health data. Live HealthKit integration, 
habit tracking, workout plans, meal plan, and weight progress charts — all offline, 
no subscription, no data leaves your phone.

---

## Features

- **Live HealthKit data** — steps, resting HR, sleep, active calories, weight — refreshes every 5 min while app is open
- **Dashboard** — TDEE, phase progress bar, weekly steps chart, newborn-mode tips
- **Workouts** — full 7-day schedule with sets/reps/rest, log completions, phase progression guide
- **Nutrition** — 7-day meal plan with ingredient breakdown, macro targets, calorie deficit
- **Habits** — 12 daily habits with tap-to-check, streak tracking, persistent via SwiftData
- **Progress** — weight log with trend chart, 7-day activity charts (steps/calories/sleep), TDEE card
- **Notifications** — 4 daily reminders (morning, midday, evening, weigh-in)

---

## Requirements

- macOS 13+ with **Xcode 15+** (free from Mac App Store)
- iPhone with iOS 17+ (or Xcode simulator — but HealthKit won't return real data on simulator)
- Apple Developer account (free account works for installing on your own device via USB)

---

## Setup — Step by Step

### 1. Open in Xcode
```
Double-click: FitDadApp.xcodeproj
```

### 2. Set your Development Team
- Click **FitDadApp** in the project navigator (top left)
- Select the **FitDadApp** target
- Under **Signing & Capabilities** → set **Team** to your Apple ID

### 3. Add HealthKit capability
- Still in **Signing & Capabilities**
- Click **+ Capability** → search **HealthKit** → double-click to add
- This is required for Apple Health access

### 4. Add your Bundle ID
- Change `com.yourname.FitDadApp` to something unique (e.g. `com.johndoe.FitDad`)
- Must be unique across all Apple devices

### 5. Connect your iPhone
- Plug in via USB → trust the computer on your phone
- Select your device from the device picker at the top of Xcode

### 6. Build & Run
```
Cmd + R
```

### 7. Grant permissions on first launch
- Allow Apple Health access (select ALL metrics for best experience)
- Allow notifications

---

## Project Structure

```
FitDadApp/
├── FitDadApp.swift              # App entry point, dependency injection
├── Models/
│   ├── Models.swift             # SwiftData models + data structs
│   └── PlanData.swift           # All plan content (workouts, meals, habits)
├── Services/
│   ├── HealthKitService.swift   # Live HealthKit reads, 5-min polling
│   └── NotificationService.swift # Daily reminders
├── Views/
│   ├── ContentView.swift        # Tab bar
│   ├── DashboardView.swift      # Home screen with live metrics
│   ├── WorkoutsView.swift       # Workout schedule + logging
│   ├── NutritionView.swift      # 7-day meal plan
│   ├── HabitsView.swift         # Daily habit checklist + streaks
│   ├── ProgressView.swift       # Weight log + activity charts
│   └── SharedComponents.swift   # GlassCard, colors, reusable UI
└── Resources/
    └── Info.plist               # HealthKit + notification permissions
```

---

## Customizing the Plan

**To change your starting weight goal:**  
Edit `goalLbs` in `ProgressView_.swift` (line ~20)

**To add/remove habits:**  
Edit `PlanData.habits` in `Models/PlanData.swift`

**To change meal plan:**  
Edit `PlanData.mealPlan` in `Models/PlanData.swift`

**To adjust calorie targets:**  
Edit `PlanData.phases[x].targetCalories`

---

## Newborn Mode

The app has a reduced calorie deficit (300–400 cal instead of 500) built into the 
TDEE card calculations. This is intentional — sleep deprivation raises cortisol, 
which makes aggressive deficits counterproductive. The plan is calibrated to be 
sustainable while you're running on fumes.

---

## Troubleshooting

**HealthKit returns zeros?**
- Must run on a real device, not simulator
- Go to Settings → Privacy → Health → FitDad → enable all categories

**Build errors?**
- Make sure Xcode 15+ is installed (Charts framework requires it)
- Clean build: Product → Clean Build Folder (Shift+Cmd+K), then run again

**"No team" signing error?**
- Sign in to Xcode with your Apple ID: Xcode → Settings → Accounts → Add Apple ID

---

Built with ❤️ and SwiftUI. No ads, no subscriptions, no cloud. Your data stays on your phone.
