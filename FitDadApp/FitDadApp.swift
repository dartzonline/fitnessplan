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
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed — delete the old store and start fresh
            let storeURL = config.url
            let base = storeURL.path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: base + suffix)
            }
            return try! ModelContainer(for: schema, configurations: [config])
        }
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
