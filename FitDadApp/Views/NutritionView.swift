import SwiftUI
import Charts

struct NutritionView: View {
    @EnvironmentObject var health: HealthKitService
    @State private var selectedDayIndex: Int = {
        let wd = Calendar.current.component(.weekday, from: .now)
        return max(0, (wd + 5) % 7)
    }()
    @State private var pageTab = 0   // 0 = Today (live), 1 = Meal Plan

    private var plan: DayMealPlan { PlanData.mealPlan[selectedDayIndex] }
    private var tdee: Double { health.snapshot.tdee > 0 ? health.snapshot.tdee : 2077 }

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Tab toggle
                        Picker("", selection: $pageTab) {
                            Text("Today (Live)").tag(0)
                            Text("Meal Plan").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        if pageTab == 0 {
                            liveTodaySection
                        } else {
                            mealPlanSection
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Nutrition")
        }
    }

    // ─── LIVE TODAY ────────────────────────────────────────────────────────────

    var liveTodaySection: some View {
        VStack(spacing: 14) {
            sourceCard
            calorieRingCard
            macroLiveGrid
            weeklyCaloriesChart
            waterCard
            setupPrompt
        }
        .padding(.horizontal, 16)
    }

    /// Shows which app logged the data
    var sourceCard: some View {
        GlassCard(tint: health.nutritionDataAvailable ? AppColors.green : AppColors.yellow) {
            HStack(spacing: 12) {
                Text(health.nutritionDataAvailable ? "🔗" : "📲").font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(health.nutritionDataAvailable ? "Connected via Apple Health" : "No food data logged today")
                        .font(.subheadline).bold()
                        .foregroundColor(health.nutritionDataAvailable ? AppColors.green : AppColors.yellow)
                    Text(health.nutritionDataAvailable
                         ? "Source: \(health.snapshot.nutritionSource) · Updates every 5 min"
                         : "Log food in MyFitnessPal, Cronometer, or Lose It — enable Apple Health sync in that app's settings")
                        .font(.caption).foregroundColor(AppColors.textSecondary).lineSpacing(2)
                }
            }
        }
    }

    /// Big calorie ring with remaining
    var calorieRingCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                // Donut ring
                ZStack {
                    AnimatedRing(progress: 1.0,           color: AppColors.cardSurface, lineWidth: 14, size: 100)
                    AnimatedRing(progress: health.snapshot.calorieProgress,
                                 color: calorieRingColor, lineWidth: 14, size: 100)
                    VStack(spacing: 2) {
                        Text("\(Int(health.snapshot.loggedCalories))")
                            .font(.title3).bold().foregroundColor(.white)
                        Text("cal").font(.caption2).foregroundColor(AppColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    calorieRow(label: "Logged",    value: Int(health.snapshot.loggedCalories), color: calorieRingColor)
                    calorieRow(label: "Target",    value: Int(health.snapshot.targetCalories), color: AppColors.textSecondary)
                    calorieRow(label: "Remaining", value: Int(health.snapshot.remainingCalories),
                               color: health.snapshot.loggedCalories > health.snapshot.targetCalories ? AppColors.red : AppColors.green)
                    calorieRow(label: "Burned",    value: Int(health.snapshot.activeCalories),  color: AppColors.orange)
                    Divider().background(AppColors.cardSurface)
                    calorieRow(label: "Net",
                               value: Int(health.snapshot.loggedCalories - health.snapshot.activeCalories),
                               color: AppColors.blue)
                }
            }
        }
    }

    private var calorieRingColor: Color {
        let p = health.snapshot.calorieProgress
        if p > 1.1 { return AppColors.red }
        if p > 0.85 { return AppColors.orange }
        return AppColors.green
    }

    private func calorieRow(label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(AppColors.textSecondary).frame(width: 72, alignment: .leading)
            Text("\(value)").font(.caption).bold().foregroundColor(color)
        }
    }

    /// Macro progress bars — live vs target
    var macroLiveGrid: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Macros Today").font(.subheadline).bold().foregroundColor(.white)
                    Spacer()
                    Text("Logged / Target").font(.caption2).foregroundColor(AppColors.textTertiary)
                }

                MacroLiveRow(
                    name: "Protein", icon: "🥩",
                    logged: health.snapshot.loggedProteinG,
                    target: health.snapshot.targetProteinG,
                    unit: "g", color: AppColors.green)

                MacroLiveRow(
                    name: "Carbs", icon: "🍞",
                    logged: health.snapshot.loggedCarbsG,
                    target: health.snapshot.targetCarbsG,
                    unit: "g", color: AppColors.blue)

                MacroLiveRow(
                    name: "Fat", icon: "🥑",
                    logged: health.snapshot.loggedFatG,
                    target: health.snapshot.targetFatG,
                    unit: "g", color: AppColors.orange)
            }
        }
    }

    /// 7-day calorie history chart
    var weeklyCaloriesChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Calories — Last 7 Days").font(.subheadline).bold().foregroundColor(.white)
                    Spacer()
                    Text("Target: \(Int(health.snapshot.targetCalories))")
                        .font(.caption2).foregroundColor(AppColors.textSecondary)
                }

                if health.weeklyNutrition.isEmpty || health.weeklyNutrition.allSatisfy({ $0.calories == 0 }) {
                    Text("No food data found in Apple Health yet.\nLog food in MFP or Cronometer and enable Health sync.")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20).frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(health.weeklyNutrition) { entry in
                            BarMark(
                                x: .value("Day",     entry.dayLabel),
                                y: .value("Calories", entry.calories)
                            )
                            .foregroundStyle(entry.calories > health.snapshot.targetCalories
                                             ? AppColors.red.gradient
                                             : AppColors.green.opacity(0.7).gradient)
                            .cornerRadius(4)
                        }
                        RuleMark(y: .value("Target", health.snapshot.targetCalories))
                            .foregroundStyle(AppColors.yellow.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .annotation(position: .trailing) {
                                Text("goal").font(.system(size: 9)).foregroundColor(AppColors.yellow)
                            }
                    }
                    .frame(height: 130)
                    .chartXAxis {
                        AxisMarks { _ in AxisValueLabel().foregroundStyle(AppColors.textTertiary) }
                    }
                    .chartYAxis {
                        AxisMarks(values: .stride(by: 400)) { _ in
                            AxisValueLabel().foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                // Macro breakdown sparklines (last 7 days)
                if !health.weeklyNutrition.allSatisfy({ $0.proteinG == 0 }) {
                    Divider().background(AppColors.cardSurface)
                    Text("Protein 7-day trend").font(.caption2).foregroundColor(AppColors.textTertiary)
                    Chart {
                        ForEach(health.weeklyNutrition) { entry in
                            LineMark(x: .value("Day", entry.dayLabel), y: .value("Protein", entry.proteinG))
                                .foregroundStyle(AppColors.green)
                            AreaMark(x: .value("Day", entry.dayLabel), y: .value("Protein", entry.proteinG))
                                .foregroundStyle(AppColors.green.opacity(0.1))
                        }
                        RuleMark(y: .value("Target", health.snapshot.targetProteinG))
                            .foregroundStyle(AppColors.green.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    }
                    .frame(height: 60)
                    .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(AppColors.textTertiary) } }
                    .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(AppColors.textTertiary) } }
                }
            }
        }
    }

    /// Water intake
    var waterCard: some View {
        GlassCard(tint: AppColors.blue) {
            HStack {
                Text("💧").font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Water Today")
                        .font(.subheadline).bold().foregroundColor(.white)
                    Text(health.snapshot.loggedWaterML > 0
                         ? String(format: "%.0f ml logged (goal: 2,000 ml)", health.snapshot.loggedWaterML)
                         : "No water logged in Health yet — track in MFP or Apple Health")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if health.snapshot.loggedWaterML > 0 {
                    Text(String(format: "%.0f%%", min(health.snapshot.loggedWaterML / 2000 * 100, 100)))
                        .font(.headline).bold().foregroundColor(AppColors.blue)
                }
            }
        }
    }

    /// Setup instructions if no data
    var setupPrompt: some View {
        GlassCard(tint: AppColors.purple) {
            VStack(alignment: .leading, spacing: 10) {
                Text("🔧 How to connect your food tracker").font(.subheadline).bold().foregroundColor(AppColors.purple)
                ForEach([
                    ("MyFitnessPal", "Profile → Settings → Apps & Devices → Health app → turn on Nutrition"),
                    ("Cronometer",   "Account → Integrations → Apple Health → enable Write Nutrition"),
                    ("Lose It!",     "Profile → App Settings → Integrations → Apple Health → Nutrition on"),
                    ("YAZIO",        "More → Settings → Health app → enable Nutrition Data"),
                ], id: \.0) { app, steps in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app).font(.caption).bold().foregroundColor(.white)
                        Text(steps).font(.caption2).foregroundColor(AppColors.textSecondary).lineSpacing(2)
                    }
                    .padding(.vertical, 2)
                    if app != "YAZIO" { Divider().background(AppColors.cardSurface) }
                }
            }
        }
    }

    // ─── MEAL PLAN ─────────────────────────────────────────────────────────────

    var mealPlanSection: some View {
        VStack(spacing: 12) {
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<PlanData.mealPlan.count, id: \.self) { i in
                        Button { withAnimation { selectedDayIndex = i } } label: {
                            Text(PlanData.mealPlan[i].shortDay)
                                .font(.caption2).bold()
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedDayIndex == i ? AppColors.green : AppColors.cardBackground)
                                .foregroundColor(selectedDayIndex == i ? .black : AppColors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Daily summary tiles
            let deficit = Int(tdee) - plan.totalCalories
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SummaryTile(value: "\(plan.totalCalories)", label: "calories", color: AppColors.green)
                    SummaryTile(value: "\(plan.totalProtein)g",  label: "protein",  color: AppColors.blue)
                    SummaryTile(value: "\(deficit > 0 ? "–" : "+")\(abs(deficit))", label: "deficit", color: AppColors.orange)
                }
                MacroProgressBar(calories: plan.totalCalories)
            }
            .padding(.horizontal, 16)

            // Meals
            ForEach(plan.meals) { meal in
                MealCard(meal: meal).padding(.horizontal, 16)
            }

            MacroTargetsCard().padding(.horizontal, 16)
        }
    }
}

// MARK: - Live Macro Row

struct MacroLiveRow: View {
    let name: String
    let icon: String
    let logged: Double
    let target: Double
    let unit: String
    let color: Color

    private var progress: Double { target > 0 ? min(logged / target, 1.5) : 0 }
    private var overTarget: Bool { logged > target * 1.05 }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(icon).font(.caption)
                Text(name).font(.caption).foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(logged > 0
                     ? String(format: "%.0f / %.0f%@", logged, target, unit)
                     : "—  /  \(Int(target))\(unit)")
                    .font(.caption).bold()
                    .foregroundColor(overTarget ? AppColors.red : color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.cardSurface).frame(height: 7)
                    Capsule()
                        .fill(overTarget ? AppColors.red : color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 7)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 7)
        }
    }
}

// ─── Meal Plan helpers (kept from original) ────────────────────────────────

struct SummaryTile: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        GlassCard {
            VStack(spacing: 2) {
                Text(value).font(.title3).bold().foregroundColor(color)
                Text(label).font(.caption2).foregroundColor(AppColors.textSecondary)
            }.frame(maxWidth: .infinity)
        }
    }
}

struct MacroProgressBar: View {
    let calories: Int
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plan Macros").font(.subheadline).bold().foregroundColor(.white)
                MacroRow(name: "Protein", g: 150, target: 150, color: AppColors.green)
                MacroRow(name: "Carbs",   g: 160, target: 160, color: AppColors.blue)
                MacroRow(name: "Fat",     g: 53,  target: 53,  color: AppColors.orange)
            }
        }
    }
}

struct MacroRow: View {
    let name: String; let g: Int; let target: Int; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(name).font(.caption).foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(g)g / \(target)g").font(.caption).bold().foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.cardSurface).frame(height: 6)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(min(Double(g) / Double(target), 1.0)), height: 6)
                }
            }.frame(height: 6)
        }
    }
}

struct MealCard: View {
    let meal: MealItem
    @State private var expanded = false
    private var typeColor: Color {
        switch meal.type {
        case "Breakfast": return AppColors.yellow
        case "Lunch":     return AppColors.blue
        case "Dinner":    return AppColors.orange
        default:          return AppColors.purple
        }
    }
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TagPill(text: meal.type, color: typeColor)
                    Text(meal.name).font(.subheadline).bold().foregroundColor(.white)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(meal.calories) cal").font(.caption).bold().foregroundColor(AppColors.green)
                        Text("\(meal.protein)g protein").font(.caption2).foregroundColor(AppColors.textSecondary)
                    }
                }
                Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                    HStack {
                        Text(expanded ? "Hide ingredients" : "Show ingredients")
                            .font(.caption).foregroundColor(AppColors.textTertiary)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9)).foregroundColor(AppColors.textTertiary)
                    }
                }
                if expanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(meal.items, id: \.self) { item in
                            HStack(spacing: 6) {
                                Circle().fill(typeColor).frame(width: 4, height: 4)
                                Text(item).font(.caption).foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }.transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

struct MacroTargetsCard: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Nutrition Tips").font(.subheadline).bold().foregroundColor(AppColors.yellow)
                ForEach([
                    "Eat protein at every meal to preserve muscle while in a deficit.",
                    "Prep Sunday meals in bulk — saves time on exhausted newborn days.",
                    "Keep healthy snacks visible; hide junk food. Environment > willpower.",
                    "If you miss a meal, don't double up — just continue normally.",
                ], id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundColor(AppColors.yellow)
                        Text(tip).font(.caption).foregroundColor(AppColors.textSecondary).lineSpacing(2)
                    }
                }
            }
        }
    }
}
