import Foundation
import SwiftData

@MainActor
final class SwiftDataManager {
    static func seedDefaultPresetsIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<ItemPreset>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let defaults = [
            ItemPreset(name: "VELO SHIELD PPF", years: 6, rate: 105000),
            ItemPreset(name: "CERAMIC COATING", years: 3, rate: 25000),
            ItemPreset(name: "WINDOW FILM", years: 5, rate: 18000),
            ItemPreset(name: "DETAILING PACKAGE", years: 1, rate: 8000)
        ]

        defaults.forEach { context.insert($0) }
        try? context.save()
    }

    static func fetchDraft(_ context: ModelContext) -> Invoice? {
        var descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { invoice in
            invoice.isDraft == true
        })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func saveDraft(_ draft: InvoiceDraft, in context: ModelContext) {
        if let existing = fetchDraft(context) {
            existing.update(from: draft, markAsDraft: true)
        } else {
            context.insert(Invoice(draft: draft, isDraft: true))
        }
        try? context.save()
    }

    static func clearDraft(_ context: ModelContext) {
        if let draft = fetchDraft(context) {
            context.delete(draft)
            try? context.save()
        }
    }
}
