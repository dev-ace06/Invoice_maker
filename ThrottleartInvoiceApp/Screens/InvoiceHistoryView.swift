import SwiftUI
import SwiftData

struct InvoiceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Invoice> { invoice in
        invoice.isDraft == false
    }, sort: \Invoice.savedAt, order: .reverse) private var invoices: [Invoice]

    let onLoad: (Invoice) -> Void
    let onDuplicate: (Invoice) -> Void
    let onPDF: (Invoice) -> Void

    @State private var searchText = ""

    private var filteredInvoices: [Invoice] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return invoices }

        return invoices.filter { invoice in
            let itemBlob = invoice.items.flatMap { item in
                [item.productName, item.carModel, item.numberPlate, "\(item.years)-year"]
            }.joined(separator: " ")

            let searchable = [
                invoice.invoiceNumber,
                invoice.billTo,
                invoice.billAddress,
                itemBlob
            ].joined(separator: " ").lowercased()

            return searchable.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            AppCard {
                SectionHeader(
                    "Invoice History",
                    subtitle: "Offline SwiftData storage. Load/edit, duplicate, re-export, delete."
                )

                TextField("Search invoice, customer, car, plate, product...", text: $searchText)
                    .appTextFieldStyle()
            }

            if filteredInvoices.isEmpty {
                Text("No saved invoice found.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.muted)
                    .padding(.vertical, 24)
            } else {
                ForEach(filteredInvoices, id: \.id) { invoice in
                    historyCard(invoice)
                }
            }
        }
    }

    private func historyCard(_ invoice: Invoice) -> some View {
        let firstItem = invoice.items.first
        let totals = InvoiceCalculator.shared.calculate(invoice: invoice)
        let dateInfo = DateFormatterService.shared.parseInvoiceDate(invoice.invoiceDate)
        let followUp = firstItem.flatMap { DateFormatterService.shared.addYears($0.years, to: dateInfo.date) }
        let followUpText = followUp.map { DateFormatterService.shared.display($0) }

        return VStack(alignment: .leading, spacing: 8) {
            Text("\(invoice.invoiceNumber.isEmpty ? "#" : invoice.invoiceNumber) - \(invoice.billTo.isEmpty ? "Customer" : invoice.billTo)")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)

            if let firstItem {
                Text(InvoiceCalculator.shared.finalProductText(firstItem))
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.muted)
                Text(InvoiceCalculator.shared.finalSubDetail(firstItem))
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.muted)
            }

            Text("Total: \(InvoiceCalculator.shared.money(totals.total))")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.muted)

            if let followUpText {
                Text("Next follow-up: \(followUpText)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppColors.muted)
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12)))
            }

            HStack(spacing: 8) {
                Button("Load/Edit") { onLoad(invoice) }
                    .buttonStyle(HistorySoftButtonStyle())
                Button("Duplicate") { onDuplicate(invoice) }
                    .buttonStyle(HistorySoftButtonStyle())
            }
            HStack(spacing: 8) {
                Button("PDF") { onPDF(invoice) }
                    .buttonStyle(HistorySoftButtonStyle())
                Button(role: .destructive) {
                    modelContext.delete(invoice)
                    try? modelContext.save()
                } label: {
                    Text("Delete")
                }
                .buttonStyle(HistoryDangerButtonStyle())
            }
        }
        .padding(14)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.12)))
    }
}

struct HistorySoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct HistoryDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(Color.red.opacity(0.92))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.red.opacity(0.28)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
