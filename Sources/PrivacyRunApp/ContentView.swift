import PrivacyRunCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PrivacyRunStore

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .alert(
            "无法完成操作",
            isPresented: Binding(
                get: {
                    if case .failed = store.launchState {
                        return true
                    }
                    return false
                },
                set: { visible in
                    if !visible {
                        store.dismissError()
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {
                store.dismissError()
            }
        } message: {
            if case .failed(let message) = store.launchState {
                Text(message)
            }
        }
    }

    private var sidebar: some View {
        List(selection: $store.selectedApplicationID) {
            Section("应用") {
                ForEach(store.applications) { application in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(application.name)
                            Text(application.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } icon: {
                        Image(nsImage: icon(for: application))
                    }
                    .tag(application.id)
                }
            }
        }
        .navigationTitle("PrivacyRun")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(action: store.addApplication) {
                    Image(systemName: "plus")
                }
                .help("添加 App")

                Button(action: store.removeSelectedApplication) {
                    Image(systemName: "minus")
                }
                .help("移除 App")
                .disabled(store.selectedApplication == nil)

                Spacer()
            }
            .padding(10)
            .background(.bar)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let application = store.selectedApplication {
            VStack(spacing: 0) {
                header(application)
                Divider()

                switch store.screen {
                case .configuration:
                    ConfigurationView(application: application)
                case .report:
                    ReportView(application: application)
                }
            }
        } else {
            ContentUnavailableView {
                Label("添加一个 App", systemImage: "app.badge")
            } description: {
                Text("选择要使用独立环境设置启动的 macOS 应用。")
            } actions: {
                Button("添加 App", action: store.addApplication)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func header(_ application: AppRecord) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: icon(for: application))
                .resizable()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(application.name)
                    .font(.headline)
                Text(application.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("页面", selection: $store.screen) {
                Text("配置").tag(PrivacyRunStore.Screen.configuration)
                Text("报告").tag(PrivacyRunStore.Screen.report)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 180)
        }
        .padding(20)
    }

    private func icon(for application: AppRecord) -> NSImage {
        NSWorkspace.shared.icon(forFile: application.bundlePath)
    }
}
