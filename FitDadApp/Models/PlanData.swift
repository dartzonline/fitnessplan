import Foundation

// MARK: - All Plan Data
struct PlanData {

    // MARK: Habits
    static let habits: [HabitItem] = [
        HabitItem(id: 1,  category: "Nutrition", icon: "💧", title: "Drink 8+ glasses of water",       color: "#60a5fa"),
        HabitItem(id: 2,  category: "Nutrition", icon: "🥗", title: "Hit protein target (150g)",        color: "#4ade80"),
        HabitItem(id: 3,  category: "Nutrition", icon: "📏", title: "Track calories in app",            color: "#4ade80"),
        HabitItem(id: 4,  category: "Nutrition", icon: "🍽️", title: "No eating after 9 PM",            color: "#4ade80"),
        HabitItem(id: 5,  category: "Nutrition", icon: "🥦", title: "Veggies with every meal",          color: "#4ade80"),
        HabitItem(id: 6,  category: "Movement",  icon: "👣", title: "Hit step goal (8,000+)",           color: "#f97316"),
        HabitItem(id: 7,  category: "Movement",  icon: "🏋️", title: "Complete scheduled workout",      color: "#f97316"),
        HabitItem(id: 8,  category: "Movement",  icon: "🧘", title: "5 min stretch / mobility",         color: "#f97316"),
        HabitItem(id: 9,  category: "Recovery",  icon: "😴", title: "Sleep when baby sleeps",           color: "#a78bfa"),
        HabitItem(id: 10, category: "Recovery",  icon: "⚖️", title: "Weigh in (weekly, same time)",    color: "#a78bfa"),
        HabitItem(id: 11, category: "Mindset",   icon: "📓", title: "Log 1 win for the day",            color: "#f43f5e"),
        HabitItem(id: 12, category: "Mindset",   icon: "🧠", title: "Check in on hunger vs. stress",   color: "#f43f5e"),
    ]

    static let habitCategories = ["Nutrition", "Movement", "Recovery", "Mindset"]

    // MARK: Training Phases
    static let phases: [TrainingPhase] = [
        TrainingPhase(number: 1, label: "Foundation", weeks: "Weeks 1–4",  colorHex: "#4ade80",
                      description: "Build consistency, learn movements, activate metabolism",
                      workoutsPerWeek: 3, cardioMinutes: 20, stepsTarget: 8000,  targetCalories: 1600, weeklyLossLbs: 0.9),
        TrainingPhase(number: 2, label: "Build",       weeks: "Weeks 5–8",  colorHex: "#facc15",
                      description: "Increase intensity, add volume, break first plateau",
                      workoutsPerWeek: 4, cardioMinutes: 30, stepsTarget: 9500,  targetCalories: 1550, weeklyLossLbs: 1.1),
        TrainingPhase(number: 3, label: "Peak",        weeks: "Weeks 9–12", colorHex: "#f97316",
                      description: "Max fat burn, preserve muscle, finish strong",
                      workoutsPerWeek: 5, cardioMinutes: 40, stepsTarget: 11000, targetCalories: 1500, weeklyLossLbs: 1.2),
    ]

    // MARK: Weekly Workouts
    static let weeklyWorkout: [DayWorkout] = [
        DayWorkout(day: "Monday", shortDay: "Mon", type: "Strength", tag: "Upper Body", tagHex: "#4ade80", icon: "💪", duration: "45 min",
                   exercises: [
                    Exercise(name: "Push-Ups (or Bench Press)",   sets: "3", reps: "10–12", rest: "60s"),
                    Exercise(name: "Dumbbell Rows",                sets: "3", reps: "10–12", rest: "60s"),
                    Exercise(name: "Overhead Shoulder Press",      sets: "3", reps: "10–12", rest: "60s"),
                    Exercise(name: "Bicep Curls",                  sets: "3", reps: "12–15", rest: "45s"),
                    Exercise(name: "Tricep Dips / Pushdowns",      sets: "3", reps: "12–15", rest: "45s"),
                    Exercise(name: "Plank",                        sets: "3", reps: "30–45s hold", rest: "45s"),
                   ]),
        DayWorkout(day: "Tuesday", shortDay: "Tue", type: "Cardio", tag: "LISS", tagHex: "#60a5fa", icon: "🚶", duration: "30 min",
                   exercises: [
                    Exercise(name: "Brisk Walk or Light Jog",   sets: "1", reps: "30 min",    rest: "—"),
                    Exercise(name: "Target heart rate zone",    sets: "—", reps: "110–130 bpm", rest: "—"),
                   ]),
        DayWorkout(day: "Wednesday", shortDay: "Wed", type: "Strength", tag: "Lower Body", tagHex: "#a78bfa", icon: "🦵", duration: "45 min",
                   exercises: [
                    Exercise(name: "Goblet Squats",          sets: "3", reps: "12–15",        rest: "60s"),
                    Exercise(name: "Romanian Deadlifts",     sets: "3", reps: "10–12",        rest: "60s"),
                    Exercise(name: "Walking Lunges",         sets: "3", reps: "10 each leg",  rest: "60s"),
                    Exercise(name: "Glute Bridges",          sets: "3", reps: "15–20",        rest: "45s"),
                    Exercise(name: "Calf Raises",            sets: "3", reps: "20",           rest: "30s"),
                    Exercise(name: "Dead Bug Core",          sets: "3", reps: "8 each side",  rest: "45s"),
                   ]),
        DayWorkout(day: "Thursday", shortDay: "Thu", type: "Recovery", tag: "Active Rest", tagHex: "#94a3b8", icon: "🧘", duration: "20 min",
                   exercises: [
                    Exercise(name: "Light Stretching / Yoga", sets: "1", reps: "15–20 min", rest: "—"),
                    Exercise(name: "Foam Rolling",            sets: "1", reps: "5–10 min",  rest: "—"),
                   ]),
        DayWorkout(day: "Friday", shortDay: "Fri", type: "Strength", tag: "Full Body", tagHex: "#f97316", icon: "🔥", duration: "50 min",
                   exercises: [
                    Exercise(name: "Dumbbell Thrusters",  sets: "4", reps: "10–12",       rest: "60s"),
                    Exercise(name: "Bent-Over Rows",      sets: "3", reps: "10–12",       rest: "60s"),
                    Exercise(name: "Step-Ups",            sets: "3", reps: "10 each leg", rest: "60s"),
                    Exercise(name: "Push-Up Variations",  sets: "3", reps: "10–15",       rest: "45s"),
                    Exercise(name: "Farmer's Carry",      sets: "3", reps: "40 steps",    rest: "60s"),
                    Exercise(name: "Russian Twists",      sets: "3", reps: "15 each side",rest: "30s"),
                   ]),
        DayWorkout(day: "Saturday", shortDay: "Sat", type: "Cardio", tag: "HIIT", tagHex: "#f43f5e", icon: "⚡", duration: "25 min",
                   exercises: [
                    Exercise(name: "Jump Squats",       sets: "4", reps: "30s on/30s off", rest: "—"),
                    Exercise(name: "Mountain Climbers", sets: "4", reps: "30s on/30s off", rest: "—"),
                    Exercise(name: "Burpees",           sets: "4", reps: "30s on/30s off", rest: "—"),
                    Exercise(name: "High Knees",        sets: "4", reps: "30s on/30s off", rest: "—"),
                    Exercise(name: "Jumping Jacks",     sets: "4", reps: "30s on/30s off", rest: "—"),
                   ]),
        DayWorkout(day: "Sunday", shortDay: "Sun", type: "Rest", tag: "Full Rest", tagHex: "#64748b", icon: "😴", duration: "—",
                   exercises: [
                    Exercise(name: "Complete rest or leisurely walk", sets: "—", reps: "—", rest: "—"),
                   ]),
    ]

    // MARK: 7-Day Meal Plan
    static let mealPlan: [DayMealPlan] = [
        DayMealPlan(day: "Monday", shortDay: "Mon", meals: [
            MealItem(type: "Breakfast", name: "Greek Yogurt Power Bowl", calories: 380, protein: 28,
                     items: ["1 cup non-fat Greek yogurt", "½ cup blueberries", "1 tbsp almond butter", "2 tbsp granola", "1 tsp honey"]),
            MealItem(type: "Snack",     name: "Apple + String Cheese",   calories: 180, protein: 8,
                     items: ["1 medium apple", "1 low-fat string cheese"]),
            MealItem(type: "Lunch",     name: "Chicken & Veggie Wrap",   calories: 480, protein: 42,
                     items: ["4 oz grilled chicken breast", "1 whole wheat tortilla", "½ cup romaine", "Tomato, cucumber, salsa", "2 tbsp hummus"]),
            MealItem(type: "Dinner",    name: "Salmon + Roasted Veggies",calories: 560, protein: 44,
                     items: ["5 oz baked salmon", "1 cup roasted broccoli + bell pepper", "¾ cup brown rice", "Olive oil, lemon, garlic"]),
        ]),
        DayMealPlan(day: "Tuesday", shortDay: "Tue", meals: [
            MealItem(type: "Breakfast", name: "Veggie Egg Scramble",    calories: 360, protein: 25,
                     items: ["3 whole eggs", "¼ cup spinach + diced peppers", "1 slice whole wheat toast", "1 tsp olive oil"]),
            MealItem(type: "Snack",     name: "Cottage Cheese + Berries",calories: 190, protein: 14,
                     items: ["½ cup low-fat cottage cheese", "½ cup strawberries"]),
            MealItem(type: "Lunch",     name: "Turkey Quinoa Bowl",     calories: 490, protein: 40,
                     items: ["4 oz lean ground turkey", "¾ cup cooked quinoa", "Roasted zucchini + onions", "2 tbsp tzatziki"]),
            MealItem(type: "Dinner",    name: "Shrimp Stir-Fry",        calories: 550, protein: 42,
                     items: ["5 oz shrimp", "Mixed veggies (broccoli, snap peas)", "¾ cup brown rice", "Low-sodium soy sauce + ginger"]),
        ]),
        DayMealPlan(day: "Wednesday", shortDay: "Wed", meals: [
            MealItem(type: "Breakfast", name: "Protein Overnight Oats", calories: 400, protein: 30,
                     items: ["½ cup rolled oats", "1 scoop vanilla protein powder", "1 cup almond milk", "1 tbsp chia seeds", "½ banana"]),
            MealItem(type: "Snack",     name: "Almonds",                 calories: 160, protein: 6,
                     items: ["1 oz (23 almonds)"]),
            MealItem(type: "Lunch",     name: "Big Salad + Tuna",        calories: 460, protein: 38,
                     items: ["4 oz canned tuna (in water)", "Mixed greens, cherry tomatoes", "2 tbsp balsamic vinaigrette", "1 slice rye crispbread"]),
            MealItem(type: "Dinner",    name: "Chicken Tikka + Lentils", calories: 590, protein: 48,
                     items: ["5 oz chicken breast", "½ cup red lentils", "Tomato tikka sauce (light)", "1 whole wheat pita"]),
        ]),
        DayMealPlan(day: "Thursday", shortDay: "Thu", meals: [
            MealItem(type: "Breakfast", name: "Smoothie + Boiled Egg",   calories: 370, protein: 30,
                     items: ["1 cup spinach", "1 frozen banana", "1 scoop protein powder", "1 cup almond milk", "1 hard boiled egg"]),
            MealItem(type: "Snack",     name: "Veggies + Hummus",        calories: 170, protein: 5,
                     items: ["1 cup celery + baby carrots", "3 tbsp hummus"]),
            MealItem(type: "Lunch",     name: "Turkey Lettuce Wraps",    calories: 450, protein: 36,
                     items: ["4 oz lean ground turkey", "Butter lettuce leaves", "Water chestnuts, scallions", "Low-sodium teriyaki sauce"]),
            MealItem(type: "Dinner",    name: "Lean Beef Taco Bowl",     calories: 590, protein: 44,
                     items: ["4 oz extra-lean ground beef", "½ cup black beans", "½ cup brown rice", "Salsa, jalapeño, lime", "1 tbsp light sour cream"]),
        ]),
        DayMealPlan(day: "Friday", shortDay: "Fri", meals: [
            MealItem(type: "Breakfast", name: "Avocado Toast + Eggs",    calories: 420, protein: 24,
                     items: ["2 slices whole wheat toast", "½ avocado (mashed)", "2 poached eggs", "Red pepper flakes, lemon"]),
            MealItem(type: "Snack",     name: "Rice Cake + Peanut Butter",calories: 200, protein: 7,
                     items: ["2 rice cakes", "1.5 tbsp natural peanut butter"]),
            MealItem(type: "Lunch",     name: "Chicken Caesar (light)",  calories: 480, protein: 40,
                     items: ["4 oz grilled chicken", "Romaine lettuce", "2 tbsp light Caesar dressing", "Small handful croutons"]),
            MealItem(type: "Dinner",    name: "Cod + Sweet Potato",      calories: 520, protein: 42,
                     items: ["5 oz baked cod", "1 medium sweet potato", "Steamed asparagus", "Lemon herb seasoning"]),
        ]),
        DayMealPlan(day: "Saturday", shortDay: "Sat", meals: [
            MealItem(type: "Breakfast", name: "Protein Pancakes",        calories: 440, protein: 34,
                     items: ["½ cup oat flour", "1 scoop protein powder", "1 egg", "½ cup almond milk", "Fresh berries + light syrup"]),
            MealItem(type: "Snack",     name: "Edamame",                 calories: 180, protein: 17,
                     items: ["1 cup shelled edamame", "Light sea salt"]),
            MealItem(type: "Lunch",     name: "Shrimp Tacos",            calories: 490, protein: 36,
                     items: ["4 oz grilled shrimp", "2 corn tortillas", "Shredded cabbage, mango salsa", "1 tbsp Greek yogurt"]),
            MealItem(type: "Dinner",    name: "Turkey Meatballs + Zoodles",calories: 540, protein: 46,
                     items: ["5 oz turkey meatballs (baked)", "Zucchini noodles", "Marinara sauce (low sugar)", "1 tbsp parmesan"]),
        ]),
        DayMealPlan(day: "Sunday", shortDay: "Sun", meals: [
            MealItem(type: "Breakfast", name: "Veggie Omelette",         calories: 380, protein: 30,
                     items: ["3 eggs + 1 egg white", "Mushrooms, spinach, tomato", "1 oz low-fat feta", "1 slice whole grain toast"]),
            MealItem(type: "Snack",     name: "Protein Bar",             calories: 200, protein: 15,
                     items: ["1 lower-sugar protein bar (RXBar, Kind Protein)", "Target: 15g+ protein, <200 cal"]),
            MealItem(type: "Lunch",     name: "Chicken Soup + Salad",    calories: 450, protein: 34,
                     items: ["1.5 cups homemade chicken veggie soup", "Side salad with lemon olive oil dressing"]),
            MealItem(type: "Dinner",    name: "Meal Prep Sunday Bowl",   calories: 570, protein: 44,
                     items: ["5 oz baked chicken or fish", "½ cup farro or quinoa", "Roasted seasonal vegetables", "Tahini drizzle"]),
        ]),
    ]
}
