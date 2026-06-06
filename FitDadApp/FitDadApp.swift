import SwiftUI
import SwiftData

@main
struct FitDadApp: App {
    @StateObject private var healthService = HealthKitService()
    @StateObject private var notificationService = NotificationService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WeightEntry.self,
            HabitLog.self,
            WorkoutLog.self,
            UserProfile.self,
            AIFeedbackEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthService)
                .environmentObject(notificationService)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    healthService.requestAuthorization()
                    notificationService.requestPermission()
                }
        }
    }
}
