import SwiftUI
import UIKit

final class PDFShareService {
    static let shared = PDFShareService()

    private init() {}

    func writePDF(data: Data, invoiceNumber: String, temporary: Bool) throws -> URL {
        let cleanNumber = sanitize(invoiceNumber.isEmpty ? "invoice" : invoiceNumber)
        let fileName = "Throttleart_Invoice_\(cleanNumber).pdf"

        let directory: URL
        if temporary {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("ThrottleartInvoicePreview", isDirectory: true)
        } else {
            directory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("ThrottleartInvoices", isDirectory: true)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func sanitize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "#", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
