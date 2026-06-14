# ThrottleartInvoiceApp — Native iOS SwiftUI Code

This is the native iOS version of the Throttleart mobile invoice prototype.

## Tech used

- UI: SwiftUI
- PDF generation: `UIGraphicsPDFRenderer` + CoreGraphics/UIKit drawing
- PDF preview: PDFKit
- Offline storage: SwiftData, which was one of the approved options alongside CoreData
- PDF export/share: `UIActivityViewController`
- Signature image: PhotosUI
- Local PDF files: FileManager
- Date formatting: DateFormatter
- Currency formatting: NumberFormatter

## Features kept from the web prototype

- Fixed brand: `Throttleart mods`
- Manual invoice number
- Date input as `dd/mm/yyyy`, rendered as `May 5, 2026`
- Bill To + address block
- Multiple invoice items
- Item format: `Product Name (X-year)`
- Sub-detail format: `Car Model (Number Plate)`
- Internal follow-up date from invoice date + X-year
- Item presets: add, edit, delete, apply to row
- Manual discount
- GST toggle with editable labels/rates, default SGST 9% and IGST 9%
- Warnings only, no hard stop
- Signature image from gallery
- Terms text
- Live summary
- Native PDF preview
- Save invoice history offline
- Load/edit saved invoice
- Duplicate invoice
- Delete invoice
- Export/share generated PDF

## How to use in Xcode

1. Open Xcode.
2. Create a new project:
   - App
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None or SwiftData. If Xcode asks, SwiftData is fine.
   - Minimum deployment target: iOS 17.0+
3. Name it `ThrottleartInvoiceApp`.
4. Delete the default `ContentView.swift` and default app file.
5. Copy the `ThrottleartInvoiceApp` folder from this zip into your Xcode project.
6. Make sure all `.swift` files are included in the app target.
7. Add this to `Info.plist` because PhotosUI is used:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a signature image for invoice PDF generation.</string>
```

8. Build and run on iPhone simulator or real iPhone.

## File structure

```text
ThrottleartInvoiceApp
├── ThrottleartInvoiceApp.swift
├── Screens
│   ├── ContentView.swift
│   ├── InvoiceFormView.swift
│   ├── ItemRowsView.swift
│   ├── PresetItemsView.swift
│   ├── InvoicePreviewView.swift
│   └── InvoiceHistoryView.swift
├── Models
│   ├── Invoice.swift
│   ├── InvoiceItem.swift
│   └── ItemPreset.swift
├── Services
│   ├── InvoiceCalculator.swift
│   ├── InvoicePDFGenerator.swift
│   ├── DateFormatterService.swift
│   └── PDFShareService.swift
├── Storage
│   ├── SwiftDataManager.swift
│   └── CoreDataManager.swift
└── Assets
    └── README.md
```

## Note about storage naming

Your structure mentioned `CoreDataManager`, but your tech table allowed **CoreData or SwiftData**. This implementation uses SwiftData because it is simpler, native, and cleaner for this app. A `CoreDataManager.swift` alias is included so the folder structure stays close to what you asked.
