import Foundation

struct InvoiceTotals: Equatable {
    let subtotal: Double
    let discount: Double
    let taxable: Double
    let gst1: Double
    let gst2: Double
    let total: Double
    let balanceDue: Double
}

final class InvoiceCalculator {
    static let shared = InvoiceCalculator()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private init() {}

    func calculate(_ invoice: InvoiceDraft) -> InvoiceTotals {
        calculate(
            items: invoice.items,
            discount: invoice.discount,
            gstEnabled: invoice.gstEnabled,
            gstRate1: invoice.gstRate1,
            gstRate2: invoice.gstRate2
        )
    }

    func calculate(invoice: Invoice) -> InvoiceTotals {
        calculate(
            items: invoice.items,
            discount: invoice.discount,
            gstEnabled: invoice.gstEnabled,
            gstRate1: invoice.gstRate1,
            gstRate2: invoice.gstRate2
        )
    }

    func calculate(items: [InvoiceItem], discount: Double, gstEnabled: Bool, gstRate1: Double, gstRate2: Double) -> InvoiceTotals {
        let subtotal = items.reduce(0) { partial, item in
            partial + item.amount
        }
        let taxable = subtotal - discount
        let safeTaxable = max(taxable, 0)
        let gst1 = gstEnabled ? safeTaxable * (gstRate1 / 100) : 0
        let gst2 = gstEnabled ? safeTaxable * (gstRate2 / 100) : 0
        let total = taxable + gst1 + gst2

        return InvoiceTotals(
            subtotal: subtotal,
            discount: discount,
            taxable: taxable,
            gst1: gst1,
            gst2: gst2,
            total: total,
            balanceDue: total
        )
    }

    func money(_ value: Double, removeCommas: Bool = false) -> String {
        let rounded = NSNumber(value: value.rounded())
        let formatted = currencyFormatter.string(from: rounded) ?? "₹\(Int(value.rounded()))"
        return removeCommas ? formatted.replacingOccurrences(of: ",", with: "") : formatted
    }

    func finalProductText(_ item: InvoiceItem) -> String {
        let name = item.productName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty && item.years <= 0 { return "" }
        if item.years > 0 { return "\(name) (\(item.years)-year)" }
        return name
    }

    func finalSubDetail(_ item: InvoiceItem) -> String {
        let car = item.carModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let plate = item.numberPlate.trimmingCharacters(in: .whitespacesAndNewlines)

        if !car.isEmpty && !plate.isEmpty { return "\(car) (\(plate))" }
        if !car.isEmpty { return car }
        if !plate.isEmpty { return "(\(plate))" }
        return ""
    }

    func nextInvoiceNumber(_ current: String) -> String {
        let characters = Array(current)
        var endIndex: Int?
        var startIndex: Int?

        for index in stride(from: characters.count - 1, through: 0, by: -1) where characters[index].isNumber {
            endIndex = endIndex ?? index
            startIndex = index
        }

        guard let startIndex, let endIndex else {
            return current.isEmpty ? "#1" : "\(current)-copy"
        }

        let numberText = String(characters[startIndex...endIndex])
        let next = String((Int(numberText) ?? 0) + 1)
        let prefix = String(characters[..<startIndex])
        let suffix = endIndex + 1 < characters.count ? String(characters[(endIndex + 1)...]) : ""
        return prefix + next + suffix
    }

    func warnings(for invoice: InvoiceDraft) -> [String] {
        var warnings: [String] = []
        let dateInfo = DateFormatterService.shared.parseInvoiceDate(invoice.invoiceDate)
        let totals = calculate(invoice)

        if !dateInfo.isValid { warnings.append("Date format should be dd/mm/yyyy, example 05/05/2026.") }
        if invoice.invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { warnings.append("Invoice number is empty.") }
        if invoice.billTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { warnings.append("Bill To name is empty.") }
        if invoice.items.isEmpty { warnings.append("No items added.") }

        for (index, item) in invoice.items.enumerated() {
            let number = index + 1
            if item.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { warnings.append("Item \(number): Product name is empty.") }
            if item.quantity == 0 { warnings.append("Item \(number): Quantity is empty or zero.") }
            if item.rate == 0 { warnings.append("Item \(number): Rate is empty or zero.") }
            if item.carModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.numberPlate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                warnings.append("Item \(number): Car model or number plate is missing.")
            }
        }

        if invoice.discount > totals.subtotal { warnings.append("Discount is greater than subtotal.") }
        if invoice.gstEnabled && invoice.gstRate1 == 0 && invoice.gstRate2 == 0 { warnings.append("GST is enabled but both GST rates are 0%.") }

        let labels = (invoice.gstLabel1 + " " + invoice.gstLabel2).lowercased()
        if invoice.gstEnabled && labels.contains("sgst") && labels.contains("igst") {
            warnings.append("SGST and IGST are both enabled. This is allowed here, but confirm tax usage before final invoice.")
        }

        if invoice.signatureImageData == nil { warnings.append("Signature image is missing.") }
        return warnings
    }
}
