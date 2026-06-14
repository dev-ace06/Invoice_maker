import Foundation

final class DateFormatterService {
    static let shared = DateFormatterService()

    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private init() {}

    func parseInvoiceDate(_ rawValue: String) -> (date: Date?, display: String, isValid: Bool) {
        let raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return (nil, "Invalid date", false)
        }

        let parts = raw.split { character in
            character == "/" || character == "-" || character == "."
        }.map(String.init)

        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let year = Int(parts[2]),
              year >= 1900,
              year <= 2200 else {
            return (nil, raw, false)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.day = day
        components.month = month
        components.year = year

        guard let date = components.date else {
            return (nil, raw, false)
        }

        let checked = calendar.dateComponents([.day, .month, .year], from: date)
        let valid = checked.day == day && checked.month == month && checked.year == year
        return valid ? (date, displayFormatter.string(from: date), true) : (nil, raw, false)
    }

    func display(_ date: Date?) -> String {
        guard let date else { return "" }
        return displayFormatter.string(from: date)
    }

    func addYears(_ years: Int, to date: Date?) -> Date? {
        guard let date, years > 0 else { return nil }
        return Calendar(identifier: .gregorian).date(byAdding: .year, value: years, to: date)
    }
}
