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
        // Named store — changing the name forces a fresh DB when schema is incompatible
        let config = ModelConfiguration("FitDadV2", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback: delete the store file and recreate
            let base = config.url.path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: base + suffix)
            }
            // If still failing, run in-memory so app doesn't crash
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [memConfig]))
                ?? { fatalError("SwiftData init failed: \(error)") }()
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
