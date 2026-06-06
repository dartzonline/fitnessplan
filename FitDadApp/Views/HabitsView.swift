import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) var ctx
    @Query var allLogs: [HabitLog]

    private var todayLogs: [HabitLog] {
        allLogs.filter { Calendar.current.isDateInToday($0.date) }
    }
    private func isCompleted(_ id: Int) -> Bool {
        todayLogs.first { $0.habitID == id }?.completed ?? false
    }
    private var completedCount: Int { todayLogs.filter { $0.completed }.count }
    private var totalCount: Int { PlanData.habits.count }
    private var percentage: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ringCard
                        streakBanner
                        ForEach(PlanData.habitCategories, id: \.self) { cat in
                            habitSection(category: cat)
                        }
                        newbornNote
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Habits")
        }
    }

    var ringCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppColors.cardSurface, lineWidth: 10)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage))
                        .stroke(
                            AngularGradient(colors: [AppColors.green, Color(hex: "#22c55e")], center: .center),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6), value: percentage)
                    VStack(spacing: 0) {
                        Text("\(Int(percentage * 100))%").font(.headline).bold().foregroundColor(AppColors.green)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(completedCount == totalCount ? "🎉 Perfect Day!" : "\(totalCount - completedCount) habits left")
                        .font(.headline).foregroundColor(.white)
                    Text(Date.now, style: .date).font(.caption).foregroundColor(AppColors.textSecondary)
                    Text("\(completedCount) of \(totalCount) complete").font(.caption2).foregroundColor(AppColors.textTertiary)
                }
                Spacer()
            }
        }
    }

    var streakBanner: some View {
        GlassCard(tint: AppColors.yellow) {
            HStack {
                Text("🔥").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Streak").font(.subheadline).bold().foregroundColor(.white)
                    Text("Tap habits to track. Streaks calculated from daily logs.")
                        .font(.caption2).foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("\(currentStreak) days").font(.title2).bold().foregroundColor(AppColors.yellow)
            }
        }
    }

    private var currentStreak: Int {
        // Count consecutive days where all habits were completed
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        while true {
            let dayLogs = allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: checkDate) && $0.completed }
            if dayLogs.count == PlanData.habits.count {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return streak
    }

    func habitSection(category: String) -> some View {
        let habits = PlanData.habits.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 8) {
            Text(category.uppercased())
                .font(.caption2).bold().foregroundColor(AppColors.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 6) {
                ForEach(habits) { habit in
                    HabitRow(habit: habit, completed: isCompleted(habit.id)) {
                        toggleHabit(habit.id)
                    }
                }
            }
        }
    }

    func toggleHabit(_ id: Int) {
        let today = Calendar.current.startOfDay(for: .now)
        if let existing = allLogs.first(where: {
            $0.habitID == id && Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.completed.toggle()
        } else {
            let log = HabitLog(date: today, habitID: id, completed: true)
            ctx.insert(log)
        }
    }

    var newbornNote: some View {
        GlassCard(tint: AppColors.purple) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Newborn survival tips 👶", systemImage: "heart.fill")
                    .font(.subheadline).bold().foregroundColor(AppColors.purple)
                Text("If you only hit 4–5 habits some days, that's still a win. The 'sleep when baby sleeps' habit is the most impactful one for your fat loss — fragmented sleep spikes ghrelin (hunger hormone) and cortisol.")
                    .font(.caption).foregroundColor(AppColors.textSecondary).lineSpacing(3)
            }
        }
    }
}

struct HabitRow: View {
    let habit: HabitItem
    let completed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(completed ? Color(hex: habit.color) : Color.clear)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(completed ? Color(hex: habit.color) : AppColors.cardSurface, lineWidth: 2))
                    if completed {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                    }
                }
                .animation(.spring(response: 0.3), value: completed)

                Text(habit.icon).font(.body)

                Text(habit.title)
                    .font(.subheadline)
                    .foregroundColor(completed ? .white : AppColors.textSecondary)
                    .strikethrough(false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(completed ? Color(hex: habit.color).opacity(0.12) : AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(completed ? Color(hex: habit.color).opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
