# FitDadApp — Setup & Installation Guide

A personal training and weight-loss app with live Apple Health data, customizable plans, and optional AI coaching (Gemini or Claude).

---

## Requirements

| Item | Minimum |
|------|---------|
| Xcode | 15 or later |
| iOS target | 17.0+ |
| macOS (dev machine) | macOS 13 Ventura or later |
| Apple Developer account | Free (sideload) or paid (App Store / TestFlight) |

---

## Installing on Your Phone

### Option A — Free Sideload (no paid account required)

1. Open `FitDadApp.xcodeproj` in Xcode.
2. Plug your iPhone into your Mac with a USB cable.
3. In the top toolbar, click the device selector and choose your iPhone.
4. Go to **Signing & Capabilities** → select your personal Apple ID team.
   - Xcode will auto-create a provisioning profile.
5. Press **⌘R** (Run). Accept any trust prompt on your phone.
6. On your iPhone: **Settings → General → VPN & Device Management** → trust your developer certificate.

> **Note:** Free accounts must re-sign every 7 days. A $99/yr Apple Developer account removes this limit and enables TestFlight.

### Option B — Wireless Install (same Wi-Fi, no cable)

1. Connect via USB once and enable **Window → Devices and Simulators → Connect via network** for your device.
2. Disconnect the cable. Your device will stay available for wireless builds.

### Option C — TestFlight (share with others)

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/).
2. In Xcode, set your team and a unique Bundle ID (e.g. `com.yourname.fitdadapp`).
3. **Product → Archive**, then upload to App Store Connect.
4. Add testers in App Store Connect under **TestFlight → Internal Testing**.

---

## First Launch

1. Grant **Health permissions** when prompted — the app reads steps, heart rate, sleep, active calories, body weight, and nutrition.
2. The **Plan Setup** screen opens automatically on first launch:
   - Enter your current weight, goal weight, height, and age.
   - Choose your activity level and loss pace (Conservative / Moderate / Aggressive).
   - The app calculates your personalized daily calorie and macro targets.
3. Log your starting weight in the **Progress** tab.

---

## Connecting Nutrition Tracking

The app reads nutrition data (calories, protein, carbs, fat) from Apple Health. Any app that writes to Apple Health will automatically appear:

| App | Setup steps |
|-----|-------------|
| **MyFitnessPal** | Settings → Health → Enable "Write Nutrition" |
| **Cronometer** | Settings → Data Sources → Apple Health → Enable all |
| **Lose It!** | Settings → Account → Health App → Connect |
| **YAZIO** | Profile → Connect Apps → Apple Health |
| **Lifesum** | Profile → Integrations → Apple Health |

Once connected, nutrition totals update live every 5 minutes on the Dashboard and Nutrition tabs.

---

## AI Coach Setup

The AI Coach gives personalized weekly check-ins and answers fitness questions using your real Health data.

### Google Gemini (free tier available)

1. Go to [aistudio.google.com](https://aistudio.google.com) and sign in with a Google account.
2. Click **Get API key** → **Create API key**.
3. Copy the key.
4. In the app: **Settings → AI Coach → Provider: Gemini** → paste key → Save.

### Anthropic Claude

1. Go to [console.anthropic.com](https://console.anthropic.com) and create an account.
2. Under **API Keys**, click **Create Key**.
3. Copy the key (shown once — save it).
4. In the app: **Settings → AI Coach → Provider: Claude** → paste key → Save.

> **Security note:** Your API key is stored locally on your device using SwiftData and is never transmitted anywhere except directly to the AI provider's official API endpoint over HTTPS.

---

## Features Overview

### Dashboard
- Live Health metrics: resting HR, steps, active calories, TDEE estimate, sleep, weight
- Dynamic goal progress bar (derived from your plan)
- 7-day steps chart with goal line
- Today's nutrition rings (calories + macros)
- Current training phase card

### Train
- Weekly workout schedule (Mon–Sun)
- Day-by-day exercise cards with sets, reps, and rest times
- One-tap workout logging with duration and notes
- Phase progression overview
- Recent workout history

### Nutrition
- Live today view — calories remaining, macro rings, water intake
- Connected app source badge (shows which app logged the data)
- 7-day nutrition history chart
- Full 7-day meal plan reference with calorie/protein breakdowns

### Habits
- 12 daily habits across Nutrition, Movement, Recovery, and Mindset categories
- Daily check-off with animated completion ring
- Streak tracker

### Progress
- Weight trend chart with goal line
- Log weight manually (one-tap)
- 7-day charts: steps, active calories, sleep
- TDEE and deficit calculator with plan-specific targets
- Weeks remaining estimate

### AI Coach
- Weekly check-in: AI analyzes your actual data and gives specific feedback
- Ask anything: type a question and get an answer grounded in your stats
- Feedback history saved locally
- Supports Gemini 1.5 Flash and Claude 3 Haiku

### Settings
- Edit your plan at any time (weight, goals, pace, activity level)
- AI provider selection and API key management
- HealthKit connection status and manual refresh
- Reset all data option

---

## Updating the App

When you pull new code and rebuild:
- SwiftData handles model migrations automatically for minor changes.
- If a migration fails, use **Settings → Reset All Data** and re-enter your plan.

---

## Privacy

- All data stays on your device (SwiftData local storage).
- Health data is read-only — the app never writes to Apple Health.
- AI requests send only anonymized numeric stats (no names, location, or identifiable data) to the provider you choose.
- API keys are stored in local SwiftData only, never uploaded.
