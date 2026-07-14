import SwiftUI

// 직접교환 약속 조회 - 등록된 약속 확인 (StepChip 없음).
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDirectMeetingInfoDialog: View {
    let scheduledAt: String
    let address: String
    let addressDetail: String
    let isHost: Bool
    let onDismiss: () -> Void
    let onConfirmClick: () -> Void
    let onEditClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            ReadOnlyField(label: "일시", value: DateUtils.formatKstDateTime(scheduledAt))
            ReadOnlyField(label: "장소", value: placeText)
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var placeText: String {
        addressDetail.isEmpty ? address : "\(address) \(addressDetail)"
    }

    private var isEditable: Bool {
        isHost && DateUtils.isMeetingEditable(scheduledAt)
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("약속을 확인해주세요!")
                .pretendardText(size: 24, weight: .bold)
                .foregroundColor(Color("grey900"))
            Spacer()
            Button(action: onDismiss) {
                Image("ic_x")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("grey100")))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        Group {
            if isEditable {
                HStack(spacing: 8) {
                    CardButton(text: "수정", style: .white, action: onEditClick)
                    CardButton(text: "확인", style: .main, action: onConfirmClick)
                }
            } else {
                CardButton(text: "확인", style: .main, action: onConfirmClick)
            }
        }
    }
}

// MARK: - 읽기전용 필드

private struct ReadOnlyField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
            Text(value)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .frame(height: 48)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TrackerDirectMeetingInfoDialog(
        scheduledAt: "2026-05-20T14:30:00",
        address: "서울특별시 강남구 강남대로 396",
        addressDetail: "2층 창가 자리",
        isHost: true,
        onDismiss: {},
        onConfirmClick: {},
        onEditClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
