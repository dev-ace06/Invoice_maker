import Foundation

struct InvoiceItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var productName: String = ""
    var years: Int = 0
    var carModel: String = ""
    var numberPlate: String = ""
    var quantity: Double = 1
    var rate: Double = 0

    var amount: Double {
        quantity * rate
    }

    static let sample = InvoiceItem(
        productName: "VELO SHIELD PPF",
        years: 6,
        carModel: "BMW X1",
        numberPlate: "GJ18EC6643",
        quantity: 1,
        rate: 105000
    )
}
