import Foundation

extension TrackerDetailResDTO {
    func toUiState() -> TrackerDetailUiState {
        let dDayChip = "D-\(max(0, dDay ?? 0))"
        let safeSteps = steps ?? []
        let currentStepStatus = safeSteps.first(where: { $0.completed != true })?.status
        let (primary, secondary) = actionsForStatus(displayStatus)

        var myProfile = myBook.toProfile()
        myProfile.progressLabelOverride = progressTextOverride(displayStatus, isMine: true)
        var partnerProfile = partnerBook.toProfile()
        partnerProfile.progressLabelOverride = progressTextOverride(displayStatus, isMine: false)

        let statusLabel = [
            ellipsizeTitle(displayBookTitle ?? "", maxChars: 9),
            displayStatusLabel ?? "",
        ].filter { !$0.isEmpty }.joined(separator: " · ")

        return TrackerDetailUiState(
            groupName: groupName ?? "",
            dDay: dDayChip,
            dDayCount: dDay,
            statusLabel: statusLabel,
            currentStepLabel: trackerPhaseLabel(currentStepStatus),
            currentStepLabelStyle: trackerPhaseStyle(currentStepStatus),
            currentStepPosition: trackerPhasePosition(currentStepStatus),
            myProfile: myProfile,
            partnerProfile: partnerProfile,
            exchangeLabel: trackerExchangeLabel(tradeType),
            primaryAction: primary,
            secondaryAction: secondary,
            primaryEnabled: !isPrimaryActionDisabled(displayStatus),
            secondaryEnabled: !isSecondaryActionDisabled(displayStatus),
            showReadingProgress: !isReadingProgressHidden(displayStatus),
            isHost: myRole == "HOST",
            steps: trackerUiSteps(safeSteps, dDayChipText: dDayChip)
        )
    }
}

// tradeType → 교환 방식 라벨
private func trackerExchangeLabel(_ tradeType: String?) -> String {
    switch tradeType {
    case "DIRECT":   return "직접 교환"
    case "DELIVERY": return "택배 교환"
    default:         return ""
    }
}

// step.status(14종) → 4개 phase 라벨
private func trackerPhaseLabel(_ status: String?) -> String {
    switch status {
    case "MY_BOOK_READING", "MY_BOOK_REVIEWING":
        return "내 책 읽기"
    case "EXCHANGE_TRACKING_REGISTER", "EXCHANGE_RECEIPT_CONFIRM",
         "DIRECT_EXCHANGE_MEETING_REGISTER", "DIRECT_EXCHANGE_COMPLETE":
        return "교환"
    case "PARTNER_BOOK_READING", "PARTNER_BOOK_REVIEWING":
        return "파트너 책 읽기"
    // RETURN_*, DIRECT_RETURN_*, PARTNER_REVIEWING, COMPLETED, nil
    default:
        return "반납"
    }
}

// 내 책 읽기 / 교환 → Main, 파트너 책 읽기 / 반납 → Sub
private func trackerPhaseStyle(_ status: String?) -> TrackerStepLabelStyle {
    switch status {
    case "MY_BOOK_READING", "MY_BOOK_REVIEWING",
         "EXCHANGE_TRACKING_REGISTER", "EXCHANGE_RECEIPT_CONFIRM",
         "DIRECT_EXCHANGE_MEETING_REGISTER", "DIRECT_EXCHANGE_COMPLETE":
        return .main
    default:
        return .sub
    }
}

// 4단계 phase 중 현재 위치 (1: 내 책 읽기, 2: 교환, 3: 파트너 책 읽기, 4: 반납)
private func trackerPhasePosition(_ status: String?) -> Int {
    switch status {
    case "MY_BOOK_READING", "MY_BOOK_REVIEWING":
        return 1
    case "EXCHANGE_TRACKING_REGISTER", "EXCHANGE_RECEIPT_CONFIRM",
         "DIRECT_EXCHANGE_MEETING_REGISTER", "DIRECT_EXCHANGE_COMPLETE":
        return 2
    case "PARTNER_BOOK_READING", "PARTNER_BOOK_REVIEWING":
        return 3
    default:
        return 4
    }
}

// completed=true는 보여주고, 첫 pending 하나는 inProgress로. 나머지 false는 숨김.
// 화면에는 최신 단계가 위로 오도록 역순 표시
private func trackerUiSteps(_ steps: [TrackerStepDTO], dDayChipText: String) -> [TrackerStep] {
    let firstPendingIdx = steps.firstIndex(where: { $0.completed != true })
    var result: [TrackerStep] = []
    for (index, step) in steps.enumerated() {
        if step.completed == true {
            result.append(TrackerStep(
                title: step.title ?? "",
                description: step.description ?? "",
                status: .completed
            ))
        } else if index == firstPendingIdx {
            result.append(TrackerStep(
                title: step.title ?? "",
                description: step.description ?? "",
                status: .inProgress(chipText: dDayChipText)
            ))
        }
    }
    return result.reversed()
}
