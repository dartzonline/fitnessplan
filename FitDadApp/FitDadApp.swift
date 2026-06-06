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

        // Proactively wipe any previous store files to avoid migration crashes
        func nukeStore(named name: String) {
            guard let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let base = appSupport.appendingPathComponent("\(name).store").path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: base + suffix)
            }
        }

        // Try persistent store first
        let config = ModelConfiguration("FitDadV3", schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Persistent failed — nuke and retry
        nukeStore(named: "FitDadV3")
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Last resort: in-memory (data won't persist between launches but app won't crash)
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memConfig])
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
