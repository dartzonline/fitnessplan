import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var health: HealthKitService
    @Environment(\.modelContext) var ctx
    @Query var profiles: [UserProfile]
    @Query(sort: \AIFeedbackEntry.date, order: .reverse) var feedbackHistory: [AIFeedbackEntry]

    @State private var showPlanSetup = false
    @State private var selectedProvider: AIProvider = .none
    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var showDeleteConfirm = false
    @State private var saveSuccess = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        planSection
                        aiSection
                        healthSection
                        historySection
                        dangerSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPlanSetup) {
                PlanSetupView()
            }
            .onAppear { loadSettings() }
        }
    }

    // MARK: - Plan Section
    var planSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your Plan")
            GlassCard {
                if let p = profile {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(p.planName).font(.headline).foregroundColor(.white)
                                Text("Started \(p.planStartDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            TagPill(text: "Active", color: AppColors.green)
                        }
                        Divider().background(AppColors.cardSurface)
                        HStack {
                            StatItem(value: String(format: "%.0f", p.currentWeightLbs), label: "Current lbs")
                            Spacer()
                            StatItem(value: String(format: "%.0f", p.goalWeightLbs), label: "Goal lbs")
                            Spacer()
                            StatItem(value: "\(p.estimatedWeeksToGoal)w", label: "Est. duration")
                            Spacer()
                            StatItem(value: "\(Int(p.dailyCalorieTarget))", label: "kcal/day")
                        }
                        Button {
                            showPlanSetup = true
                        } label: {
                            Label("Edit Plan", systemImage: "pencil")
                                .font(.subheadline).bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppColors.cardSurface)
                                .foregroundColor(AppColors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("No plan set up yet.")
                            .font(.subheadline).foregroundColor(AppColors.textSecondary)
                        Button {
                            showPlanSetup = true
                        } label: {
                            Label("Create My Plan", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.green)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI Section
    var aiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "AI Coach")
            GlassCard {
                VStack(spacing: 16) {
                    Text("Connect an AI to get personalized feedback, weekly check-ins, and answers to your fitness questions.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Provider").font(.caption).foregroundColor(AppColors.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(AIProvider.allCases, id: \.self) { p in
                                Button { selectedProvider = p } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: p.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(selectedProvider == p ? .black : AppColors.textSecondary)
                                        Text(p.displayName)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(selectedProvider == p ? .black : AppColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedProvider == p ? AppColors.green : AppColors.cardSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }

                    if selectedProvider != .none {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("API Key").font(.caption).foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Button { showAPIKey.toggle() } label: {
                                    Text(showAPIKey ? "Hide" : "Show")
                                        .font(.caption).foregroundColor(AppColors.blue)
                                }
                            }
                            HStack {
                                Group {
                                    if showAPIKey {
                                        TextField("Paste your API key...", text: $apiKey)
                                    } else {
                                        SecureField("Paste your API key...", text: $apiKey)
                                    }
                                }
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white)
                                if !apiKey.isEmpty {
                                    Button { apiKey = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(AppColors.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            providerHint
                        }
                    }

                    Button {
                        saveAISettings()
                    } label: {
                        HStack {
                            Image(systemName: saveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                            Text(saveSuccess ? "Saved!" : "Save AI Settings")
                        }
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(saveSuccess ? AppColors.green.opacity(0.2) : AppColors.green)
                        .foregroundColor(saveSuccess ? AppColors.green : .black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    @ViewBuilder
    var providerHint: some View {
        let (hint, link): (String, String) = {
            switch selectedProvider {
            case .gemini: return ("Get a free API key at Google AI Studio", "aistudio.google.com")
            case .claude: return ("Get an API key at Anthropic Console", "console.anthropic.com")
            default: return ("", "")
            }
        }()
        if !hint.isEmpty {
            Label(hint + " (\(link))", systemImage: "info.circle")
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Health Section
    var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Health App")
            GlassCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: health.authorized ? "heart.fill" : "heart.slash")
                            .foregroundColor(health.authorized ? AppColors.red : AppColors.textTertiary)
                        Text(health.authorized ? "HealthKit connected" : "HealthKit not authorized")
                            .font(.subheadline)
                            .foregroundColor(health.authorized ? .white : AppColors.textSecondary)
                        Spacer()
                        if !health.authorized {
                            Button("Connect") {
                                health.requestAuthorization()
                            }
                            .font(.subheadline).bold()
                            .foregroundColor(AppColors.green)
                        }
                    }
                    if health.authorized {
                        Button {
                            Task { await health.fetchAll() }
                        } label: {
                            Label("Refresh Health Data", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppColors.cardSurface)
                                .foregroundColor(AppColors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    Text("Steps, heart rate, sleep, active calories, and nutrition are read live from Apple Health. Nutrition data syncs from apps like MyFitnessPal, Cronometer, or Lose It.")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Feedback History
    var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "AI Feedback History")
            if feedbackHistory.isEmpty {
                GlassCard {
                    Text("No AI feedback yet. Use the AI Coach tab to get your first check-in.")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(feedbackHistory.prefix(5)) { entry in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TagPill(text: entry.provider.capitalized, color: AppColors.purple)
                                TagPill(text: entry.category, color: AppColors.cardSurface)
                                Spacer()
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundColor(AppColors.textTertiary)
                            }
                            Text(entry.response)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Danger Zone
    var dangerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Data")
            GlassCard {
                VStack(spacing: 10) {
                    if let p = profile {
                        Text("App version 1.0 · Plan: \(p.planName)")
                            .font(.caption2).foregroundColor(AppColors.textTertiary)
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.red.opacity(0.12))
                            .foregroundColor(AppColors.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .confirmationDialog("Reset all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                        Button("Reset Everything", role: .destructive) { resetAll() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will delete your profile, weight history, workout logs, and AI feedback. This cannot be undone.")
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func loadSettings() {
        guard let p = profiles.first else { return }
        selectedProvider = AIProvider(rawValue: p.aiProvider) ?? .none
        apiKey = p.aiApiKey
    }

    private func saveAISettings() {
        guard let p = profiles.first else { return }
        p.aiProvider = selectedProvider.rawValue
        p.aiApiKey = apiKey
        withAnimation { saveSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saveSuccess = false }
        }
    }

    private func resetAll() {
        profiles.forEach { ctx.delete($0) }
        feedbackHistory.forEach { ctx.delete($0) }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold().foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(AppColors.textTertiary)
        }
    }
}
