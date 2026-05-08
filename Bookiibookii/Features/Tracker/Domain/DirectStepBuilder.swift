import Foundation

/// 안드 trkDirectHost/trkDirectGuest의 buildSteps + reversed() 대응.
/// status별 visibleCount/doneCount는 안드 progressByStatus 표를 그대로 옮김.
enum DirectStepBuilder {
    static func buildHostSteps(status: TrackerStatusDTO) -> [TrackerStepItem] {
        let all: [TrackerStepItem] = [
            .init(
                id: "GUEST_RETURN_SHIP",
                title: "책을 읽고 있어요",
                description: "독서카드를 작성하면 교환독서가 더 즐거워져요!",
                badge: "예정"
            ),
            .init(
                id: "GUEST_SET_APPOINTMENT",
                title: "게스트와 만날 약속을 정해요",
                description: "게스트와 협의 후 약속을 정해주세요.",
                badge: "예정"
            ),
            .init(
                id: "GUEST_READ",
                title: "게스트에게 책을 전달해주세요",
                description: "약속 장소에서 게스트를 만나 책을 전달해주세요.",
                badge: "예정"
            ),
            .init(
                id: "HOST_EXCHANGE_HANDOVER",
                title: "게스트가 책을 읽고 있어요",
                description: "게스트의 독서 카드를 확인해볼까요?",
                badge: "예정"
            ),
            .init(
                id: "HOST_SET_APPOINTMENT",
                title: "게스트와 만날 약속을 정해요",
                description: "게스트와 협의 후 약속을 등록해주세요.",
                badge: "예정"
            ),
            .init(
                id: "HOST_READ",
                title: "게스트에게 책을 돌려받아요",
                description: "약속 장소에서 게스트를 만나 책을 받으세요.",
                badge: "예정"
            ),
            .init(
                id: "FINISH",
                title: "교환독서가 종료되었어요!",
                description: "책과 파트너에 대한 후기를 남겨주세요.",
                badge: "예정"
            ),
        ]
        return apply(progress: hostProgress(status: status), to: all)
    }

    static func buildGuestSteps(status: TrackerStatusDTO) -> [TrackerStepItem] {
        let all: [TrackerStepItem] = [
            .init(
                id: "HOST_READING",
                title: "호스트가 책을 읽고 있어요",
                description: "호스트의 독서 카드를 확인해볼까요?",
                badge: "예정"
            ),
            .init(
                id: "APPOINTMENT_TO_GUEST",
                title: "호스트와 만날 약속을 정해요",
                description: "호스트와 협의 후 약속을 정해주세요.",
                badge: "예정"
            ),
            .init(
                id: "HANDOVER_TO_GUEST",
                title: "호스트에게 책을 받아요",
                description: "약속 장소에서 호스트를 만나 책을 받으세요.",
                badge: "예정"
            ),
            .init(
                id: "GUEST_READING",
                title: "책을 읽고 있어요",
                description: "독서카드를 작성하면 교환독서가 더 즐거워져요!",
                badge: "예정"
            ),
            .init(
                id: "APPOINTMENT_TO_HOST",
                title: "호스트와 만날 약속을 정해요",
                description: "호스트와 협의 후 약속을 등록해주세요.",
                badge: "예정"
            ),
            .init(
                id: "RETURN_TO_HOST",
                title: "호스트에게 책을 반납해주세요",
                description: "약속 장소에서 호스트를 만나 책을 반납해주세요.",
                badge: "예정"
            ),
            .init(
                id: "FINISH",
                title: "교환독서가 종료되었어요!",
                description: "책과 파트너에 대한 후기를 남겨주세요.",
                badge: "예정"
            ),
        ]
        return apply(progress: guestProgress(status: status), to: all)
    }

    // MARK: - 내부

    private struct Progress {
        let visibleCount: Int
        let doneCount: Int
    }

    /// 안드 DirectHostViewModel.progressByStatus 기반 + COMPLETED만 의도적으로 (7,7) 로 끌어올림.
    /// 안드는 COMPLETED 도 (6,6) 이라 호스트 step 카드에 "교환독서가 종료되었어요!" 헤더 행이 안 보이는데,
    /// 게스트는 (7,7) 로 헤더가 보여서 비대칭이 생김. iOS에서는 호스트도 헤더가 보이도록 통일 (안드는 추후 동기화 예정).
    private static func hostProgress(status: TrackerStatusDTO) -> Progress {
        switch status {
        case .ready:                                     return .init(visibleCount: 1, doneCount: 0)
        case .hostReading, .hostExtension:               return .init(visibleCount: 1, doneCount: 0)
        case .hostDone:                                  return .init(visibleCount: 2, doneCount: 1)
        case .shippingToGuest:                           return .init(visibleCount: 3, doneCount: 2)
        case .received:                                  return .init(visibleCount: 4, doneCount: 3)
        case .guestReading, .guestExtension:             return .init(visibleCount: 4, doneCount: 3)
        case .guestDone:                                 return .init(visibleCount: 5, doneCount: 4)
        case .shippingToHost:                            return .init(visibleCount: 6, doneCount: 5)
        case .returned:                                  return .init(visibleCount: 6, doneCount: 6)
        case .completed:                                 return .init(visibleCount: 7, doneCount: 7)
        case .unknown:                                   return .init(visibleCount: 1, doneCount: 0)
        }
    }

    /// 안드 DirectGuestViewModel.progressByStatus 와 1:1.
    /// COMPLETED는 (7,7) — FINISH 헤더 노출 (호스트와 다름).
    private static func guestProgress(status: TrackerStatusDTO) -> Progress {
        switch status {
        case .ready:                                     return .init(visibleCount: 1, doneCount: 0)
        case .hostReading, .hostExtension:               return .init(visibleCount: 1, doneCount: 0)
        case .hostDone:                                  return .init(visibleCount: 2, doneCount: 1)
        case .shippingToGuest:                           return .init(visibleCount: 3, doneCount: 2)
        case .received:                                  return .init(visibleCount: 4, doneCount: 3)
        case .guestReading, .guestExtension:             return .init(visibleCount: 4, doneCount: 3)
        case .guestDone:                                 return .init(visibleCount: 5, doneCount: 4)
        case .shippingToHost:                            return .init(visibleCount: 6, doneCount: 5)
        case .returned:                                  return .init(visibleCount: 6, doneCount: 6)
        case .completed:                                 return .init(visibleCount: 7, doneCount: 7)
        case .unknown:                                   return .init(visibleCount: 1, doneCount: 0)
        }
    }

    private static func apply(progress: Progress, to all: [TrackerStepItem]) -> [TrackerStepItem] {
        let visible = all.prefix(min(progress.visibleCount, all.count))
        let withBadges = visible.enumerated().map { idx, item -> TrackerStepItem in
            let badge = idx < progress.doneCount ? "완료" : "예정"
            return TrackerStepItem(
                id: item.id,
                title: item.title,
                description: item.description,
                badge: badge
            )
        }
        return Array(withBadges.reversed())
    }
}
