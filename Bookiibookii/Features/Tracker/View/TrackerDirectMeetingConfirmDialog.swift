import SwiftUI

// 직접교환 약속 잡기 3/3 - 약속 확인 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDirectMeetingConfirmDialog: View {
    let scheduledAt: String
    let address: String
    let addressDetail: String
    let onDismiss: () -> Void
    let onConfirmClick: () -> Void

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

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                StepChip(text: "3/3")
                Text("약속을 확인해주세요!")
                    .pretendardText(size: 24, weight: .bold)
                    .foregroundColor(Color("grey900"))
            }
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
        HStack(spacing: 8) {
            CardButton(text: "이전", style: .grey, action: onDismiss)
            CardButton(text: "등록", style: .main, action: onConfirmClick)
        }
    }
}

// MARK: - StepChip

private struct StepChip: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 14, weight: .medium)
            .foregroundColor(Color("grey900"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("white"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("grey200"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
    TrackerDirectMeetingConfirmDialog(
        scheduledAt: "2026-05-20T14:30:00",
        address: "서울특별시 강남구 강남대로 396",
        addressDetail: "2층 창가 자리",
        onDismiss: {},
        onConfirmClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
