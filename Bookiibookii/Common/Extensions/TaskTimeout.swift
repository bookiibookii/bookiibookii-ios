import Foundation

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? { "요청 시간이 초과되었습니다." }
}

/// 주어진 시간 안에 `operation`이 끝나지 않으면 `TimeoutError`를 던지고 진행 중이던 작업을 취소합니다.
/// URLSession 기반 요청처럼 cancellation을 인식하는 작업은 즉시 정리됩니다.
func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}
