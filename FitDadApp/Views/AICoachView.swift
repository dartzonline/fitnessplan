import SwiftUI
import SwiftData

struct AICoachView: View {
    @EnvironmentObject var health: HealthKitService
    @StateObject private var aiService = AIService()
    @Environment(\.modelContext) var ctx
    @Query var profiles: [UserProfile]
    @Query(sort: \WeightEntry.date, order: .reverse) var weightEntries: [WeightEntry]
    @Query(sort: \WorkoutLog.date, order: .reverse) var workoutLogs: [WorkoutLog]
    @Query var habitLogs: [HabitLog]
    @Query(sort: \AIFeedbackEntry.date, order: .reverse) var feedbackHistory: [AIFeedbackEntry]

    @State private var customQuestion = ""
    @State private var showingSettings = false
    @State private var responseText: String? = nil

    private var profile: UserProfile? { profiles.first }
    private var provider: AIProvider { AIProvider(rawValue: profile?.aiProvider ?? "none") ?? .none }
    private var hasAI: Bool { provider != .none && !(profile?.aiApiKey.isEmpty ?? true) }

    private var fitnessContext: AIFitnessContext {
        let startWeight = weightEntries.last?.weightLbs ?? 0
        let currentWeight = weightEntries.first?.weightLbs ?? health.snapshot.latestWeightLbs
        let lost = max(0, startWeight - currentWeight)
        let weekNum = profile?.currentWeekNumber ?? 1
        let targetDays = profile?.weeklyWorkoutDays ?? 4

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weekWorkouts = workoutLogs.filter { $0.date >= sevenDaysAgo && $0.completed }.count

        let avgSteps = health.weeklySteps.filter { $0 > 0 }.average
        let avgSleep = health.weeklySleepHours.filter { $0 > 0 }.average
        let avgCals = health.weeklyNutrition.map { $0.calories }.filter { $0 > 0 }.average
        let calTarget = profile?.dailyCalorieTarget ?? health.snapshot.targetCalories

        let today = Calendar.current.startOfDay(for: .now)
        let todayHabits = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let habitPct = todayHabits.isEmpty ? 0 : Double(todayHabits.filter { $0.completed }.count) / Double(todayHabits.count)

        return AIFitnessContext(
            currentWeightLbs: currentWeight,
            goalWeightLbs: profile?.goalWeightLbs ?? 0,
            weightLostLbs: lost,
            weekNumber: weekNum,
            weeklyWorkoutsCompleted: weekWorkouts,
            weeklyWorkoutsTarget: targetDays,
            averageDailySteps: avgSteps,
            averageSleepHours: avgSleep,
            averageCaloriesLogged: avgCals,
            calorieTarget: calTarget,
            habitsCompletedPercent: habitPct
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if !hasAI {
                            noAICard
                        } else {
                            providerBadge
                            weeklyCheckinCard
                            askCard
                        }
                        if !feedbackHistory.isEmpty {
                            historySection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - No AI Card
    var noAICard: some View {
        GlassCard(tint: AppColors.purple) {
            VStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.purple)
                Text("AI Coach Not Configured")
                    .font(.headline).foregroundColor(.white)
                Text("Connect Gemini or Claude to get personalized weekly check-ins, nutrition tips, and answers to your fitness questions — all grounded in your real Health data.")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    showingSettings = true
                } label: {
                    Label("Set Up AI Coach", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.purple)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Provider Badge
    var providerBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: provider.icon)
                .foregroundColor(AppColors.purple)
            Text("Powered by \(provider.displayName)")
                .font(.caption).foregroundColor(AppColors.textSecondary)
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Text("Change").font(.caption).foregroundColor(AppColors.blue)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekly Check-in Card
    var weeklyCheckinCard: some View {
        GlassCard(tint: AppColors.purple) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Weekly Check-in", systemImage: "calendar.badge.checkmark")
                    .font(.headline).foregroundColor(.white)
                Text("Get feedback based on your current Health data, workouts, and habits.")
                    .font(.caption).foregroundColor(AppColors.textSecondary)

                if aiService.isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(AppColors.purple)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if let resp = responseText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resp)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Button {
                                Task { await requestCheckin() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption).foregroundColor(AppColors.purple)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = resp
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption).foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                }

                if let err = aiService.lastError {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundColor(AppColors.red)
                }

                if responseText == nil && !aiService.isLoading {
                    Button {
                        Task { await requestCheckin() }
                    } label: {
                        Label("Get Weekly Feedback", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.purple)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Ask Card
    var askCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ask a Question", systemImage: "message.fill")
                    .font(.headline).foregroundColor(.white)
                HStack(spacing: 10) {
                    TextField("e.g. How can I break my plateau?", text: $customQuestion, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(AppColors.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button {
                        Task { await askQuestion() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(customQuestion.trimmingCharacters(in: .whitespaces).isEmpty ? AppColors.cardSurface : AppColors.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(customQuestion.trimmingCharacters(in: .whitespaces).isEmpty || aiService.isLoading)
                }
            }
        }
    }

    // MARK: - History
    var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent Feedback")
            ForEach(feedbackHistory.prefix(5)) { entry in
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TagPill(text: entry.provider.capitalized, color: AppColors.purple)
                            if entry.category != "general" {
                                TagPill(text: entry.category, color: AppColors.cardSurface)
                            }
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundColor(AppColors.textTertiary)
                        }
                        if entry.category != "weekly_checkin" {
                            Text("Q: \(entry.prompt.prefix(80))...")
                                .font(.caption2).foregroundColor(AppColors.textTertiary)
                        }
                        Text(entry.response)
                            .font(.caption).foregroundColor(AppColors.textSecondary)
                            .lineLimit(5)
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func requestCheckin() async {
        guard let p = profile else { return }
        let prov = AIProvider(rawValue: p.aiProvider) ?? .none
        let result = await aiService.getFeedback(provider: prov, apiKey: p.aiApiKey, context: fitnessContext)
        responseText = result
        if let result {
            ctx.insert(AIFeedbackEntry(provider: prov.rawValue, prompt: "Weekly check-in", response: result, category: "weekly_checkin"))
        }
    }

    private func askQuestion() async {
        let q = customQuestion.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, let p = profile else { return }
        let prov = AIProvider(rawValue: p.aiProvider) ?? .none
        let result = await aiService.getFeedback(provider: prov, apiKey: p.aiApiKey, context: fitnessContext, userMessage: q)
        if let result {
            responseText = result
            ctx.insert(AIFeedbackEntry(provider: prov.rawValue, prompt: q, response: result, category: "question"))
            customQuestion = ""
        }
    }
}

// MARK: - Average helper
private extension Array where Element == Double {
    var average: Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}
