import PrivacyRunCore
import SwiftUI

struct ReportView: View {
    let application: AppRecord

    var body: some View {
        if let report = application.latestReport {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("运行报告")
                            .font(.title3.weight(.medium))
                        Text(report.createdAt.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let processIdentifier = report.processIdentifier {
                        Text("PID \(processIdentifier)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 0) {
                    GridRow {
                        tableHeader("检查项")
                        tableHeader("期望值")
                        tableHeader("实际值")
                        tableHeader("结果")
                    }
                    Divider().gridCellColumns(4)

                    ForEach(report.checks) { check in
                        GridRow {
                            Text(check.name)
                            Text(check.expected)
                                .foregroundStyle(.secondary)
                            Text(check.actual)
                                .foregroundStyle(.secondary)
                            Label(
                                check.resultLabel,
                                systemImage: icon(for: check.result)
                            )
                            .foregroundStyle(color(for: check.result))
                        }
                        .padding(.vertical, 10)
                        Divider().gridCellColumns(4)
                    }
                }

                Label(
                    "系统字体为只读检测。时区与 IP 按国家或地区比较，IP 查询结果可能存在误差。",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if let launchError = report.launchError {
                    Label(launchError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(24)
        } else {
            ContentUnavailableView {
                Label("尚无运行报告", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("启动 App 后会自动生成验证结果。")
            }
        }
    }

    private func tableHeader(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    private func icon(for result: CheckResult) -> String {
        switch result {
        case .passed:
            "checkmark.circle.fill"
        case .information:
            "info.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .unavailable:
            "questionmark.circle"
        }
    }

    private func color(for result: CheckResult) -> Color {
        switch result {
        case .passed:
            .green
        case .information:
            .secondary
        case .warning:
            .orange
        case .unavailable:
            .secondary
        }
    }
}
