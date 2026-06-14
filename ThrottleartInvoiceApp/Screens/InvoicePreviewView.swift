import SwiftUI
import PDFKit

struct InvoicePreviewView: View {
    @Binding var draft: InvoiceDraft
    let onSave: () -> Void
    let onDuplicate: () -> Void
    let onSharePDF: () -> Void

    @State private var pdfURL: URL?
    @State private var pdfError: String?

    private var totals: InvoiceTotals {
        InvoiceCalculator.shared.calculate(draft)
    }

    private var dateDisplay: String {
        DateFormatterService.shared.parseInvoiceDate(draft.invoiceDate).display
    }

    var body: some View {
        VStack(spacing: 14) {
            AppCard {
                SectionHeader(
                    "Invoice Summary",
                    subtitle: "Live calculations before PDF export.",
                    trailing: AnyView(datePill)
                )

                VStack(spacing: 8) {
                    summaryRow("Subtotal", totals.subtotal)
                    summaryRow("Discount", totals.discount)
                    if draft.gstEnabled {
                        summaryRow("\(draft.gstLabel1) \(cleanRate(draft.gstRate1))%", totals.gst1)
                        summaryRow("\(draft.gstLabel2) \(cleanRate(draft.gstRate2))%", totals.gst2)
                    }
                    summaryRow("Total", totals.total, isTotal: true)
                }

                HStack(spacing: 9) {
                    Button("PDF") { refreshPDFPreview(saveToDocuments: true) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Share") { onSharePDF() }
                        .buttonStyle(SoftButtonStyle())
                    Button("Duplicate") { onDuplicate() }
                        .buttonStyle(SoftButtonStyle())
                }

                Button(action: onSave) {
                    Text("Save Invoice")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("PDF button generates a native PDF. Share opens the iOS share sheet with the generated PDF file.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AppCard {
                SectionHeader("PDF Preview", subtitle: "Native PDFKit viewer")

                if let pdfURL {
                    PDFKitView(url: pdfURL)
                        .frame(height: 560)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.12)))
                } else if let pdfError {
                    Text(pdfError)
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ProgressView("Preparing PDF preview...")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
        }
        .onAppear { refreshPDFPreview(saveToDocuments: false) }
        .onChange(of: draft) { _, _ in
            refreshPDFPreview(saveToDocuments: false)
        }
    }

    private var datePill: some View {
        Text(dateDisplay)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(AppColors.muted)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12)))
    }

    private func summaryRow(_ label: String, _ value: Double, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(isTotal ? .white : AppColors.muted)
            Spacer()
            Text(InvoiceCalculator.shared.money(value))
                .font(.system(size: isTotal ? 20 : 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .font(.system(size: 13, weight: isTotal ? .black : .regular))
        .padding(.vertical, isTotal ? 10 : 8)
        .overlay(alignment: .bottom) {
            if !isTotal { Rectangle().fill(.white.opacity(0.12)).frame(height: 1) }
        }
    }

    private func refreshPDFPreview(saveToDocuments: Bool) {
        do {
            let data = InvoicePDFGenerator.shared.generatePDFData(for: draft)
            let url = try PDFShareService.shared.writePDF(
                data: data,
                invoiceNumber: draft.invoiceNumber,
                temporary: !saveToDocuments
            )
            pdfURL = url
            pdfError = nil
        } catch {
            pdfError = "Could not create preview: \(error.localizedDescription)"
        }
    }

    private func cleanRate(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(.white.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
