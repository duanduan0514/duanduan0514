import SwiftUI

enum AppSection {
    case bills
    case entry
    case directory
    case query
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var section: AppSection = .bills
    @State private var entryDate = DateKey.startOfDay(Date())
    @State private var entryReloadID = UUID()

    var body: some View {
        Group {
            switch section {
            case .bills:
                HomeView(
                    onNewEntry: openTodayEntry,
                    onOpenDate: openEntry,
                    onOpenSettings: { section = .directory },
                    onOpenReports: { section = .query }
                )
            case .entry:
                EntryView(initialDate: entryDate) {
                    store.reloadAll()
                    section = .bills
                }
                .id(entryReloadID)
            case .directory:
                DirectoryView { section = .bills }
            case .query:
                QueryView { section = .bills }
            }
        }
        .alert(isPresented: errorBinding) {
            Alert(
                title: Text("本机数据错误"),
                message: Text(store.lastError ?? "未知错误"),
                dismissButton: .default(Text("知道了")) { store.lastError = nil }
            )
        }
    }

    private func openTodayEntry() {
        entryDate = DateKey.startOfDay(Date())
        entryReloadID = UUID()
        section = .entry
    }

    private func openEntry(_ date: Date) {
        entryDate = DateKey.startOfDay(date)
        entryReloadID = UUID()
        section = .entry
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )
    }
}