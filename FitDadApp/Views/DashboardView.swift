import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var health: HealthKitService
    @Query(sort: \WeightEntry.date, order: .reverse) var weightEntries: [WeightEntry]
    @Query var habitLogs: [HabitLog]
    @Query var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var currentWeight: Double {
        weightEntries.first?.weightLbs ?? health.snapshot.latestWeightLbs
    }
    private var startWeight: Double {
        weightEntries.last?.weightLbs ?? profile?.currentWeightLbs ?? 0
    }
    private var lostSoFar: Double { max(0, startWeight - currentWeight) }
    private var goalLbs: Double { profile?.goalWeightLossLbs ?? 20 }
    private var goalWeight: Double { profile?.goalWeightLbs ?? (startWeight - goalLbs) }

    private var todayHabitsCompleted: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.completed }.count
    }

    private var currentPhase: TrainingPhase { PlanData.phases[0] }
    private var weekNumber: Int { profile?.currentWeekNumber ?? 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        liveMetricsGrid
                        weeklyStepsChart
                        nutritionRingsCard
                        phaseCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(profile?.planName ?? "My Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await health.fetchAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.green)
                    }
                }
            }
        }
    }

    // MARK: - Header
    var headerCard: some View {
        GlassCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(weekNumber)")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                    Text(String(format: "%.0f lb Goal", goalLbs))
                        .font(.title2).bold().foregroundColor(.white)
                    if let p = profile {
                        Text("\(p.planStartDate.formatted(date: .abbreviated, time: .omitted)) → \(p.estimatedCompletionDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2).foregroundColor(AppColors.textTertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "–%.1f lbs", lostSoFar))
                        .font(.title).bold().foregroundColor(AppColors.green)
                    Text("lost so far")
                        .font(.caption2).foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.bottom, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.cardSurface).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [AppColors.green, Color(hex: "#22c55e")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(min(lostSoFar / max(goalLbs, 1), 1.0)), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.top, 4)

            HStack {
                Text(String(format: "%.0f lbs", startWeight)).font(.caption2).foregroundColor(AppColors.textTertiary)
                Spacer()
                Text(String(format: "%.0f%%", min(lostSoFar / max(goalLbs, 1) * 100, 100))) .font(.caption2).foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f lbs", goalWeight)).font(.caption2).foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Live Metrics Grid
    var liveMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Live Health Data", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption).foregroundColor(AppColors.green)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(icon: "❤️", value: health.snapshot.restingHR > 0 ? "\(Int(health.snapshot.restingHR)) bpm" : "—",
                           label: "Resting HR", sub: "Healthy <70", color: .red)
                MetricTile(icon: "👣", value: health.snapshot.dailySteps > 0 ? "\(Int(health.snapshot.dailySteps).formatted())" : "—",
                           label: "Steps Today", sub: "Goal: \(currentPhase.stepsTarget.formatted())", color: AppColors.orange)
                MetricTile(icon: "🔥", value: health.snapshot.activeCalories > 0 ? "\(Int(health.snapshot.activeCalories))" : "—",
                           label: "Active Cal", sub: "Today", color: AppColors.yellow)
                MetricTile(icon: "⚡", value: health.snapshot.tdee > 0 ? "\(Int(health.snapshot.tdee))" : "—",
                           label: "Est. TDEE", sub: "Total burn", color: AppColors.blue)
                MetricTile(icon: "😴", value: health.snapshot.sleepHours > 0 ? String(format: "%.1fh", health.snapshot.sleepHours) : "—",
                           label: "Sleep", sub: "Last night", color: AppColors.purple)
                MetricTile(icon: "⚖️",
                           value: health.snapshot.latestWeightLbs > 0 ? String(format: "%.1f lbs", health.snapshot.latestWeightLbs) : "—",
                           label: "Weight", sub: "From Health", color: AppColors.green)
            }
        }
    }

    // MARK: - Nutrition Rings
    var nutritionRingsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nutrition Today").font(.subheadline).bold().foregroundColor(.white)
                    Spacer()
                    if health.snapshot.nutritionSource != "Not logged yet" {
                        TagPill(text: health.snapshot.nutritionSource, color: AppColors.green)
                    }
                }

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        ZStack {
                            AnimatedRing(progress: health.snapshot.calorieProgress, color: AppColors.orange, lineWidth: 8, size: 72)
                            VStack(spacing: 0) {
                                Text("\(Int(health.snapshot.loggedCalories))").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                Text("kcal").font(.system(size: 9)).foregroundColor(AppColors.textTertiary)
                            }
                        }
                        Text("Calories").font(.system(size: 10)).foregroundColor(AppColors.textSecondary)
                    }

                    VStack(spacing: 10) {
                        MacroBar(label: "Protein", grams: health.snapshot.loggedProteinG,
                                 target: health.snapshot.targetProteinG, color: AppColors.blue)
                        MacroBar(label: "Carbs", grams: health.snapshot.loggedCarbsG,
                                 target: health.snapshot.targetCarbsG, color: AppColors.yellow)
                        MacroBar(label: "Fat", grams: health.snapshot.loggedFatG,
                                 target: health.snapshot.targetFatG, color: AppColors.orange)
                    }
                    .frame(maxWidth: .infinity)
                }

                if health.snapshot.loggedCalories == 0 {
                    Text("No nutrition logged yet today. Log food in MyFitnessPal, Cronometer, or Lose It and it will appear here.")
                        .font(.caption2).foregroundColor(AppColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Weekly Steps Chart
    var weeklyStepsChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Steps — Last 7 Days").font(.subheadline).bold().foregroundColor(.white)
                    Spacer()
                    Text("Goal: \(currentPhase.stepsTarget.formatted())")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                }

                let maxVal = max(health.weeklySteps.max() ?? 1, Double(currentPhase.stepsTarget))
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let val   = health.weeklySteps[i]
                        let ratio = CGFloat(val / maxVal)
                        let day   = Calendar.current.date(byAdding: .day, value: i - 6, to: .now)!
                        let label = Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: day) - 1]
                        let isToday = Calendar.current.isDateInToday(day)
                        let metGoal = val >= Double(currentPhase.stepsTarget)

                        VStack(spacing: 3) {
                            Text(val > 0 ? "\(Int(val / 1000))k" : "")
                                .font(.system(size: 8)).foregroundColor(AppColors.textTertiary)
                            GeometryReader { g in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(metGoal ? AppColors.green : (isToday ? AppColors.blue : AppColors.cardSurface))
                                        .frame(height: max(4, g.size.height * ratio))
                                }
                            }
                            Text(label).font(.system(size: 9)).foregroundColor(isToday ? AppColors.green : AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
            }
        }
    }

    // MARK: - Phase Card
    var phaseCard: some View {
        GlassCard(tint: Color(hex: currentPhase.colorHex)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(currentPhase.number): \(currentPhase.label)")
                        .font(.headline).bold().foregroundColor(Color(hex: currentPhase.colorHex))
                    Text(currentPhase.weeks).font(.caption).foregroundColor(AppColors.textSecondary)
                    Text(currentPhase.description).font(.caption).foregroundColor(AppColors.textSecondary)
                        .padding(.top, 2)
                }
                Spacer()
                VStack(spacing: 6) {
                    PhaseStatBadge(value: "\(currentPhase.workoutsPerWeek)x", label: "workouts", color: Color(hex: currentPhase.colorHex))
                    PhaseStatBadge(value: "\(currentPhase.cardioMinutes)m", label: "cardio", color: Color(hex: currentPhase.colorHex))
                    PhaseStatBadge(value: "\(currentPhase.targetCalories)", label: "cal/day", color: Color(hex: currentPhase.colorHex))
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MacroBar: View {
    let label: String
    let grams: Double
    let target: Double
    let color: Color

    var progress: Double { target > 0 ? min(grams / target, 1.0) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 10)).foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(Int(grams))g / \(Int(target))g").font(.system(size: 10)).foregroundColor(AppColors.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.cardSurface).frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}

struct MetricTile: View {
    let icon: String
    let value: String
    let label: String
    let sub: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(icon).font(.title3)
                Text(value)
                    .font(.title3).bold().foregroundColor(.white)
                    .minimumScaleFactor(0.7).lineLimit(1)
                Text(label).font(.caption2).foregroundColor(AppColors.textSecondary)
                Text(sub).font(.system(size: 9)).foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PhaseStatBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(value).font(.caption).bold().foregroundColor(color)
            Text(label).font(.system(size: 8)).foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

