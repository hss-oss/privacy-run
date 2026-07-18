import PrivacyRunCore
import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject private var store: PrivacyRunStore
    let application: AppRecord

    private let timeZones = [
        "跟随系统",
        "UTC",
        "Asia/Tokyo",
        "Asia/Shanghai",
        "Asia/Singapore",
        "Europe/London",
        "Europe/Berlin",
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles"
    ]
    private let languages = [
        ("跟随系统", ""),
        ("简体中文", "zh-Hans"),
        ("繁体中文", "zh-Hant"),
        ("English (United States)", "en-US"),
        ("English (United Kingdom)", "en-GB"),
        ("日本語", "ja-JP")
    ]
    private let locales = [
        ("跟随系统", ""),
        ("中国大陆", "zh_CN"),
        ("中国香港", "zh_HK"),
        ("美国", "en_US"),
        ("英国", "en_GB"),
        ("日本", "ja_JP")
    ]

    var body: some View {
        Form {
            Section {
                Picker("时区", selection: timeZoneSelection) {
                    ForEach(timeZones, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                Picker("语言", selection: languageSelection) {
                    ForEach(languages, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }

                Picker("地区格式", selection: localeSelection) {
                    ForEach(locales, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
            } header: {
                Text("环境设置")
            } footer: {
                Text("配置仅应用于由 PrivacyRun 启动的新进程，不修改 macOS 系统设置。")
            }

            Section {
                HStack {
                    Label("宿主系统保持原值", systemImage: "checkmark.shield")
                    Spacer()
                    Text("0 项系统修改")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button(action: store.launchSelectedApplication) {
                    switch store.launchState {
                    case .launching:
                        ProgressView()
                            .controlSize(.small)
                        Text("正在启动")
                    default:
                        Image(systemName: "play.fill")
                        Text("启动 App")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.launchState == .launching)
            }
            .padding(16)
            .background(.bar)
        }
    }

    private var timeZoneSelection: Binding<String> {
        Binding(
            get: {
                switch application.configuration.timeZone {
                case .inherit:
                    "跟随系统"
                case .fixed(let identifier):
                    identifier
                }
            },
            set: { value in
                var configuration = application.configuration
                configuration.timeZone =
                    value == "跟随系统" ? .inherit : .fixed(identifier: value)
                store.updateConfiguration(configuration)
            }
        )
    }

    private var languageSelection: Binding<String> {
        Binding(
            get: { application.configuration.languageIdentifier ?? "" },
            set: { value in
                var configuration = application.configuration
                configuration.languageIdentifier = value.isEmpty ? nil : value
                store.updateConfiguration(configuration)
            }
        )
    }

    private var localeSelection: Binding<String> {
        Binding(
            get: { application.configuration.localeIdentifier ?? "" },
            set: { value in
                var configuration = application.configuration
                configuration.localeIdentifier = value.isEmpty ? nil : value
                store.updateConfiguration(configuration)
            }
        )
    }
}
