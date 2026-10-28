import Foundation
import Combine

final class AppStore: ObservableObject {
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var bills: [Bill] = []
    @Published private(set) var drafts: [DraftSummary] = []
    @Published var lastError: String?

    private let database: Database?
    private let remoteLedger: RemoteLedgerService
    let serverSettings: ServerConnectionSettingsStore

    /// 当前默认注入纯离线实现，不发起网络请求。
    /// 后续服务器验证完成后，可在此注入 HTTP 实现，而无需改动账目业务层。
    init(
        remoteLedger: RemoteLedgerService = DisabledRemoteLedgerService(),
        serverSettings: ServerConnectionSettingsStore = ServerConnectionSettingsStore()
    ) {
        self.remoteLedger = remoteLedger
        self.serverSettings = serverSettings
        do {
            let database = try Database()
            self.database = database
            reloadAll()
        } catch {
            self.database = nil
            self.lastError = error.localizedDescription
        }
    }

    func reloadAll() {
        guard let database else { return }
        do {
            customers = try database.loadCustomers()
            employees = try database.loadEmployees()
            bills = try database.loadBills()
            drafts = try database.loadDraftSummaries()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func bill(on date: Date) -> Bill? {
        let key = DateKey.string(from: date)
        return bills.first { DateKey.string(from: $0.date) == key }
    }

    func draft(on date: Date) -> DraftSummary? {
        let key = DateKey.string(from: date)
        return drafts.first { DateKey.string(from: $0.date) == key }
    }

    func loadRows(for date: Date) -> (rows: [EntryRow], source: EntrySource) {
        guard let database else { return ([EntryRow.empty()], .new) }
        do {
            if let draftRows = try database.loadDraft(date: date), !draftRows.isEmpty {
                return (draftRows, .draft)
            }
            if let existing = bill(on: date), !existing.items.isEmpty {
                let rows = existing.items.map {
                    EntryRow(
                        id: UUID(),
                        customer: $0.customer,
                        employee: $0.employee,
                        model: $0.model,
                        quantity: String($0.quantity),
                        colorCount: $0.colorCount
                    )
                }
                return (rows, .bill)
            }
        } catch {
            lastError = error.localizedDescription
        }
        return ([EntryRow.empty(customer: customers.first?.name ?? "", employee: employees.first?.name ?? "")], .new)
    }

    func saveDraft(date: Date, rows: [EntryRow]) {
        guard let database else { return }
        do {
            try database.saveDraft(date: date, rows: rows)
            drafts = try database.loadDraftSummaries()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteDraft(date: Date) {
        guard let database else { return }
        do {
            try database.deleteDraft(date: date)
            drafts = try database.loadDraftSummaries()
        } catch {
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func submitBill(date: Date, rows: [EntryRow]) throws -> Bill {
        guard let database else {
            throw DatabaseError.openFailed("数据库未打开")
        }
        let bill = try database.saveBill(date: date, rows: rows)
        customers = try database.loadCustomers()
        employees = try database.loadEmployees()
        bills = try database.loadBills()
        drafts = try database.loadDraftSummaries()
        return bill
    }

    func addCustomer(name: String) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        _ = try database.addCustomer(name: name)
        customers = try database.loadCustomers()
    }

    func updateCustomer(_ customer: Customer, name: String) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        try database.updateCustomer(id: customer.id, name: name)
        customers = try database.loadCustomers()
    }

    func deleteCustomer(_ customer: Customer) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        try database.deleteCustomer(id: customer.id)
        customers = try database.loadCustomers()
    }

    func addEmployee(name: String) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        _ = try database.addEmployee(name: name)
        employees = try database.loadEmployees()
    }

    func updateEmployee(_ employee: Employee, name: String) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        try database.updateEmployee(id: employee.id, name: name)
        employees = try database.loadEmployees()
    }

    func deleteEmployee(_ employee: Employee) throws {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        try database.deleteEmployee(id: employee.id)
        employees = try database.loadEmployees()
    }

    func queryRecords(
        startDate: Date,
        endDate: Date,
        employee: String,
        customer: String,
        colorCount: Int?,
        modelText: String
    ) -> [QueryRecord] {
        let start = DateKey.startOfDay(startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: DateKey.startOfDay(endDate)) ?? endDate
        let search = modelText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return bills
            .filter { $0.date >= start && $0.date < end }
            .flatMap { bill in
                bill.items.compactMap { item in
                    guard employee.isEmpty || item.employee == employee else { return nil }
                    guard customer.isEmpty || item.customer == customer else { return nil }
                    guard colorCount == nil || item.colorCount == colorCount else { return nil }
                    guard search.isEmpty || item.model.lowercased().contains(search) else { return nil }
                    return QueryRecord(
                        id: "\(bill.id)-\(item.id)",
                        billID: bill.id,
                        itemID: item.id,
                        date: bill.date,
                        employee: item.employee,
                        customer: item.customer,
                        model: item.model,
                        quantity: item.quantity,
                        colorCount: item.colorCount,
                        workload: item.workload
                    )
                }
            }
            .sorted {
                if $0.date == $1.date { return $0.id > $1.id }
                return $0.date > $1.date
            }
    }

    var allCustomerNames: [String] {
        uniqueSorted(customers.map(\.name) + bills.flatMap { $0.items.map(\.customer) })
    }

    var allEmployeeNames: [String] {
        uniqueSorted(employees.map(\.name) + bills.flatMap { $0.items.map(\.employee) })
    }

    var allModelNames: [String] {
        uniqueSorted(bills.flatMap { $0.items.map(\.model) })
    }

    func draftRows(on date: Date) -> [EntryRow] {
        guard let database else { return [] }
        return (try? database.loadDraft(date: date)) ?? []
    }

    func createDatabaseBackup() throws -> URL {
        guard let database else { throw DatabaseError.openFailed("数据库未打开") }
        return try database.createBackupCopy()
    }

    private func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty })).sorted { $0.localizedCompare($1) == .orderedAscending }
    }
}

enum EntrySource: Equatable {
    case new
    case draft
    case bill
}
