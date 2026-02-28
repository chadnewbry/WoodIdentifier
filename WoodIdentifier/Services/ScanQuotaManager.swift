import Foundation

/// Tracks daily free scan quota (3 scans/day) persisted in UserDefaults.
final class ScanQuotaManager {
    static let shared = ScanQuotaManager()

    private let maxDailyScans = 3
    private let defaults = UserDefaults.standard
    private let countKey = "scanCount"
    private let dateKey = "scanDate"

    init() {
        resetIfNewDay()
    }

    /// Whether the user can perform another scan today.
    var canScan: Bool {
        resetIfNewDay()
        return defaults.integer(forKey: countKey) < maxDailyScans
    }

    /// Number of scans remaining today.
    var scansRemaining: Int {
        resetIfNewDay()
        return max(0, maxDailyScans - defaults.integer(forKey: countKey))
    }

    /// Record that a scan was used.
    func recordScan() {
        resetIfNewDay()
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
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
