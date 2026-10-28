import Foundation
import SwiftUI
import UIKit

enum CSVExporter {
    static func makeFile(records: [QueryRecord]) throws -> URL {
        let headers = ["日期", "员工", "客户", "产品型号", "数量", "色数", "计酬工作量"]
        var rows: [[String]] = [headers]
        rows.append(contentsOf: records.map { record in
            [
                DateKey.string(from: record.date),
                record.employee,
                record.customer,
                record.model,
                String(record.quantity),
                String(record.colorCount),
                String(record.workload)
            ]
        })

        let csv = "\u{FEFF}" + rows.map { row in
            row.map(escape).joined(separator: ",")
        }.joined(separator: "\r\n") + "\r\n"

        let filename = "计件流水-\(DateKey.filenameTimestamp()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

enum ExportError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "导出文件编码失败。"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}