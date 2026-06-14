import SwiftUI
import SwiftData

struct PresetItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ItemPreset.createdAt, order: .reverse) private var presets: [ItemPreset]

    @State private var presetName = ""
    @State private var presetYears: Int = 0
    @State private var presetRate: Double = 0
    @State private var editingPreset: ItemPreset?

    var body: some View {
        VStack(spacing: 12) {
            AppCard {
                SectionHeader(
                    "Item Presets",
                    subtitle: "Add/edit/delete product presets. Rows remain manually editable."
                )

                field("Product Name") {
                    TextField("VELO SHIELD PPF", text: $presetName)
                        .appTextFieldStyle()
                }

                HStack(spacing: 10) {
                    field("X-year") {
                        TextField("6", value: $presetYears, format: .number)
                            .keyboardType(.numberPad)
                            .appTextFieldStyle()
                    }
                    field("Default Rate") {
                        TextField("105000", value: $presetRate, format: .number)
                            .keyboardType(.decimalPad)
                            .appTextFieldStyle()
                    }
                }

                Button(action: addPreset) {
                    Text("Add Preset")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(.black)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if presets.isEmpty {
                Text("No presets saved.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.muted)
                    .padding(.vertical, 18)
            } else {
                ForEach(presets, id: \.id) { preset in
                    presetCard(preset)
                }
            }
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditSheet(preset: preset)
        }
    }

    private func presetCard(_ preset: ItemPreset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(preset.displayName)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
            Text("Default rate: \(InvoiceCalculator.shared.money(preset.rate))")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.muted)

            HStack(spacing: 9) {
                Button {
                    editingPreset = preset
                } label: {
                    Text("Edit")
                        .font(.system(size: 12, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.12)))
                }

                Button(role: .destructive) {
                    modelContext.delete(preset)
                    try? modelContext.save()
                } label: {
                    Text("Delete")
                        .font(.system(size: 12, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.red.opacity(0.28)))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.12)))
    }

    private func addPreset() {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(ItemPreset(name: name, years: presetYears, rate: presetRate))
        try? modelContext.save()
        presetName = ""
        presetYears = 0
        presetRate = 0
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

struct PresetEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var preset: ItemPreset

    var body: some View {
        NavigationStack {
            Form {
                Section("Preset") {
                    TextField("Product Name", text: $preset.name)
                    TextField("X-year", value: $preset.years, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Default Rate", value: $preset.rate, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
