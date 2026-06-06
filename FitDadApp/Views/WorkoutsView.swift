import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @State private var selectedDayIndex: Int = {
        // Default to today's weekday (0=Mon … 6=Sun)
        let wd = Calendar.current.component(.weekday, from: .now)
        // weekday: 1=Sun, 2=Mon … 7=Sat → map to 0=Mon…6=Sun
        return max(0, (wd + 5) % 7)
    }()
    @State private var showingLogSheet = false
    @Environment(\.modelContext) var ctx
    @Query(sort: \WorkoutLog.date, order: .reverse) var logs: [WorkoutLog]

    var todayLog: WorkoutLog? {
        logs.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Day selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<PlanData.weeklyWorkout.count, id: \.self) { i in
                                    let w = PlanData.weeklyWorkout[i]
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedDayIndex = i }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(w.shortDay)
                                                .font(.caption2).bold()
                                                .foregroundColor(selectedDayIndex == i ? .black : AppColors.textSecondary)
                                            Text(w.icon).font(.caption)
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(
                                            selectedDayIndex == i
                                            ? Color(hex: w.tagHex)
                                            : AppColors.cardBackground
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Workout detail
                        let workout = PlanData.weeklyWorkout[selectedDayIndex]
                        WorkoutDetailCard(workout: workout)
                            .padding(.horizontal, 16)

                        // Log button
                        Button {
                            showingLogSheet = true
                        } label: {
                            Label(todayLog?.completed == true ? "✅ Workout Logged!" : "Log Today's Workout",
                                  systemImage: todayLog?.completed == true ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(todayLog?.completed == true ? AppColors.green.opacity(0.2) : AppColors.green)
                                .foregroundColor(todayLog?.completed == true ? AppColors.green : .black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 16)
                        .disabled(todayLog?.completed == true)

                        // Phase progression
                        PhaseProgressionCard()
                            .padding(.horizontal, 16)

                        // Recent logs
                        if !logs.isEmpty {
                            RecentWorkoutLogs(logs: Array(logs.prefix(5)))
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Workouts")
            .sheet(isPresented: $showingLogSheet) {
                LogWorkoutSheet(workout: PlanData.weeklyWorkout[selectedDayIndex]) { duration, notes in
                    let log = WorkoutLog(workoutName: PlanData.weeklyWorkout[selectedDayIndex].day + " – " + PlanData.weeklyWorkout[selectedDayIndex].tag,
                                        durationMinutes: duration, completed: true, notes: notes)
                    ctx.insert(log)
                }
            }
        }
    }
}

struct WorkoutDetailCard: View {
    let workout: DayWorkout
    @State private var expanded = true

    var body: some View {
        GlassCard(tint: Color(hex: workout.tagHex)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(workout.icon) \(workout.day)").font(.title2).bold().foregroundColor(.white)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        TagPill(text: workout.type,    color: Color(hex: workout.tagHex))
                        TagPill(text: workout.tag,     color: AppColors.cardSurface)
                        TagPill(text: "⏱ \(workout.duration)", color: AppColors.cardSurface)
                    }
                }

                Button { withAnimation { expanded.toggle() } } label: {
                    HStack {
                        Text("Exercises").font(.subheadline).foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundColor(AppColors.textTertiary)
                    }
                }

                if expanded {
                    // Header row
                    HStack {
                        Text("Exercise").font(.caption2).foregroundColor(AppColors.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Sets").font(.caption2).foregroundColor(AppColors.textTertiary).frame(width: 36)
                        Text("Reps").font(.caption2).foregroundColor(AppColors.textTertiary).frame(width: 72)
                        Text("Rest").font(.caption2).foregroundColor(AppColors.textTertiary).frame(width: 40)
                    }
                    Divider().background(AppColors.cardSurface)

                    ForEach(workout.exercises) { ex in
                        HStack {
                            Text(ex.name).font(.caption).foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(ex.sets).font(.caption).bold().foregroundColor(Color(hex: workout.tagHex)).frame(width: 36)
                            Text(ex.reps).font(.caption).foregroundColor(AppColors.textSecondary).frame(width: 72)
                            Text(ex.rest).font(.caption).foregroundColor(AppColors.textTertiary).frame(width: 40)
                        }
                        .padding(.vertical, 3)
                        Divider().background(AppColors.cardSurface.opacity(0.5))
                    }
                }
            }
        }
    }
}

struct PhaseProgressionCard: View {
    var body: some View {
        GlassCard(tint: AppColors.orange) {
            VStack(alignment: .leading, spacing: 10) {
                Text("📈 How Workouts Scale").font(.subheadline).bold().foregroundColor(AppColors.orange)
                ForEach(PlanData.phases) { phase in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(Color(hex: phase.colorHex)).frame(width: 8, height: 8).padding(.top, 4)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Phase \(phase.number) (\(phase.weeks))").font(.caption).bold().foregroundColor(Color(hex: phase.colorHex))
                            Text("\(phase.workoutsPerWeek)x strength · \(phase.cardioMinutes) min cardio · \(phase.stepsTarget.formatted()) steps/day")
                                .font(.caption2).foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

struct RecentWorkoutLogs: View {
    let logs: [WorkoutLog]
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Workouts").font(.subheadline).bold().foregroundColor(.white)
                ForEach(logs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.workoutName).font(.caption).foregroundColor(.white)
                            Text(log.date, style: .date).font(.caption2).foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text("\(log.durationMinutes) min").font(.caption).foregroundColor(AppColors.green)
                    }
                    .padding(.vertical, 2)
                    if log.id != logs.last?.id { Divider().background(AppColors.cardSurface) }
                }
            }
        }
    }
}

struct LogWorkoutSheet: View {
    let workout: DayWorkout
    let onSave: (Int, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var duration = 45
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                Form {
                    Section("Workout") {
                        Text("\(workout.icon) \(workout.day) – \(workout.tag)")
                            .foregroundColor(.white)
                    }
                    Section("Duration (minutes)") {
                        Stepper("\(duration) min", value: $duration, in: 5...120, step: 5)
                            .foregroundColor(.white)
                    }
                    Section("Notes (optional)") {
                        TextField("How did it go?", text: $notes)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(duration, notes)
                        dismiss()
                    }.bold().foregroundColor(AppColors.green)
                }
            }
        }
    }
}
