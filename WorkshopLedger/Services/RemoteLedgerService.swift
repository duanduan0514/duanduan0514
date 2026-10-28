import Foundation

/// 服务器连接的业务边界。
///
/// 当前版本只注入 `DisabledRemoteLedgerService`，不会创建网络任务，也不会
/// 读取账号或密码。后续接入飞牛服务器时，只需新增一个符合该协议的 HTTP
/// 实现，并通过 `AppStore` 的初始化参数注入，不需要重写记账和报表逻辑。
struct ServerConnectionConfiguration: Codable, Equatable {
    var isEnabled: Bool
    var baseURL: URL?

    static let disabled = ServerConnectionConfiguration(isEnabled: false, baseURL: nil)

    var isReady: Bool {
        isEnabled && baseURL != nil
    }
}

struct RemoteBillItemRecord: Codable, Equatable {
    let customer: String
    let employee: String
    let model: String
    let quantity: Int
    let colorCount: Int
    let workload: Int

    init(item: BillItem) {
        customer = item.customer
        employee = item.employee
        model = item.model
        quantity = item.quantity
        colorCount = item.colorCount
        workload = item.workload
    }
}

struct RemoteBillRecord: Codable, Equatable {
    let localBillID: Int64
    let billDate: String
    let submittedAt: Date
    let items: [RemoteBillItemRecord]

    init(bill: Bill) {
        localBillID = bill.id
        billDate = DateKey.string(from: bill.date)
        submittedAt = bill.submittedAt
        items = bill.items.map(RemoteBillItemRecord.init)
    }
}

struct RemoteUploadReceipt: Codable, Equatable {
    let remoteID: String
    let syncedAt: Date
}

enum RemoteLedgerError: LocalizedError {
    case disabled
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "当前为纯离线模式，服务器同步尚未启用。"
        case .notConfigured:
            return "尚未配置服务器地址。"
        }
    }
}

protocol RemoteLedgerService {
    var configuration: ServerConnectionConfiguration { get }
    func upload(bill: Bill) async throws -> RemoteUploadReceipt
}

/// 当前默认实现：保留服务器接入点，但不产生任何网络请求。
struct DisabledRemoteLedgerService: RemoteLedgerService {
    let configuration = ServerConnectionConfiguration.disabled

    func upload(bill: Bill) async throws -> RemoteUploadReceipt {
        throw RemoteLedgerError.disabled
    }
}

/// 仅保存未来服务器连接所需的配置，不包含账号和密码。
/// 当前界面不会调用它；后续验证服务器时再接入设置页面。
final class ServerConnectionSettingsStore {
    private let defaults: UserDefaults
    private let storageKey = "workshopLedger.serverConnection.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var configuration: ServerConnectionConfiguration {
        guard let data = defaults.data(forKey: storageKey),
              let value = try? JSONDecoder().decode(ServerConnectionConfiguration.self, from: data) else {
            return .disabled
        }
        return value
    }

    func save(_ configuration: ServerConnectionConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}