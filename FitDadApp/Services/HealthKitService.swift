import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    private let store = HKHealthStore()
    @Published var snapshot = HealthSnapshot()
    @Published var authorized = false
    @Published var weeklySteps: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyHR: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklyActiveCalories: [Double] = Array(repeating: 0, count: 7)
    @Published var weeklySleepHours: [Double] = Array(repeating: 0, count: 7)

    // Nutrition history — MFP / Cronometer / Lose It all write to these HealthKit fields
    @Published var weeklyNutrition: [DailyNutritionEntry] = []
    @Published var nutritionDataAvailable: Bool = false

    private var refreshTask: Task<Void, Never>?

    // Types we want to read
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        let ids: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .basalEnergyBurned,
            .restingHeartRate, .heartRateVariabilitySDNN,
            .bodyMass, .height, .bodyMassIndex, .bodyFatPercentage,
            .heartRate, .walkingHeartRateAverage,
            // Nutrition — written by MyFitnessPal, Cronometer, Lose It, etc.
            .dietaryEnergyConsumed, .dietaryProtein,
            .dietaryCarbohydrates, .dietaryFatTotal, .dietaryWater
        ]
        for id in ids {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    func requestAuthorization() {
        #if targetEnvironment(macCatalyst)
        return
        #else
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.authorized = success
                if success { self?.startRefreshing() }
            }
        }
        #endif
    }

    func startRefreshing() {
        refreshTask?.cancel()
        refreshTask = Task {
            await fetchAll()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                await fetchAll()
            }
        }
    }

    func fetchAll() async {
        async let steps      = fetchTodaySteps()
        async let active     = fetchTodayActiveCalories()
        async let basal      = fetchTodayBasalCalories()
        async let rhr        = fetchRestingHR()
        async let weight     = fetchLatestWeight()
        async let sleep      = fetchLastNightSleep()
        async let hrv        = fetchHRV()
        async let wSteps     = fetchWeeklySteps()
        async let wHR        = fetchWeeklyRestingHR()
        async let wActive    = fetchWeeklyActiveCalories()
        async let wSleep     = fetchWeeklySleep()
        // Nutrition
        async let todayCal   = fetchTodayNutrient(.dietaryEnergyConsumed, unit: .kilocalorie())
        async let todayProt  = fetchTodayNutrient(.dietaryProtein,        unit: .gram())
        async let todayCarb  = fetchTodayNutrient(.dietaryCarbohydrates,  unit: .gram())
        async let todayFat   = fetchTodayNutrient(.dietaryFatTotal,       unit: .gram())
        async let todayWater = fetchTodayNutrient(.dietaryWater,          unit: .literUnit(with: .milli))
        async let nutSource  = fetchNutritionSource()
        async let wNutr      = fetchWeeklyNutrition()

        let (s, ac, bc, r, w, sl, h, ws, whr, wac, wsl,
             tcal, tprot, tcarb, tfat, twater, nsrc, wn) =
            await (steps, active, basal, rhr, weight, sleep, hrv, wSteps, wHR, wActive, wSleep,
                   todayCal, todayProt, todayCarb, todayFat, todayWater, nutSource, wNutr)

        snapshot.dailySteps            = s
        snapshot.activeCalories        = ac
        snapshot.basalCalories         = bc
        snapshot.restingHR             = r
        snapshot.latestWeightLbs       = w
        snapshot.sleepHours            = sl
        snapshot.heartRateVariability  = h
        snapshot.loggedCalories        = tcal
        snapshot.loggedProteinG        = tprot
        snapshot.loggedCarbsG          = tcarb
        snapshot.loggedFatG            = tfat
        snapshot.loggedWaterML         = twater
        snapshot.nutritionSource       = nsrc
        weeklySteps                    = ws
        weeklyHR                       = whr
        weeklyActiveCalories           = wac
        weeklySleepHours               = wsl
        weeklyNutrition                = wn
        nutritionDataAvailable         = tcal > 0
    }

    // MARK: - Today queries

    private func fetchTodaySteps() async -> Double {
        await fetchSum(.stepCount, unit: .count(), startDate: Calendar.current.startOfDay(for: .now))
    }
    private func fetchTodayActiveCalories() async -> Double {
        await fetchSum(.activeEnergyBurned, unit: .kilocalorie(), startDate: Calendar.current.startOfDay(for: .now))
    }
    private func fetchTodayBasalCalories() async -> Double {
        await fetchSum(.basalEnergyBurned, unit: .kilocalorie(), startDate: Calendar.current.startOfDay(for: .now))
    }
    private func fetchRestingHR() async -> Double {
        await fetchMostRecent(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }
    private func fetchLatestWeight() async -> Double {
        let kg = await fetchMostRecent(.bodyMass, unit: .gramUnit(with: .kilo))
        return kg * 2.20462
    }
    private func fetchHRV() async -> Double {
        await fetchMostRecent(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
    }

    // MARK: - Nutrition today

    private func fetchTodayNutrient(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        await fetchSum(id, unit: unit, startDate: Calendar.current.startOfDay(for: .now))
    }

    /// Detects which app last wrote nutrition data (bundle ID of the source)
    private func fetchNutritionSource() async -> String {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return "Not logged yet" }
        let start = Calendar.current.startOfDay(for: .now)
        let pred  = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let sort  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first else { cont.resume(returning: "Not logged yet"); return }
                let bundle = sample.sourceRevision.source.bundleIdentifier
                // Map known bundle IDs to friendly names
                let name: String
                switch bundle {
                case let b where b.contains("myfitnesspal"):  name = "MyFitnessPal"
                case let b where b.contains("cronometer"):    name = "Cronometer"
                case let b where b.contains("loseit"):        name = "Lose It!"
                case let b where b.contains("noom"):          name = "Noom"
                case let b where b.contains("carbs"):         name = "Carbs & Cals"
                case let b where b.contains("apple"):         name = "Apple Health"
                case let b where b.contains("lifesum"):       name = "Lifesum"
                case let b where b.contains("yazio"):         name = "YAZIO"
                default:                                       name = bundle.components(separatedBy: ".").last?.capitalized ?? "Food App"
                }
                cont.resume(returning: name)
            }
            store.execute(q)
        }
    }

    // MARK: - Weekly nutrition history (last 7 days)

    func fetchWeeklyNutrition() async -> [DailyNutritionEntry] {
        var entries: [DailyNutritionEntry] = []
        let cal = Calendar.current
        for dayOffset in (0..<7).reversed() {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: .now)),
                  let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            async let cal_   = fetchSum(.dietaryEnergyConsumed, unit: .kilocalorie(),  startDate: dayStart, endDate: dayEnd)
            async let prot   = fetchSum(.dietaryProtein,        unit: .gram(),          startDate: dayStart, endDate: dayEnd)
            async let carb   = fetchSum(.dietaryCarbohydrates,  unit: .gram(),          startDate: dayStart, endDate: dayEnd)
            async let fat    = fetchSum(.dietaryFatTotal,       unit: .gram(),          startDate: dayStart, endDate: dayEnd)
            let (c, p, cb, f) = await (cal_, prot, carb, fat)

            entries.append(DailyNutritionEntry(date: dayStart, calories: c, proteinG: p, carbsG: cb, fatG: f))
        }
        return entries
    }

    // MARK: - Weekly activity

    private func fetchWeeklySteps() async -> [Double] {
        await fetchDailyStats(.stepCount, unit: .count(), stats: .cumulativeSum, days: 7)
    }
    private func fetchWeeklyRestingHR() async -> [Double] {
        await fetchDailyStats(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), stats: .discreteAverage, days: 7)
    }
    private func fetchWeeklyActiveCalories() async -> [Double] {
        await fetchDailyStats(.activeEnergyBurned, unit: .kilocalorie(), stats: .cumulativeSum, days: 7)
    }
    private func fetchWeeklySleep() async -> [Double] {
        var results = [Double]()
        let cal = Calendar.current
        for dayOffset in (0..<7).reversed() {
            guard let dayStart = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: .now)),
                  let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) else {
                results.append(0); continue
            }
            results.append(await fetchSleepForRange(start: dayStart, end: dayEnd))
        }
        return results
    }

    private func fetchLastNightSleep() async -> Double {
        let end   = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -14, to: end)!
        return await fetchSleepForRange(start: start, end: end)
    }

    private func fetchSleepForRange(start: Date, end: Date) async -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: sleepType, predicate: pred, limit: 200, sortDescriptors: nil) { _, samples, _ in
                var total: TimeInterval = 0
                for s in (samples ?? []) {
                    if let cat = s as? HKCategorySample,
                       cat.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       cat.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       cat.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       cat.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        total += cat.endDate.timeIntervalSince(cat.startDate)
                    }
                }
                cont.resume(returning: total / 3600)
            }
            store.execute(q)
        }
    }

    // MARK: - Generic helpers

    private func fetchSum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, startDate: Date, endDate: Date = .now) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let pred = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    private func fetchMostRecent(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let s = samples?.first as? HKQuantitySample {
                    cont.resume(returning: s.quantity.doubleValue(for: unit))
                } else { cont.resume(returning: 0) }
            }
            store.execute(q)
        }
    }

    private func fetchDailyStats(_ id: HKQuantityTypeIdentifier, unit: HKUnit,
                                  stats: HKStatisticsOptions, days: Int) async -> [Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return Array(repeating: 0, count: days) }
        let cal   = Calendar.current
        let end   = cal.startOfDay(for: .now).addingTimeInterval(86400)
        let start = cal.date(byAdding: .day, value: -days, to: end)!
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsCollectionQuery(
                quantityType: type, quantitySamplePredicate: pred,
                options: stats, anchorDate: start, intervalComponents: interval)
            q.initialResultsHandler = { _, collection, _ in
                var results = [Double]()
                collection?.enumerateStatistics(from: start, to: end) { stat, _ in
                    if stats == .cumulativeSum {
                        results.append(stat.sumQuantity()?.doubleValue(for: unit) ?? 0)
                    } else {
                        results.append(stat.averageQuantity()?.doubleValue(for: unit) ?? 0)
                    }
                }
                while results.count > days { results.removeFirst() }
                while results.count < days { results.insert(0, at: 0) }
                cont.resume(returning: results)
            }
            store.execute(q)
        }
    }
}
