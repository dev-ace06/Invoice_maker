import Foundation
import SwiftData

@Model
final class ItemPreset: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var years: Int
    var rate: Double
    var createdAt: Date

    init(id: UUID = UUID(), name: String, years: Int, rate: Double, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.years = years
        self.rate = rate
        self.createdAt = createdAt
    }

    var displayName: String {
        years > 0 ? "\(name) (\(years)-year)" : name
    }
}
