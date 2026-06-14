import UIKit

final class InvoicePDFGenerator {
    static let shared = InvoicePDFGenerator()

    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4 points
    private let margin: CGFloat = 44
    private let calculator = InvoiceCalculator.shared
    private let dateService = DateFormatterService.shared

    private init() {}

    func generatePDFData(for invoice: InvoiceDraft) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "ThrottleartInvoiceApp",
            kCGPDFContextTitle as String: "Invoice \(invoice.invoiceNumber)"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        return renderer.pdfData { context in
            context.beginPage()
            drawInvoice(invoice, in: context)
        }
    }

    private func drawInvoice(_ invoice: InvoiceDraft, in context: UIGraphicsPDFRendererContext) {
        let totals = calculator.calculate(invoice)
        let dateInfo = dateService.parseInvoiceDate(invoice.invoiceDate)
        let bounds = CGRect(origin: .zero, size: pageSize)

        UIColor.white.setFill()
        UIRectFill(bounds)

        drawHeader(invoice: invoice, dateDisplay: dateInfo.display)
        var y = drawBillBlock(invoice: invoice, dateDisplay: dateInfo.display, balanceDue: totals.balanceDue)
        y += 55
        y = drawTable(invoice: invoice, startY: y, context: context)
        drawTotals(invoice: invoice, totals: totals, startY: max(y + 48, 590))
        drawTermsAndSignature(invoice: invoice)
    }

    private func drawHeader(invoice: InvoiceDraft, dateDisplay: String) {
        drawText(
            "Throttleart mods",
            in: CGRect(x: margin, y: 82, width: 230, height: 28),
            font: .systemFont(ofSize: 18, weight: .heavy),
            color: .darkText
        )

        drawText(
            "INVOICE",
            in: CGRect(x: 345, y: 70, width: 206, height: 52),
            font: .serifTitleFont(size: 38),
            color: .darkText,
            alignment: .right
        )

        drawText(
            invoice.invoiceNumber.isEmpty ? "#" : invoice.invoiceNumber,
            in: CGRect(x: 345, y: 119, width: 206, height: 24),
            font: .systemFont(ofSize: 13, weight: .semibold),
            color: .secondaryLabel,
            alignment: .right
        )
    }

    private func drawBillBlock(invoice: InvoiceDraft, dateDisplay: String, balanceDue: Double) -> CGFloat {
        let top: CGFloat = 180

        drawText(
            "Bill To: \(invoice.billTo.isEmpty ? "Customer Name" : invoice.billTo)",
            in: CGRect(x: margin, y: top, width: 230, height: 22),
            font: .systemFont(ofSize: 11, weight: .semibold),
            color: .secondaryLabel
        )

        drawText(
            invoice.billAddress,
            in: CGRect(x: margin, y: top + 25, width: 230, height: 90),
            font: .systemFont(ofSize: 11),
            color: .secondaryLabel
        )

        drawText(
            "Date:",
            in: CGRect(x: 330, y: top, width: 90, height: 18),
            font: .systemFont(ofSize: 11),
            color: .secondaryLabel
        )

        drawText(
            dateDisplay,
            in: CGRect(x: 410, y: top, width: 140, height: 18),
            font: .systemFont(ofSize: 11, weight: .medium),
            color: .darkText
        )

        let balanceRect = CGRect(x: 330, y: top + 26, width: 220, height: 30)
        UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1).setFill()
        UIBezierPath(roundedRect: balanceRect, cornerRadius: 3).fill()

        drawText(
            "Balance Due:",
            in: CGRect(x: balanceRect.minX, y: balanceRect.minY + 6, width: 130, height: 18),
            font: .systemFont(ofSize: 12, weight: .heavy),
            color: .darkText,
            alignment: .center
        )

        drawText(
            calculator.money(balanceDue, removeCommas: true),
            in: CGRect(x: balanceRect.minX + 132, y: balanceRect.minY + 6, width: 84, height: 18),
            font: .systemFont(ofSize: 12, weight: .heavy),
            color: .darkText
        )

        return top + 56
    }

    private func drawTable(invoice: InvoiceDraft, startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let tableX = margin
        let tableWidth = pageSize.width - (margin * 2)
        let itemWidth: CGFloat = tableWidth * 0.60
        let qtyWidth: CGFloat = tableWidth * 0.13
        let rateWidth: CGFloat = tableWidth * 0.14
        let amountWidth: CGFloat = tableWidth - itemWidth - qtyWidth - rateWidth
        let headerHeight: CGFloat = 31
        let rowHeight: CGFloat = 55
        var y = startY

        func drawTableHeader(at y: CGFloat) {
            let headerRect = CGRect(x: tableX, y: y, width: tableWidth, height: headerHeight)
            UIColor.darkGray.setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

            drawText("Item", in: CGRect(x: tableX + 11, y: y + 8, width: itemWidth - 18, height: 16), font: .systemFont(ofSize: 10.5, weight: .medium), color: .white)
            drawText("Quantity", in: CGRect(x: tableX + itemWidth, y: y + 8, width: qtyWidth - 8, height: 16), font: .systemFont(ofSize: 10.5, weight: .medium), color: .white, alignment: .right)
            drawText("Rate", in: CGRect(x: tableX + itemWidth + qtyWidth, y: y + 8, width: rateWidth - 8, height: 16), font: .systemFont(ofSize: 10.5, weight: .medium), color: .white, alignment: .right)
            drawText("Amount", in: CGRect(x: tableX + itemWidth + qtyWidth + rateWidth, y: y + 8, width: amountWidth - 8, height: 16), font: .systemFont(ofSize: 10.5, weight: .medium), color: .white, alignment: .right)
        }

        drawTableHeader(at: y)
        y += headerHeight

        if invoice.items.isEmpty {
            drawText(
                "No items added",
                in: CGRect(x: tableX + 11, y: y + 14, width: itemWidth - 18, height: 20),
                font: .italicSystemFont(ofSize: 10.5),
                color: .lightGray
            )
            return y + rowHeight
        }

        for item in invoice.items {
            if y + rowHeight > 610 {
                context.beginPage()
                UIColor.white.setFill()
                UIRectFill(CGRect(origin: .zero, size: pageSize))
                drawHeader(invoice: invoice, dateDisplay: DateFormatterService.shared.parseInvoiceDate(invoice.invoiceDate).display)
                drawText(
                    "Continued",
                    in: CGRect(x: margin, y: 146, width: pageSize.width - margin * 2, height: 18),
                    font: .systemFont(ofSize: 10, weight: .semibold),
                    color: .secondaryLabel
                )
                y = 180
                drawTableHeader(at: y)
                y += headerHeight
            }

            let productText = calculator.finalProductText(item).isEmpty ? "Product Name (X-year)" : calculator.finalProductText(item)
            let subText = calculator.finalSubDetail(item).isEmpty ? "Car Model (Number Plate)" : calculator.finalSubDetail(item)

            drawText(
                productText.uppercased(),
                in: CGRect(x: tableX + 11, y: y + 13, width: itemWidth - 18, height: 16),
                font: .systemFont(ofSize: 10.5, weight: .heavy),
                color: .darkText
            )

            drawText(
                subText,
                in: CGRect(x: tableX + 28, y: y + 32, width: itemWidth - 35, height: 16),
                font: .systemFont(ofSize: 10, weight: .regular),
                color: .black
            )

            drawText(
                item.quantity == 0 ? "" : String(format: "%.0f", item.quantity),
                in: CGRect(x: tableX + itemWidth, y: y + 16, width: qtyWidth - 8, height: 16),
                font: .systemFont(ofSize: 10.5),
                color: .darkText,
                alignment: .right
            )

            drawText(
                calculator.money(item.rate, removeCommas: true),
                in: CGRect(x: tableX + itemWidth + qtyWidth, y: y + 16, width: rateWidth - 8, height: 16),
                font: .systemFont(ofSize: 10.5),
                color: .darkText,
                alignment: .right
            )

            drawText(
                calculator.money(item.amount, removeCommas: true),
                in: CGRect(x: tableX + itemWidth + qtyWidth + rateWidth, y: y + 16, width: amountWidth - 8, height: 16),
                font: .systemFont(ofSize: 10.5),
                color: .darkText,
                alignment: .right
            )

            y += rowHeight
        }

        return y
    }

    private func drawTotals(invoice: InvoiceDraft, totals: InvoiceTotals, startY: CGFloat) {
        let rows: [(label: String, value: String, grand: Bool)] = {
            var result: [(String, String, Bool)] = [
                ("Subtotal:", calculator.money(totals.subtotal, removeCommas: true), false),
                ("Discount:", calculator.money(totals.discount, removeCommas: true), false)
            ]

            if invoice.gstEnabled {
                result.append(("\(invoice.gstLabel1) \(cleanRate(invoice.gstRate1))%:", calculator.money(totals.gst1, removeCommas: true), false))
                result.append(("\(invoice.gstLabel2) \(cleanRate(invoice.gstRate2))%:", calculator.money(totals.gst2, removeCommas: true), false))
            }

            result.append(("Total:", calculator.money(totals.total, removeCommas: true), true))
            return result
        }()

        let x = pageSize.width - margin - 210
        var y = startY
        for row in rows {
            drawText(
                row.label,
                in: CGRect(x: x, y: y, width: 100, height: 18),
                font: .systemFont(ofSize: row.grand ? 11.5 : 10.5, weight: row.grand ? .heavy : .regular),
                color: row.grand ? .darkText : .secondaryLabel,
                alignment: .right
            )
            drawText(
                row.value,
                in: CGRect(x: x + 112, y: y, width: 98, height: 18),
                font: .systemFont(ofSize: row.grand ? 11.5 : 10.5, weight: row.grand ? .heavy : .medium),
                color: .darkText,
                alignment: .right
            )
            y += 20
        }
    }

    private func drawTermsAndSignature(invoice: InvoiceDraft) {
        let y: CGFloat = 720
        drawText(
            "Terms:",
            in: CGRect(x: margin, y: y, width: 240, height: 16),
            font: .systemFont(ofSize: 10, weight: .regular),
            color: .secondaryLabel
        )
        drawText(
            invoice.termsText,
            in: CGRect(x: margin, y: y + 18, width: 265, height: 70),
            font: .systemFont(ofSize: 9.5),
            color: .darkGray
        )

        let signatureBox = CGRect(x: pageSize.width - margin - 170, y: y - 10, width: 170, height: 92)
        if let data = invoice.signatureImageData, let image = UIImage(data: data) {
            image.drawAspectFit(in: CGRect(x: signatureBox.minX + 25, y: signatureBox.minY, width: 120, height: 52))
        }
        drawText(
            "SIGNATURE",
            in: CGRect(x: signatureBox.minX, y: signatureBox.maxY - 28, width: signatureBox.width, height: 18),
            font: .systemFont(ofSize: 10),
            color: .secondaryLabel,
            alignment: .center
        )
    }

    private func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]

        text.draw(in: rect, withAttributes: attributes)
    }

    private func cleanRate(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

private extension UIFont {
    static func serifTitleFont(size: CGFloat) -> UIFont {
        UIFont(name: "Georgia", size: size) ?? .serifFallback(size: size)
    }

    static func serifFallback(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .regular)
    }
}

private extension UIImage {
    func drawAspectFit(in rect: CGRect) {
        let imageRatio = size.width / size.height
        let rectRatio = rect.width / rect.height
        let drawRect: CGRect

        if imageRatio > rectRatio {
            let height = rect.width / imageRatio
            drawRect = CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
        } else {
            let width = rect.height * imageRatio
            drawRect = CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height)
        }

        draw(in: drawRect)
    }
}
