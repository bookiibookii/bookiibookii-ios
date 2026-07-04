import Foundation

// 안드 tracker/model/TrackerMainMapper.kt 대응.

// 제목이 maxChars(공백 포함 글자수)를 넘으면 그만큼 자르고 "..." 부착
func ellipsizeTitle(_ title: String, maxChars: Int) -> String {
    title.count > maxChars ? String(title.prefix(maxChars)) + "..." : title
}

extension TrackerTopBannerResDTO {
    // 상단 배너(topBanners) → 알림 표시 아이템
    func toNotificationItem() -> TrackerNotificationItem {
        TrackerNotificationItem(
            groupId: groupId ?? 0,
            // dDayLabel이 null/빈 값이면 "진행 중"
            dDay: (dDayLabel.map { $0.isEmpty ? "진행 중" : $0 }) ?? "진행 중",
            template: titleTemplate ?? (title ?? ""),
            nickname: partnerNickname ?? "",
            bookTitle: bookTitle ?? "",
            remainingSeconds: remainingSeconds ?? 0,
            subText: subtitle ?? ""
        )
    }
}

extension Optional where Wrapped == BookInfo {
    func toProfile() -> TrackerProfileItem {
        TrackerProfileItem(
            nickname: self?.currentReaderNickname ?? "",
            bookTitle: self?.title ?? "",
            bookCoverUrl: self?.image,
            profileImageUrl: self?.currentReaderProfileImageUrl,
            progressPercent: self?.currentReadingRate ?? 0,
            isOwnerBook: self?.isMyOriginalBook ?? false,
            totalPages: self?.totalPages ?? 0
        )
    }
}

extension TrackerListItemResDTO {
    func toCardModel() -> TrackerCardModel {
        let (primary, secondary) = actionsForStatus(displayStatus)
        var left = myCurrentBook.toProfile()
        left.progressLabelOverride = progressTextOverride(displayStatus, isMine: true)
        var right = partnerCurrentBook.toProfile()
        right.progressLabelOverride = progressTextOverride(displayStatus, isMine: false)
        return TrackerCardModel(
            groupId: groupId,
            groupName: groupName ?? "",
            displayBookTitle: displayBookTitle ?? "",
            bookTitle: myCurrentBook?.title ?? "",
            progressLabel: displayStatusLabel ?? "",
            dDay: "D-\(max(0, remainingDays ?? 0))",
            left: left,
            right: right,
            primaryAction: primary,
            secondaryAction: secondary,
            primaryEnabled: !isPrimaryActionDisabled(displayStatus),
            secondaryEnabled: !isSecondaryActionDisabled(displayStatus),
            showReadingProgress: !isReadingProgressHidden(displayStatus),
            isHost: myRole == "HOST"
        )
    }
}
