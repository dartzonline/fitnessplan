import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var health: HealthKitService
    @Query var profiles: [UserProfile]
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            WorkoutsView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }
                .tag(1)

            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
                .tag(2)

            HabitsView()
                .tabItem { Label("Habits", systemImage: "checkmark.circle.fill") }
                .tag(3)

            ProgressView_()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(4)

            AICoachView()
                .tabItem { Label("AI Coach", systemImage: "sparkles") }
                .tag(5)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(6)
        }
        .tint(AppColors.green)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showOnboarding) {
            PlanSetupView()
        }
        .onAppear {
            updateHealthTargets()
            if profiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                }
            }
        }
        .onChange(of: profiles.count) { _, _ in updateHealthTargets() }
    }

    private func updateHealthTargets() {
        guard let p = profile else { return }
        health.snapshot.targetCalories = p.dailyCalorieTarget
        health.snapshot.targetProteinG = p.dailyProteinTarget
        health.snapshot.targetCarbsG   = p.dailyCarbTarget
        health.snapshot.targetFatG     = p.dailyFatTarget
    }
}
