import SwiftUI
import SwiftData

@main
struct ThrottleartInvoiceApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Invoice.self,
            ItemPreset.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
