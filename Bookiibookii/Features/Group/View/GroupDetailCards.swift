import SwiftUI

// 그룹 상세: 책정보 + 교환뱃지 / 소개·규칙 카드 + 점선 구분선 / 참여 멤버 카드
// 안드 GroupDetailScreen.kt(582-908) 대응

// MARK: - 책 정보

// 안드 GroupDetailBookInfo(582-695) 대응
struct GroupDetailBookInfo: View {
    let detail: GroupDetailDto

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            BookCover(imageUrl: detail.bookImage)
                .frame(width: 72, height: 100)

            VStack(alignment: .leading, spacing: 0) {
                topBlock
                Spacer(minLength: 0)
                bottomBlock
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var topBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                GroupDetailExchangeBadge(text: exchangeTypeLabel)
                Text(detail.title.stripBookSubtitle())
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Text("\(detail.author)(\(detail.genre))")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Text("독서 기간")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
                Text("\(detail.readingPeriod)")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey800"))
                Text("일")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
            }
            HStack(spacing: 4) {
                ProfilePlaceholder(imageUrl: detail.hostProfileImageUrl, size: 20)
                Text(detail.hostNickname)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey700"))
                Text("·")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey700"))
                Text(detail.groupName)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    // 안드 tradeTypeLabel(tradeType) 대응
    private var exchangeTypeLabel: String {
        switch detail.tradeType {
        case "DIRECT": return "직접"
        case "DELIVERY": return "택배"
        default: return ""
        }
    }
}

// 카드 내부 교환 방식 라벨 배지 (안드 GroupDetailExchangeBadge)
private struct GroupDetailExchangeBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("main100")))
    }
}

// MARK: - 소개 / 규칙 카드

// 안드 GroupDetailDescriptionCard(699-786) 대응
struct GroupDetailDescriptionCard: View {
    let title: String
    let body_: String
    var exchangePlaceName: String? = nil
    var exchangePlaceAddress: String? = nil
    var exchangePlaceLabel: String = "교환 희망 장소"

    init(
        title: String,
        body: String,
        exchangePlaceName: String? = nil,
        exchangePlaceAddress: String? = nil,
        exchangePlaceLabel: String = "교환 희망 장소"
    ) {
        self.title = title
        self.body_ = body
        self.exchangePlaceName = exchangePlaceName
        self.exchangePlaceAddress = exchangePlaceAddress
        self.exchangePlaceLabel = exchangePlaceLabel
    }

    private var hasBody: Bool { !body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .padding(.bottom, 12)
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)
            }

            if hasBody {
                Text(body_)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey700"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let exchangePlaceName {
                VStack(alignment: .leading, spacing: 0) {
                    if hasBody {
                        DashedDivider(color: Color("grey100"))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exchangePlaceLabel)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                            .padding(.horizontal, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color("grey100")))
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(exchangePlaceName)
                                .pretendardText(size: 15)
                                .foregroundColor(Color("grey600"))
                                .underline()
                                .onTapGesture { openInKakaoMap(exchangePlaceName) }
                            if let exchangePlaceAddress {
                                Text(exchangePlaceAddress)
                                    .pretendardText(size: 12)
                                    .foregroundColor(Color("grey400"))
                            }
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.top, hasBody ? 12 : 0)
                }
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // 안드: Uri.encode(exchangePlaceName)를 카카오맵 검색 링크에 붙여 인텐트로 오픈
    private func openInKakaoMap(_ placeName: String) {
        let encoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        guard let url = URL(string: "https://map.kakao.com/link/search/\(encoded)") else { return }
        UIApplication.shared.open(url)
    }
}

// 점선 구분선 (안드 DashedDivider, Canvas dashPathEffect(8,6) 대응)
struct DashedDivider: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
        }
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 참여 멤버 카드

// 안드 GroupDetailMembersCard(813-846) 대응
struct GroupDetailMembersCard: View {
    let matchedCount: Int
    let maxCapacity: Int
    let slots: [ParticipantSlot]
    var onProfileTap: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("참여 멤버")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                    Text("\(matchedCount)/\(maxCapacity) 명")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("main200"))
                }
                .padding(.bottom, 12)
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                    ParticipantSlotRow(slot: slot, onProfileTap: onProfileTap)
                }
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// 슬롯 한 줄 (HOST / GUEST / EMPTY) — 안드 ParticipantSlotRow
private struct ParticipantSlotRow: View {
    let slot: ParticipantSlot
    var onProfileTap: ((String) -> Void)?

    var body: some View {
        let content = HStack(spacing: 12) {
            ProfilePlaceholder(imageUrl: slot.profileImageUrl, size: 40)

            switch slot.role {
            case "HOST":
                HStack(spacing: 8) {
                    Text(slot.nickname ?? "")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                    GroupDetailHostChip()
                }
            case "EMPTY":
                Text("모집 중")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey600"))
            default:
                Text(slot.nickname ?? "")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
            }
        }

        if let nickname = slot.nickname, slot.role != "EMPTY", let onProfileTap {
            Button { onProfileTap(nickname) } label: { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// 안드 GroupDetailHostChip
private struct GroupDetailHostChip: View {
    var body: some View {
        Text("HOST")
            .pretendardText(size: 11)
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("main100")))
    }
}
