import SwiftUI

struct ItemRowsView: View {
    @Binding var draft: InvoiceDraft
    let presets: [ItemPreset]

    var body: some View {
        AppCard {
            SectionHeader(
                "Items",
                subtitle: "Format: Product Name (X-year), then Car Model (Number Plate).",
                trailing: AnyView(addButton)
            )

            if draft.items.isEmpty {
                Text("No items added.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }

            ForEach($draft.items) { $item in
                itemCard(item: $item)
            }
        }
    }

    private var addButton: some View {
        Button {
            draft.items.append(InvoiceItem(quantity: 1, rate: 0))
        } label: {
            Label("Add", systemImage: "plus")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func itemCard(item: Binding<InvoiceItem>) -> some View {
        let index = draft.items.firstIndex(where: { $0.id == item.wrappedValue.id }).map { $0 + 1 } ?? 1
        let dateInfo = DateFormatterService.shared.parseInvoiceDate(draft.invoiceDate)
        let followUp = DateFormatterService.shared.addYears(item.wrappedValue.years, to: dateInfo.date)
        let followUpText = dateInfo.isValid && item.wrappedValue.years > 0
            ? "Internal follow-up date: \(DateFormatterService.shared.display(followUp))"
            : "Internal follow-up appears after valid date + X-year."

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Item \(index)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                Button(role: .destructive) {
                    draft.items.removeAll { $0.id == item.wrappedValue.id }
                } label: {
                    Text("Remove")
                        .font(.system(size: 12, weight: .black))
                }
            }

            Menu {
                Button("Manual Item") {}
                Divider()
                ForEach(presets, id: \.id) { preset in
                    Button(preset.displayName) {
                        item.wrappedValue.productName = preset.name
                        item.wrappedValue.years = preset.years
                        item.wrappedValue.rate = preset.rate
                        if item.wrappedValue.quantity == 0 { item.wrappedValue.quantity = 1 }
                    }
                }
            } label: {
                HStack {
                    Text("Preset")
                    Spacer()
                    Text("Select preset / manual item")
                        .foregroundStyle(AppColors.muted)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(minHeight: 48)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(.white.opacity(0.12)))
            }

            field("Product Name") {
                TextField("VELO SHIELD PPF", text: item.productName)
                    .appTextFieldStyle()
            }

            HStack(spacing: 10) {
                field("X-year") {
                    TextField("6", value: item.years, format: .number)
                        .keyboardType(.numberPad)
                        .appTextFieldStyle()
                }
                field("Quantity") {
                    TextField("1", value: item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .appTextFieldStyle()
                }
            }

            HStack(spacing: 10) {
                field("Car Model") {
                    TextField("BMW X1", text: item.carModel)
                        .appTextFieldStyle()
                }
                field("Number Plate") {
                    TextField("GJ18EC6643", text: item.numberPlate)
                        .textInputAutocapitalization(.characters)
                        .appTextFieldStyle()
                }
            }

            field("Rate") {
                TextField("105000", value: item.rate, format: .number)
                    .keyboardType(.decimalPad)
                    .appTextFieldStyle()
            }

            HStack {
                Text("Auto Amount")
                    .foregroundStyle(AppColors.muted)
                Spacer()
                Text(InvoiceCalculator.shared.money(item.wrappedValue.amount))
                    .fontWeight(.black)
                    .foregroundStyle(.white)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))

            Text(followUpText)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.muted)
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.12)))
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AppColors.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
