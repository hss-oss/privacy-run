import Foundation

public enum ProbeRunnerError: LocalizedError {
    case failedToStart(String)
    case failed(Int32, String)
    case invalidOutput

    public var errorDescription: String? {
        switch self {
        case .failedToStart(let message):
            "Probe 无法启动：\(message)"
        case .failed(let status, let message):
            "Probe 失败（\(status)）：\(message)"
        case .invalidOutput:
            "Probe 返回了无法解析的结果"
        }
    }
}

public struct ProbeRunner: Sendable {
    public init() {}

    public func run(
        executableURL: URL,
        environment: [String: String],
        arguments: [String]
    ) throws -> ProbeReport {
        let output = Pipe()
        let errors = Pipe()
        let process = Process()
        process.executableURL = executableURL
        process.environment = environment
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = errors

        do {
            try process.run()
        } catch {
            throw ProbeRunnerError.failedToStart(error.localizedDescription)
        }
        process.waitUntilExit()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = errors.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            let message = String(data: errorData, encoding: .utf8) ?? "未知错误"
            throw ProbeRunnerError.failed(process.terminationStatus, message)
        }

        guard let report = try? JSONDecoder().decode(ProbeReport.self, from: outputData) else {
            throw ProbeRunnerError.invalidOutput
        }
        return report
    }
}
