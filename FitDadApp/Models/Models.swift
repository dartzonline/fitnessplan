import Foundation
import SwiftData

// MARK: - Weight Entry
@Model
final class WeightEntry {
    var date: Date
    var weightLbs: Double
    var note: String

    init(date: Date = .now, weightLbs: Double, note: String = "") {
        self.date = date
        self.weightLbs = weightLbs
        self.note = note
    }
}

// MARK: - Habit Log (daily check-ins)
@Model
final class HabitLog {
    var date: Date
    var habitID: Int
    var completed: Bool

    init(date: Date, habitID: Int, completed: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.habitID = habitID
        self.completed = completed
    }
}

// MARK: - Workout Log
@Model
final class WorkoutLog {
    var date: Date
    var workoutName: String
    var durationMinutes: Int
    var completed: Bool
    var notes: String

    init(date: Date = .now, workoutName: String, durationMinutes: Int, completed: Bool = false, notes: String = "") {
        self.date = date
        self.workoutName = workoutName
        self.durationMinutes = durationMinutes
        self.completed = completed
        self.notes = notes
    }
}

// MARK: - User Fitness Profile (customizable plan)
@Model
final class UserProfile {
    var currentWeightLbs: Double
    var goalWeightLbs: Double
    var heightInches: Double
    var age: Int
    var activityLevel: String        // sedentary, light, moderate, active, very_active
    var goalPace: String             // conservative (0.5/wk), moderate (1/wk), aggressive (1.5/wk)
    var weeklyWorkoutDays: Int
    var planStartDate: Date
    var planName: String
    var aiProvider: String           // none, gemini, claude
    var aiApiKey: String

    init(
        currentWeightLbs: Double = 0,
        goalWeightLbs: Double = 0,
        heightInches: Double = 70,
        age: Int = 30,
        activityLevel: String = "moderate",
        goalPace: String = "moderate",
        weeklyWorkoutDays: Int = 4,
        planStartDate: Date = .now,
        planName: String = "My Plan",
        aiProvider: String = "none",
        aiApiKey: String = ""
    ) {
        self.currentWeightLbs = currentWeightLbs
        self.goalWeightLbs = goalWeightLbs
        self.heightInches = heightInches
        self.age = age
        self.activityLevel = activityLevel
        self.goalPace = goalPace
        self.weeklyWorkoutDays = weeklyWorkoutDays
        self.planStartDate = planStartDate
        self.planName = planName
        self.aiProvider = aiProvider
        self.aiApiKey = aiApiKey
    }

    var goalWeightLossLbs: Double { max(0, currentWeightLbs - goalWeightLbs) }

    var dailyCalorieTarget: Double {
        // Mifflin-St Jeor BMR (male default)
        let bmr = 10 * (currentWeightLbs * 0.453592) + 6.25 * (heightInches * 2.54) - 5 * Double(age) + 5
        let multipliers: [String: Double] = [
            "sedentary": 1.2, "light": 1.375, "moderate": 1.55,
            "active": 1.725, "very_active": 1.9
        ]
        let tdee = bmr * (multipliers[activityLevel] ?? 1.55)
        let deficits: [String: Double] = [
            "conservative": 250, "moderate": 500, "aggressive": 750
        ]
        return max(1200, tdee - (deficits[goalPace] ?? 500))
    }

    var weeklyLossTarget: Double {
        switch goalPace {
        case "conservative": return 0.5
        case "aggressive": return 1.5
        default: return 1.0
        }
    }

    var estimatedWeeksToGoal: Int {
        guard weeklyLossTarget > 0 else { return 0 }
        return Int(ceil(goalWeightLossLbs / weeklyLossTarget))
    }

    var estimatedCompletionDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: estimatedWeeksToGoal, to: planStartDate) ?? planStartDate
    }

    var currentWeekNumber: Int {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: planStartDate, to: .now).weekOfYear ?? 0
        return max(1, weeks + 1)
    }

    var dailyProteinTarget: Double { currentWeightLbs * 0.8 }
    var dailyCarbTarget: Double { (dailyCalorieTarget * 0.40) / 4 }
    var dailyFatTarget: Double { (dailyCalorieTarget * 0.30) / 9 }
}

// MARK: - AI Feedback Entry
@Model
final class AIFeedbackEntry {
    var date: Date
    var provider: String
    var prompt: String
    var response: String
    var category: String  // weekly_checkin, nutrition, workout, general

    init(date: Date = .now, provider: String, prompt: String, response: String, category: String = "general") {
        self.date = date
        self.provider = provider
        self.prompt = prompt
        self.response = response
        self.category = category
    }
}

// MARK: - Habit Definition (static data)
struct HabitItem: Identifiable {
    let id: Int
    let category: String
    let icon: String
    let title: String
    let color: String // hex
}

// MARK: - Workout Definition (static data)
struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: String
    let reps: String
    let rest: String
}

struct DayWorkout: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    let type: String
    let tag: String
    let tagHex: String
    let icon: String
    let duration: String
    let exercises: [Exercise]
}

// MARK: - Meal Data
struct MealItem: Identifiable {
    let id = UUID()
    let type: String   // Breakfast / Snack / Lunch / Dinner
    let name: String
    let calories: Int
    let protein: Int
    let items: [String]
}

struct DayMealPlan: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    let meals: [MealItem]
    var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int  { meals.reduce(0) { $0 + $1.protein } }
}

// MARK: - Phase
struct TrainingPhase: Identifiable {
    let id = UUID()
    let number: Int
    let label: String
    let weeks: String
    let colorHex: String
    let description: String
    let workoutsPerWeek: Int
    let cardioMinutes: Int
    let stepsTarget: Int
    let targetCalories: Int
    let weeklyLossLbs: Double
}

// MARK: - Health Snapshot (from HealthKit)
struct HealthSnapshot {
    var restingHR: Double = 0
    var dailySteps: Double = 0
    var activeCalories: Double = 0
    var basalCalories: Double = 0
    var sleepHours: Double = 0
    var latestWeightLbs: Double = 0
    var heartRateVariability: Double = 0
    var vo2Max: Double = 0

    // Nutrition — written by MFP, Cronometer, Lose It, etc. via Apple Health
    var loggedCalories: Double = 0
    var loggedProteinG: Double = 0
    var loggedCarbsG: Double = 0
    var loggedFatG: Double = 0
    var loggedWaterML: Double = 0

    // Dynamic targets — set from UserProfile
    var targetCalories: Double = 1600
    var targetProteinG: Double = 150
    var targetCarbsG: Double = 160
    var targetFatG: Double = 53

    var tdee: Double { basalCalories + activeCalories }
    var suggestedDailyCalories: Double { max(1200, tdee - 500) }

    var remainingCalories: Double { max(0, targetCalories - loggedCalories) }
    var calorieProgress: Double { targetCalories > 0 ? min(loggedCalories / targetCalories, 1.5) : 0 }
    var proteinProgress: Double { targetProteinG > 0 ? min(loggedProteinG / targetProteinG, 1.5) : 0 }
    var carbsProgress: Double   { targetCarbsG > 0   ? min(loggedCarbsG / targetCarbsG, 1.5) : 0 }
    var fatProgress: Double     { targetFatG > 0     ? min(loggedFatG / targetFatG, 1.5) : 0 }

    var nutritionSource: String = "Not logged yet"
}

// MARK: - Daily Nutrition Entry (7-day history, from HealthKit)
struct DailyNutritionEntry: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double

    var dayLabel: String {
        Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
    }
}
