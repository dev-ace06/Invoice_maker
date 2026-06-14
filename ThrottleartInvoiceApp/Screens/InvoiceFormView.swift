import SwiftUI
import PhotosUI
import UIKit

struct InvoiceFormView: View {
    @Binding var draft: InvoiceDraft
    let onSave: () -> Void
    @State private var signaturePickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 14) {
            AppCard {
                SectionHeader(
                    "Invoice Details",
                    subtitle: "Invoice number is auto/manual. Date input stays dd/mm/yyyy."
                )

                HStack(spacing: 10) {
                    field("Invoice No.") {
                        TextField("#74", text: $draft.invoiceNumber)
                            .appTextFieldStyle()
                    }

                    field("Date") {
                        TextField("05/05/2026", text: $draft.invoiceDate)
                            .keyboardType(.numbersAndPunctuation)
                            .appTextFieldStyle()
                    }
                }

                field("Bill To") {
                    TextField("Customer name", text: $draft.billTo)
                        .textContentType(.name)
                        .appTextFieldStyle()
                }

                field("Address Block") {
                    TextEditor(text: $draft.billAddress)
                        .frame(minHeight: 88)
                        .scrollContentBackground(.hidden)
                        .appTextFieldStyle()
                }
            }

            AppCard {
                SectionHeader(
                    "Discount & GST",
                    subtitle: "Discount is manual. GST is optional and editable."
                )

                field("Manual Discount") {
                    TextField("17500", value: $draft.discount, format: .number)
                        .keyboardType(.decimalPad)
                        .appTextFieldStyle()
                }

                Toggle(isOn: $draft.gstEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("GST Toggle")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                        Text("Default: SGST 9%, IGST 9%")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.muted)
                    }
                }
                .tint(.white)

                if draft.gstEnabled {
                    HStack(spacing: 10) {
                        field("GST Label 1") {
                            TextField("SGST", text: $draft.gstLabel1)
                                .appTextFieldStyle()
                        }
                        field("Rate %") {
                            TextField("9", value: $draft.gstRate1, format: .number)
                                .keyboardType(.decimalPad)
                                .appTextFieldStyle()
                        }
                    }

                    HStack(spacing: 10) {
                        field("GST Label 2") {
                            TextField("IGST", text: $draft.gstLabel2)
                                .appTextFieldStyle()
                        }
                        field("Rate %") {
                            TextField("9", value: $draft.gstRate2, format: .number)
                                .keyboardType(.decimalPad)
                                .appTextFieldStyle()
                        }
                    }
                }
            }

            AppCard {
                SectionHeader(
                    "Signature & Terms",
                    subtitle: "Signature image is optional. Warnings only, no hard stop."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Signature Image")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AppColors.muted)

                    PhotosPicker(selection: $signaturePickerItem, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo")
                            Text(draft.signatureImageData == nil ? "Pick Signature Image" : "Change Signature Image")
                            Spacer()
                            if draft.signatureImageData != nil {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .frame(minHeight: 48)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(.white.opacity(0.12)))
                    }

                    if let data = draft.signatureImageData, let uiImage = UIImage(data: data) {
                        HStack(spacing: 12) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 54)
                                .padding(8)
                                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Button(role: .destructive) {
                                draft.signatureImageData = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                    }
                }

                field("Terms") {
                    TextEditor(text: $draft.termsText)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .appTextFieldStyle()
                }
            }


            Button(action: onSave) {
                Text("Save Invoice")
                    .font(.system(size: 15, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.black)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .onChange(of: signaturePickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    draft.signatureImageData = data
                }
            }
        }
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
