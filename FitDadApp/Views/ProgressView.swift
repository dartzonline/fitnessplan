import SwiftUI
import SwiftData
import Charts

struct ProgressView_: View {
    @EnvironmentObject var health: HealthKitService
    @Environment(\.modelContext) var ctx
    @Query(sort: \WeightEntry.date) var weightEntries: [WeightEntry]
    @Query var profiles: [UserProfile]
    @State private var showingWeightSheet = false
    @State private var selectedChartTab = 0

    private var profile: UserProfile? { profiles.first }
    private var goalLbs: Double { profile?.goalWeightLossLbs ?? 20 }
    private var startWeight: Double? { weightEntries.first?.weightLbs }
    private var currentWeight: Double? { weightEntries.last?.weightLbs }
    private var lostSoFar: Double {
        guard let s = startWeight, let c = currentWeight else { return 0 }
        return s - c
    }
    private var goalWeight: Double? {
        guard let s = startWeight else { return nil }
        return profile?.goalWeightLbs ?? (s - goalLbs)
    }

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        summaryCards
                        logWeightButton
                        weightChart
                        weeklyActivityCharts
                        tdeeCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Progress")
            .sheet(isPresented: $showingWeightSheet) {
                LogWeightSheet { lbs, note in
                    let entry = WeightEntry(weightLbs: lbs, note: note)
                    ctx.insert(entry)
                }
            }
        }
    }

    // MARK: - Summary
    var summaryCards: some View {
        HStack(spacing: 10) {
            GlassCard {
                VStack(spacing: 4) {
                    Text(currentWeight.map { String(format: "%.1f", $0) } ?? "—").font(.title2).bold().foregroundColor(.white)
                    Text("lbs now").font(.caption2).foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            GlassCard {
                VStack(spacing: 4) {
                    Text(String(format: "–%.1f", lostSoFar)).font(.title2).bold().foregroundColor(AppColors.green)
                    Text("lbs lost").font(.caption2).foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            GlassCard {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", max(0, goalLbs - lostSoFar))).font(.title2).bold().foregroundColor(AppColors.orange)
                    Text("lbs to go").font(.caption2).foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Log Button
    var logWeightButton: some View {
        Button { showingWeightSheet = true } label: {
            Label("Log Today's Weight", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.green)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Weight Chart
    var weightChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Weight Trend").font(.subheadline).bold().foregroundColor(.white)
                if weightEntries.isEmpty {
                    Text("Log your starting weight to see progress here.")
                        .font(.caption).foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 20).frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(weightEntries) { entry in
                            LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.weightLbs))
                                .foregroundStyle(AppColors.green)
                            PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weightLbs))
                                .foregroundStyle(AppColors.green)
                        }
                        if let goal = goalWeight {
                            RuleMark(y: .value("Goal", goal))
                                .foregroundStyle(AppColors.orange.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .annotation(position: .trailing) {
                                    Text("Goal").font(.caption2).foregroundColor(AppColors.orange)
                                }
                        }
                    }
                    .frame(height: 160)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.month().day(), centered: true)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel().foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weekly Activity
    var weeklyActivityCharts: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 Days Activity").font(.subheadline).bold().foregroundColor(.white)

                Picker("", selection: $selectedChartTab) {
                    Text("Steps").tag(0)
                    Text("Active Cal").tag(1)
                    Text("Sleep").tag(2)
                }
                .pickerStyle(.segmented)

                let days: [String] = {
                    (0..<7).map { offset in
                        let d = Calendar.current.date(byAdding: .day, value: offset - 6, to: .now)!
                        return Calendar.current.shortWeekdaySymbols[Calendar.current.component(.weekday, from: d) - 1]
                    }
                }()

                let values: [Double] = {
                    switch selectedChartTab {
                    case 0: return health.weeklySteps
                    case 1: return health.weeklyActiveCalories
                    default: return health.weeklySleepHours
                    }
                }()

                let maxVal = max(values.max() ?? 1, 1.0)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let v = values[i]
                        let ratio = CGFloat(v / maxVal)
                        VStack(spacing: 3) {
                            Text(v > 0 ? shortLabel(v, tab: selectedChartTab) : "")
                                .font(.system(size: 8)).foregroundColor(AppColors.textTertiary)
                            GeometryReader { g in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(barColor(i, tab: selectedChartTab))
                                        .frame(height: max(4, g.size.height * ratio))
                                }
                            }
                            Text(days[i]).font(.system(size: 9))
                                .foregroundColor(i == 6 ? AppColors.green : AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 90)
            }
        }
    }

    private func shortLabel(_ v: Double, tab: Int) -> String {
        switch tab {
        case 0: return v >= 1000 ? String(format: "%.0fk", v/1000) : "\(Int(v))"
        case 1: return "\(Int(v))"
        default: return String(format: "%.1f", v)
        }
    }

    private func barColor(_ i: Int, tab: Int) -> Color {
        let colors: [Color] = [AppColors.green, AppColors.orange, AppColors.purple]
        return i == 6 ? colors[tab] : colors[tab].opacity(0.4)
    }

    // MARK: - TDEE Card
    var tdeeCard: some View {
        GlassCard(tint: AppColors.blue) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Numbers").font(.subheadline).bold().foregroundColor(AppColors.blue)
                let tdee = health.snapshot.tdee > 0 ? Int(health.snapshot.tdee) : 0
                let target = profile.map { Int($0.dailyCalorieTarget) } ?? Int(health.snapshot.targetCalories)
                let deficit = tdee > 0 ? tdee - target : 0
                VStack(spacing: 8) {
                    if tdee > 0 {
                        TDEERow(label: "Est. TDEE (today)", value: "\(tdee) kcal", color: AppColors.blue)
                    }
                    TDEERow(label: "Daily calorie target", value: "\(target) kcal", color: AppColors.green)
                    if deficit > 0 {
                        TDEERow(label: "Daily deficit", value: "~\(deficit) kcal", color: AppColors.orange)
                        TDEERow(label: "Weekly deficit", value: "~\(deficit * 7) kcal", color: AppColors.yellow)
                    }
                    if let p = profile {
                        Divider().background(AppColors.cardSurface)
                        TDEERow(label: "Target loss/week", value: "\(p.weeklyLossTarget) lbs", color: AppColors.textSecondary)
                        TDEERow(label: "Est. weeks remaining", value: "\(max(0, p.estimatedWeeksToGoal - p.currentWeekNumber + 1))", color: AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct TDEERow: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value).font(.caption).bold().foregroundColor(color)
        }
    }
}

struct LogWeightSheet: View {
    let onSave: (Double, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var weightText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack { AppColors.background.ignoresSafeArea()
                Form {
                    Section("Weight (lbs)") {
                        TextField("e.g. 185.5", text: $weightText)
                            .keyboardType(.decimalPad)
                    }
                    Section("Note (optional)") {
                        TextField("Morning weigh-in, after workout…", text: $note)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let lbs = Double(weightText) {
                            onSave(lbs, note)
                            dismiss()
                        }
                    }
                    .bold().foregroundColor(AppColors.green)
                    .disabled(Double(weightText) == nil)
                }
            }
        }
    }
}

