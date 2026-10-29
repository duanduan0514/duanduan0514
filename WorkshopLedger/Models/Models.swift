import Foundation

struct Customer: Identifiable, Hashable {
    let id: Int64
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(id: Int64, name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Employee: Identifiable, Hashable {
    let id: Int64
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(id: Int64, name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct BillItem: Identifiable, Hashable {
    let id: Int64
    let billID: Int64
    let customer: String
    let employee: String
    let model: String
    let quantity: Int
    let colorCount: Int

    var workload: Int { quantity * colorCount }
}

struct Bill: Identifiable, Hashable {
    let id: Int64
    let date: Date
    let submittedAt: Date
    let items: [BillItem]

    var workload: Int { items.reduce(0) { $0 + $1.workload } }
    var customerCount: Int { Set(items.map(\.customer)).count }
    var employeeCount: Int { Set(items.map(\.employee)).count }
}

struct DraftSummary: Identifiable, Hashable {
    let date: Date
    let updatedAt: Date
    var id: String { DateKey.string(from: date) }
}

struct EntryRow: Identifiable, Codable, Hashable {
    var id: UUID
    var customer: String
    var employee: String
    var model: String
    var quantity: String
    var colorCount: Int

    static func empty(customer: String = "", employee: String = "") -> EntryRow {
        EntryRow(
            id: UUID(),
            customer: customer,
            employee: employee,
            model: "",
            quantity: "",
            colorCount: 1
        )
    }

    var quantityValue: Int? {
        guard let value = Int(quantity), value > 0 else { return nil }
        return value
    }

    var isCompletelyEmpty: Bool {
        customer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && employee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct DraftPayload: Codable {
    var rows: [EntryRow]
}

struct QueryRecord: Identifiable, Hashable {
    let id: String
    let billID: Int64
    let itemID: Int64
    let date: Date
    let employee: String
    let customer: String
    let model: String
    let quantity: Int
    let colorCount: Int
    let workload: Int
}

enum DateKey {
    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    static func string(from date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        keyFormatter.date(from: string)
    }

    static func display(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func filenameTimestamp(_ date: Date = Date()) -> String {
        filenameFormatter.string(from: date)
    }

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

extension Array where Element == EntryRow {
    func normalizedForSubmission() -> [EntryRow] {
        map { row in
            var copy = row
            copy.customer = copy.customer.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.employee = copy.employee.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.model = copy.model.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.quantity = copy.quantity.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.colorCount = Swift.min(5, Swift.max(1, copy.colorCount))
            return copy
        }
        .filter { !$0.isCompletelyEmpty }
    }
}
