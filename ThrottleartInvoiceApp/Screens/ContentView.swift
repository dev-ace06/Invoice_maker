import SwiftUI
import SwiftData

private enum AppTab: String, CaseIterable {
    case details = "Details"
    case items = "Items"
    case preview = "Preview"
    case history = "History"

    var icon: String {
        switch self {
        case .details: return "square.and.pencil"
        case .items: return "list.bullet.rectangle"
        case .preview: return "doc.richtext"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ItemPreset.createdAt, order: .reverse) private var presets: [ItemPreset]

    @State private var selectedTab: AppTab = .details
    @State private var draft = InvoiceDraft()
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var appMessage: String?

    private var totals: InvoiceTotals {
        InvoiceCalculator.shared.calculate(draft)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 14) {
                        WarningBanner(warnings: InvoiceCalculator.shared.warnings(for: draft))

                        switch selectedTab {
                        case .details:
                            InvoiceFormView(draft: $draft, onSave: saveInvoice)
                        case .items:
                            VStack(spacing: 14) {
                                ItemRowsView(draft: $draft, presets: presets)
                                PresetItemsView()
                            }
                        case .preview:
                            InvoicePreviewView(
                                draft: $draft,
                                onSave: saveInvoice,
                                onDuplicate: duplicateCurrentDraft,
                                onSharePDF: shareCurrentPDF
                            )
                        case .history:
                            InvoiceHistoryView(
                                onLoad: loadInvoice,
                                onDuplicate: duplicateSavedInvoice,
                                onPDF: shareSavedInvoicePDF
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 96)
                }

                bottomNav
            }
        }
        .task {
            SwiftDataManager.seedDefaultPresetsIfNeeded(modelContext)
            loadDraftIfAvailable()
        }
        .onChange(of: draft) { _, newValue in
            SwiftDataManager.saveDraft(newValue, in: modelContext)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
        .alert("Throttleart Invoice", isPresented: Binding(
            get: { appMessage != nil },
            set: { if !$0 { appMessage = nil } }
        )) {
            Button("OK", role: .cancel) { appMessage = nil }
        } message: {
            Text(appMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Throttleart Invoice")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Native SwiftUI invoice app")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Balance Due")
                    .font(.system(size: 10, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.56))
                Text(InvoiceCalculator.shared.money(totals.balanceDue, removeCommas: true))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.12)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.black.opacity(0.18))
    }

    private var bottomNav: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(selectedTab == tab ? .black : .white.opacity(0.62))
                    .background(selectedTab == tab ? .white : .clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.black.opacity(0.35))
    }

    private func loadDraftIfAvailable() {
        guard let savedDraft = SwiftDataManager.fetchDraft(modelContext) else { return }
        draft = InvoiceDraft(invoice: savedDraft)
        draft.sourceInvoiceID = nil
    }

    private func saveInvoice() {
        let record: Invoice

        if let id = draft.sourceInvoiceID, let existing = fetchInvoice(id: id) {
            existing.update(from: draft, markAsDraft: false)
            record = existing
        } else {
            record = Invoice(draft: draft, isDraft: false)
            modelContext.insert(record)
        }

        try? modelContext.save()
        draft.sourceInvoiceID = record.id
        SwiftDataManager.saveDraft(draft, in: modelContext)
        appMessage = "Invoice saved to offline history."
    }

    private func loadInvoice(_ invoice: Invoice) {
        draft = InvoiceDraft(invoice: invoice)
        selectedTab = .details
    }

    private func duplicateCurrentDraft() {
        draft.sourceInvoiceID = nil
        draft.invoiceNumber = InvoiceCalculator.shared.nextInvoiceNumber(draft.invoiceNumber)
        selectedTab = .details
    }

    private func duplicateSavedInvoice(_ invoice: Invoice) {
        var copy = InvoiceDraft(invoice: invoice)
        copy.sourceInvoiceID = nil
        copy.invoiceNumber = InvoiceCalculator.shared.nextInvoiceNumber(copy.invoiceNumber)
        let record = Invoice(draft: copy, isDraft: false)
        modelContext.insert(record)
        try? modelContext.save()
        appMessage = "Duplicate invoice saved to history."
    }

    private func shareCurrentPDF() {
        sharePDF(for: draft)
    }

    private func shareSavedInvoicePDF(_ invoice: Invoice) {
        sharePDF(for: InvoiceDraft(invoice: invoice))
    }

    private func sharePDF(for invoice: InvoiceDraft) {
        do {
            let data = InvoicePDFGenerator.shared.generatePDFData(for: invoice)
            let url = try PDFShareService.shared.writePDF(
                data: data,
                invoiceNumber: invoice.invoiceNumber,
                temporary: false
            )
            shareItems = [url]
            showShareSheet = true
        } catch {
            appMessage = "Could not create PDF: \(error.localizedDescription)"
        }
    }

    private func fetchInvoice(id: UUID) -> Invoice? {
        var descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { invoice in
            invoice.id == id && invoice.isDraft == false
        })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}

struct AppColors {
    static let background = Color(red: 0.058, green: 0.058, blue: 0.062)
    static let surface = Color.white.opacity(0.075)
    static let border = Color.white.opacity(0.12)
    static let muted = Color.white.opacity(0.62)
    static let warning = Color(red: 1.0, green: 0.82, blue: 0.48)
}

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(AppColors.border))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 14)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            trailing
        }
    }
}

struct WarningBanner: View {
    let warnings: [String]

    var body: some View {
        if !warnings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Warnings only — export is still allowed")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppColors.warning)
                ForEach(warnings, id: \.self) { warning in
                    Text("• \(warning)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.warning.opacity(0.96))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppColors.warning.opacity(0.36)))
        }
    }
}

extension View {
    func appTextFieldStyle() -> some View {
        self
            .padding(.horizontal, 13)
            .frame(minHeight: 48)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(.white.opacity(0.12)))
            .foregroundStyle(.white)
            .tint(.white)
    }
}
