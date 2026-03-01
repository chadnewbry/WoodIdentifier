import Foundation

/// Tracks daily free scan quota (3 scans/day) persisted in UserDefaults.
/// Pro users bypass all limits.
final class ScanQuotaManager: ObservableObject {
    static let shared = ScanQuotaManager()

    private let maxDailyScans = 3
    private let defaults = UserDefaults.standard
    private let countKey = "scanCount"
    private let dateKey = "scanDate"
    private let totalScansKey = "totalScanCount"

    init() {
        resetIfNewDay()
    }

    /// Whether the user can perform another scan today.
    var canScan: Bool {
        if SubscriptionManager.shared.isProUser { return true }
        resetIfNewDay()
        return defaults.integer(forKey: countKey) < maxDailyScans
    }

    /// Number of scans remaining today (returns Int.max for pro users).
    var scansRemaining: Int {
        if SubscriptionManager.shared.isProUser { return .max }
        resetIfNewDay()
        return max(0, maxDailyScans - defaults.integer(forKey: countKey))
    }

    /// Total scans ever performed (for review prompt logic).
    var totalScans: Int {
        defaults.integer(forKey: totalScansKey)
    }

    /// Record that a scan was used.
    func recordScan() {
        resetIfNewDay()
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
        defaults.set(defaults.integer(forKey: totalScansKey) + 1, forKey: totalScansKey)
    }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: dateKey) as? Date ?? .distantPast
        let storedDay = Calendar.current.startOfDay(for: stored)

        if today > storedDay {
            defaults.set(0, forKey: countKey)
            defaults.set(today, forKey: dateKey)
        }
    }
}
