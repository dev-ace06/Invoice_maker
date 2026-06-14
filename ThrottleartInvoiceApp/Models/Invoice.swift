import Foundation
import SwiftData

struct InvoiceDraft: Codable, Equatable {
    var sourceInvoiceID: UUID? = nil
    var invoiceNumber: String = "#74"
    var invoiceDate: String = "05/05/2026"
    var billTo: String = "Vikash Patel"
    var billAddress: String = ""
    var discount: Double = 17500
    var gstEnabled: Bool = false
    var gstLabel1: String = "SGST"
    var gstRate1: Double = 9
    var gstLabel2: String = "IGST"
    var gstRate2: Double = 9
    var termsText: String = "1. Goods once sold will not be exchanged or returned.\n2. All disputes are subject to Ahmedabad jurisdiction only."
    var signatureImageData: Data? = nil
    var items: [InvoiceItem] = [.sample]

    static let empty = InvoiceDraft(items: [])

    init(
        sourceInvoiceID: UUID? = nil,
        invoiceNumber: String = "#74",
        invoiceDate: String = "05/05/2026",
        billTo: String = "Vikash Patel",
        billAddress: String = "",
        discount: Double = 17500,
        gstEnabled: Bool = false,
        gstLabel1: String = "SGST",
        gstRate1: Double = 9,
        gstLabel2: String = "IGST",
        gstRate2: Double = 9,
        termsText: String = "1. Goods once sold will not be exchanged or returned.\n2. All disputes are subject to Ahmedabad jurisdiction only.",
        signatureImageData: Data? = nil,
        items: [InvoiceItem] = [.sample]
    ) {
        self.sourceInvoiceID = sourceInvoiceID
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.billTo = billTo
        self.billAddress = billAddress
        self.discount = discount
        self.gstEnabled = gstEnabled
        self.gstLabel1 = gstLabel1
        self.gstRate1 = gstRate1
        self.gstLabel2 = gstLabel2
        self.gstRate2 = gstRate2
        self.termsText = termsText
        self.signatureImageData = signatureImageData
        self.items = items
    }

    init(invoice: Invoice) {
        self.sourceInvoiceID = invoice.id
        self.invoiceNumber = invoice.invoiceNumber
        self.invoiceDate = invoice.invoiceDate
        self.billTo = invoice.billTo
        self.billAddress = invoice.billAddress
        self.discount = invoice.discount
        self.gstEnabled = invoice.gstEnabled
        self.gstLabel1 = invoice.gstLabel1
        self.gstRate1 = invoice.gstRate1
        self.gstLabel2 = invoice.gstLabel2
        self.gstRate2 = invoice.gstRate2
        self.termsText = invoice.termsText
        self.signatureImageData = invoice.signatureImageData
        self.items = invoice.items
    }
}

@Model
final class Invoice: Identifiable {
    @Attribute(.unique) var id: UUID
    var savedAt: Date
    var invoiceNumber: String
    var invoiceDate: String
    var billTo: String
    var billAddress: String
    var discount: Double
    var gstEnabled: Bool
    var gstLabel1: String
    var gstRate1: Double
    var gstLabel2: String
    var gstRate2: Double
    var termsText: String
    @Attribute(.externalStorage) var signatureImageData: Data?
    var itemsJSON: Data
    var isDraft: Bool

    init(id: UUID = UUID(), draft: InvoiceDraft, isDraft: Bool = false) {
        self.id = id
        self.savedAt = Date()
        self.invoiceNumber = draft.invoiceNumber
        self.invoiceDate = draft.invoiceDate
        self.billTo = draft.billTo
        self.billAddress = draft.billAddress
        self.discount = draft.discount
        self.gstEnabled = draft.gstEnabled
        self.gstLabel1 = draft.gstLabel1
        self.gstRate1 = draft.gstRate1
        self.gstLabel2 = draft.gstLabel2
        self.gstRate2 = draft.gstRate2
        self.termsText = draft.termsText
        self.signatureImageData = draft.signatureImageData
        self.itemsJSON = Invoice.encodeItems(draft.items)
        self.isDraft = isDraft
    }

    var items: [InvoiceItem] {
        get { Invoice.decodeItems(itemsJSON) }
        set { itemsJSON = Invoice.encodeItems(newValue) }
    }

    func update(from draft: InvoiceDraft, markAsDraft: Bool = false) {
        savedAt = Date()
        invoiceNumber = draft.invoiceNumber
        invoiceDate = draft.invoiceDate
        billTo = draft.billTo
        billAddress = draft.billAddress
        discount = draft.discount
        gstEnabled = draft.gstEnabled
        gstLabel1 = draft.gstLabel1
        gstRate1 = draft.gstRate1
        gstLabel2 = draft.gstLabel2
        gstRate2 = draft.gstRate2
        termsText = draft.termsText
        signatureImageData = draft.signatureImageData
        items = draft.items
        isDraft = markAsDraft
    }

    private static func encodeItems(_ items: [InvoiceItem]) -> Data {
        (try? JSONEncoder().encode(items)) ?? Data()
    }

    private static func decodeItems(_ data: Data) -> [InvoiceItem] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([InvoiceItem].self, from: data)) ?? []
    }
}
