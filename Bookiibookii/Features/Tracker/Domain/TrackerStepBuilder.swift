import Foundation

/// 안드 trkHost.TradeStatusItem 대응.
struct TrackerStepItem: Identifiable, Equatable, Hashable {
    let id: String          // 안드 StepId
    let title: String
    let description: String
    let badge: String
}

extension DeliveryPhase {
    /// 안드 Phase enum의 ordinal — 진행 비교 + visibleCount 계산용.
    var ordinal: Int {
        switch self {
        case .initState:           return 0
        case .hostReading:         return 1
        case .hostShippingReady:   return 2
        case .hostShipped:         return 3
        case .guestReading:        return 4
        case .guestShippingReady:  return 5
        case .guestShipped:        return 6
        case .finished:            return 7
        }
    }
}

/// 안드 HostViewModel.buildSteps / GuestViewModel.buildSteps 대응.
/// 현재 phase까지의 단계만 반환하며, 첫 단계가 마지막에 오도록 `.reversed()` 처리.
enum TrackerStepBuilder {
    static func buildHostSteps(phase: DeliveryPhase) -> [TrackerStepItem] {
        let all: [TrackerStepItem] = [
            .init(
                id: "HOST_READING",
                title: "책을 읽고 있어요",
                description: hostReadingDescription(phase),
                badge: hostReadingBadge(phase)
            ),
            .init(
                id: "HOST_SHIP",
                title: "게스트에게 책을 발송해요",
                description: "책이 파손되지 않도록 꼼꼼하게 포장해주세요.",
                badge: hostShipBadge(phase)
            ),
            .init(
                id: "RECEIVE_CHECK",
                title: "수령 인증을 확인해주세요",
                description: "게스트가 책을 잘 받았는지 확인해주세요.",
                badge: receiveCheckBadge(phase)
            ),
            .init(
                id: "GUEST_READING",
                title: "게스트가 책을 읽고 있어요",
                description: "게스트의 독서 카드를 확인해볼까요?",
                badge: guestReadingBadgeHost(phase)
            ),
            .init(
                id: "GUEST_SHIP",
                title: "게스트가 책을 발송해요",
                description: "게스트가 곧 책을 발송할 예정이에요.",
                badge: guestShipBadge(phase)
            ),
            .init(
                id: "RECEIVE_REGISTER",
                title: "수령 인증을 등록해주세요",
                description: "책을 받으면 수령 인증을 등록해주세요.",
                badge: receiveRegisterBadge(phase)
            ),
            .init(
                id: "FINISH_HEADER",
                title: "교환독서가 종료되었어요!",
                description: "책과 파트너에 대한 후기를 남겨주세요.",
                badge: "D-7"
            ),
        ]
        return Array(all.prefix(visibleCount(phase: phase)).reversed())
    }

    static func buildGuestSteps(phase: DeliveryPhase) -> [TrackerStepItem] {
        let all: [TrackerStepItem] = [
            .init(
                id: "HOST_READING",
                title: "호스트가 책을 읽고 있어요",
                description: "호스트의 독서 카드를 확인해볼까요?",
                badge: doneIf(phase.ordinal > DeliveryPhase.hostReading.ordinal)
            ),
            .init(
                id: "HOST_SHIP",
                title: "호스트가 책을 발송해요",
                description: "호스트가 곧 책을 발송할 예정이에요.",
                badge: doneIf(phase.ordinal >= DeliveryPhase.hostShipped.ordinal)
            ),
            .init(
                id: "RECEIVE_REGISTER",
                title: "수령 인증을 등록해주세요",
                description: "책을 받으면 수령 인증을 등록해주세요.",
                badge: doneIf(phase.ordinal >= DeliveryPhase.guestReading.ordinal)
            ),
            .init(
                id: "GUEST_READING",
                title: "책을 읽고 있어요",
                description: "독서카드를 작성하면 교환독서가 더 즐거워져요!",
                badge: doneIf(phase.ordinal > DeliveryPhase.guestReading.ordinal)
            ),
            .init(
                id: "GUEST_SHIP",
                title: "호스트에게 책을 반환해요",
                description: "책이 파손되지 않도록 꼼꼼하게 포장해주세요.",
                badge: doneIf(phase.ordinal >= DeliveryPhase.guestShipped.ordinal)
            ),
            .init(
                id: "RECEIVE_CHECK",
                title: "수령 인증을 확인해주세요",
                description: "호스트가 책을 잘 받았는지 확인해주세요.",
                badge: doneIf(phase.ordinal >= DeliveryPhase.finished.ordinal)
            ),
            .init(
                id: "FINISH_HEADER",
                title: "교환독서가 종료되었어요!",
                description: "책과 파트너에 대한 후기를 남겨주세요.",
                badge: doneIf(phase == .finished)
            ),
        ]
        return Array(all.prefix(visibleCount(phase: phase)).reversed())
    }

    // MARK: - 공통

    private static func visibleCount(phase: DeliveryPhase) -> Int {
        switch phase {
        case .initState, .hostReading: return 1
        case .hostShippingReady:       return 2
        case .hostShipped:             return 3
        case .guestReading:            return 4
        case .guestShippingReady:      return 5
        case .guestShipped:            return 6
        case .finished:                return 7
        }
    }

    private static func doneIf(_ condition: Bool) -> String {
        condition ? "완료" : "예정"
    }

    // MARK: - Host badge / description

    private static func hostReadingDescription(_ phase: DeliveryPhase) -> String {
        if phase.ordinal < DeliveryPhase.hostReading.ordinal {
            return "아직 독서를 시작하지 않았어요.\n독서를 시작하면 아래 시작하기 버튼을 눌러주세요"
        }
        return "독서카드를 작성하면 교환독서가 더 즐거워져요!"
    }

    private static func hostReadingBadge(_ phase: DeliveryPhase) -> String {
        phase.ordinal > DeliveryPhase.hostReading.ordinal ? "완료" : "예정"
    }

    private static func hostShipBadge(_ phase: DeliveryPhase) -> String {
        phase.ordinal >= DeliveryPhase.hostShipped.ordinal ? "완료" : "예정"
    }

    private static func receiveCheckBadge(_ phase: DeliveryPhase) -> String {
        phase.ordinal >= DeliveryPhase.guestReading.ordinal ? "완료" : "예정"
    }

    private static func guestReadingBadgeHost(_ phase: DeliveryPhase) -> String {
        phase.ordinal > DeliveryPhase.guestReading.ordinal ? "완료" : "예정"
    }

    private static func guestShipBadge(_ phase: DeliveryPhase) -> String {
        phase.ordinal >= DeliveryPhase.guestShipped.ordinal ? "완료" : "예정"
    }

    private static func receiveRegisterBadge(_ phase: DeliveryPhase) -> String {
        phase.ordinal >= DeliveryPhase.finished.ordinal ? "완료" : "예정"
    }
}
