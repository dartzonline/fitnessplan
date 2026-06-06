import SwiftUI
import SwiftData

// MARK: - Plan Setup / Onboarding
struct PlanSetupView: View {
    @Environment(\.modelContext) var ctx
    @Environment(\.dismiss) var dismiss
    @Query var profiles: [UserProfile]

    var profile: UserProfile? { profiles.first }

    @State private var currentWeightText = ""
    @State private var goalWeightText = ""
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var age = 30
    @State private var activityLevel = "moderate"
    @State private var goalPace = "moderate"
    @State private var weeklyWorkoutDays = 4
    @State private var planName = "My Plan"
    @State private var startDate = Date()
    @State private var page = 0

    private let activityOptions: [(String, String, String)] = [
        ("sedentary",   "Desk job, little movement",        "🪑"),
        ("light",       "Light walks, 1–2 workouts/wk",     "🚶"),
        ("moderate",    "3–4 workouts/wk, active job",      "🏃"),
        ("active",      "5+ workouts/wk, physical job",     "💪"),
        ("very_active", "Athlete or very physical work",    "🔥"),
    ]
    private let paceOptions: [(String, String, String)] = [
        ("conservative", "~0.5 lb/week — slow & steady",  "🐢"),
        ("moderate",     "~1.0 lb/week — balanced",       "⚖️"),
        ("aggressive",   "~1.5 lb/week — push harder",    "⚡"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    progressBar
                    TabView(selection: $page) {
                        welcomePage.tag(0)
                        bodyStatsPage.tag(1)
                        activityPage.tag(2)
                        goalPage.tag(3)
                        summaryPage.tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: page)
                }
            }
            .navigationTitle(page == 0 ? "Set Up Your Plan" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if profile != nil {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .onAppear { loadExisting() }
    }

    // MARK: - Progress Bar
    var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i <= page ? AppColors.green : AppColors.cardSurface)
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Page 0: Welcome
    var welcomePage: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.green.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "figure.run")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.green)
                    }
                    Text("Build Your Plan")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Personalized targets based on your body, goals, and lifestyle — powered by your actual Health data.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    TextField("Plan name (e.g. Summer Cut)", text: $planName)
                        .textFieldStyle(FitTextFieldStyle())
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                        .tint(AppColors.green)
                }
                .padding(.horizontal, 24)

                nextButton(label: "Get Started", icon: "arrow.right")
                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Page 1: Body Stats
    var bodyStatsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                pageHeader(icon: "scalemass", title: "Body Stats", subtitle: "Used to calculate your calorie targets")

                VStack(spacing: 14) {
                    SetupField(label: "Current Weight (lbs)", value: $currentWeightText, keyboard: .decimalPad, placeholder: "e.g. 215")
                    SetupField(label: "Goal Weight (lbs)", value: $goalWeightText, keyboard: .decimalPad, placeholder: "e.g. 190")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height").font(.caption).foregroundColor(AppColors.textSecondary).padding(.leading, 4)
                        HStack(spacing: 10) {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { Text("\($0) ft").tag($0) }
                            }
                            .pickerStyle(.wheel).frame(height: 100)
                            .background(AppColors.cardBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                            }
                            .pickerStyle(.wheel).frame(height: 100)
                            .background(AppColors.cardBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age").font(.caption).foregroundColor(AppColors.textSecondary).padding(.leading, 4)
                        Stepper("\(age) years old", value: $age, in: 16...80)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    backButton
                    nextButton(label: "Next", icon: "arrow.right")
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Page 2: Activity Level
    var activityPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                pageHeader(icon: "bolt.heart", title: "Activity Level", subtitle: "How active are you on a typical day?")

                VStack(spacing: 8) {
                    ForEach(activityOptions, id: \.0) { key, desc, icon in
                        Button { activityLevel = key } label: {
                            HStack(spacing: 12) {
                                Text(icon).font(.title2).frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                                        .font(.subheadline).bold().foregroundColor(.white)
                                    Text(desc).font(.caption).foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if activityLevel == key {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.green)
                                }
                            }
                            .padding(14)
                            .background(activityLevel == key ? AppColors.green.opacity(0.12) : AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(activityLevel == key ? AppColors.green.opacity(0.4) : Color.clear, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    backButton
                    nextButton(label: "Next", icon: "arrow.right")
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Page 3: Goal Pace
    var goalPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                pageHeader(icon: "target", title: "Loss Pace", subtitle: "How fast do you want to reach your goal?")

                VStack(spacing: 8) {
                    ForEach(paceOptions, id: \.0) { key, desc, icon in
                        Button { goalPace = key } label: {
                            HStack(spacing: 12) {
                                Text(icon).font(.title2).frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(key.capitalized)
                                        .font(.subheadline).bold().foregroundColor(.white)
                                    Text(desc).font(.caption).foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if goalPace == key {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.green)
                                }
                            }
                            .padding(14)
                            .background(goalPace == key ? AppColors.green.opacity(0.12) : AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(goalPace == key ? AppColors.green.opacity(0.4) : Color.clear, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly workout days").font(.caption).foregroundColor(AppColors.textSecondary).padding(.leading, 4)
                    Stepper("\(weeklyWorkoutDays) days/week", value: $weeklyWorkoutDays, in: 2...7)
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    backButton
                    nextButton(label: "Review Plan", icon: "arrow.right")
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Page 4: Summary
    var summaryPage: some View {
        let cw = Double(currentWeightText) ?? 0
        let gw = Double(goalWeightText) ?? 0
        let inches = Double(heightFeet * 12 + heightInches)
        let tempProfile = UserProfile(
            currentWeightLbs: cw, goalWeightLbs: gw,
            heightInches: inches, age: age,
            activityLevel: activityLevel, goalPace: goalPace,
            weeklyWorkoutDays: weeklyWorkoutDays, planStartDate: startDate,
            planName: planName
        )
        return ScrollView {
            VStack(spacing: 20) {
                pageHeader(icon: "checkmark.seal.fill", title: "Your Plan", subtitle: "Review and activate")

                GlassCard(tint: AppColors.green) {
                    VStack(spacing: 14) {
                        SummaryRow(label: "Plan Name", value: planName.isEmpty ? "My Plan" : planName)
                        SummaryRow(label: "Current Weight", value: String(format: "%.1f lbs", cw))
                        SummaryRow(label: "Goal Weight", value: String(format: "%.1f lbs", gw))
                        SummaryRow(label: "To Lose", value: String(format: "%.1f lbs", max(0, cw - gw)))
                        Divider().background(AppColors.cardSurface)
                        SummaryRow(label: "Daily Calories", value: "\(Int(tempProfile.dailyCalorieTarget)) kcal", accent: true)
                        SummaryRow(label: "Daily Protein", value: "\(Int(tempProfile.dailyProteinTarget)) g", accent: true)
                        SummaryRow(label: "Weekly Loss Target", value: "\(tempProfile.weeklyLossTarget) lbs/wk", accent: true)
                        Divider().background(AppColors.cardSurface)
                        SummaryRow(label: "Estimated Duration", value: "\(tempProfile.estimatedWeeksToGoal) weeks")
                        SummaryRow(label: "Goal Date", value: tempProfile.estimatedCompletionDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    savePlan(profile: tempProfile)
                    dismiss()
                } label: {
                    Label("Activate Plan", systemImage: "bolt.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.green)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                backButton.padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Helpers
    private func pageHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(AppColors.green)
                .padding(.top, 16)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    private func nextButton(label: String, icon: String) -> some View {
        Button {
            withAnimation { page = min(page + 1, 4) }
        } label: {
            Label(label, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.green)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var backButton: some View {
        Button {
            withAnimation { page = max(page - 1, 0) }
        } label: {
            Label("Back", systemImage: "chevron.left")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.cardBackground)
                .foregroundColor(AppColors.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func savePlan(profile: UserProfile) {
        if let existing = profiles.first {
            existing.currentWeightLbs = profile.currentWeightLbs
            existing.goalWeightLbs = profile.goalWeightLbs
            existing.heightInches = profile.heightInches
            existing.age = profile.age
            existing.activityLevel = profile.activityLevel
            existing.goalPace = profile.goalPace
            existing.weeklyWorkoutDays = profile.weeklyWorkoutDays
            existing.planStartDate = profile.planStartDate
            existing.planName = profile.planName
        } else {
            ctx.insert(profile)
        }
    }

    private func loadExisting() {
        guard let p = profiles.first else { return }
        currentWeightText = String(format: "%.1f", p.currentWeightLbs)
        goalWeightText = String(format: "%.1f", p.goalWeightLbs)
        let totalInches = Int(p.heightInches)
        heightFeet = totalInches / 12
        heightInches = totalInches % 12
        age = p.age
        activityLevel = p.activityLevel
        goalPace = p.goalPace
        weeklyWorkoutDays = p.weeklyWorkoutDays
        planName = p.planName
        startDate = p.planStartDate
    }
}

// MARK: - Setup Field
struct SetupField: View {
    let label: String
    @Binding var value: String
    var keyboard: UIKeyboardType = .default
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(AppColors.textSecondary).padding(.leading, 4)
            TextField(placeholder, text: $value)
                .keyboardType(keyboard)
                .textFieldStyle(FitTextFieldStyle())
        }
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value).font(.subheadline).bold().foregroundColor(accent ? AppColors.green : .white)
        }
    }
}

// MARK: - Text Field Style
struct FitTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.cardBackground)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardSurface, lineWidth: 1))
    }
}
