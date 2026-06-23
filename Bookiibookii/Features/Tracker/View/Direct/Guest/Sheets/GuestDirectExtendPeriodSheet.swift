import SwiftUI

// 안드 fragment_direct_guest_extend_period_dialog.xml (DirectGuestExtendPeriodDialogFragment) 대응.
// 게스트 본인 독서 기간 연장 신청 다이얼로그. 일수 1~7 입력.
struct GuestDirectExtendPeriodSheet: View {
    @Binding var days: String
    let originalEndDate: String
    let extendedEndDate: String
    let onClose: () -> Void
    let onCancel: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text("1회에 한하여 최대 7일까지 독서 기간을 연장할 수 있어요.")
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey500"))
                .padding(.top, 4)
            daysField.padding(.top, 20)
            datesBox.padding(.top, 12)
            buttons.padding(.top, 20)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var header: some View {
        HStack {
            Text("독서 기간 연장 신청")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()
            Button(action: onClose) {
                Image("ic_x")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var daysField: some View {
        HStack(spacing: 0) {
            TextField("", text: $days)
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey900"))
                .keyboardType(.numberPad)
                .onChange(of: days) { _, newValue in
                    let filtered = newValue.filter { "1234567".contains($0) }
                    days = String(filtered.prefix(1))
                }
            Text("일")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey600"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var datesBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("기존 예정 종료일 |").foregroundColor(Color("grey700"))
                Text(originalEndDate).foregroundColor(Color("grey700"))
            }
            HStack(spacing: 6) {
                Text("연장 후 예정 종료일").foregroundColor(Color("grey700"))
                Text(extendedEndDate).foregroundColor(Color("grey900"))
            }
        }
        .font(.pretendard(size: 14))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("취소")
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(Color("grey700"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button(action: onApply) {
                Text("신청하기")
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(canApply ? Color("white") : Color("grey500"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canApply ? Color("grey900") : Color("grey100"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(!canApply)
        }
    }

    private var canApply: Bool {
        Int(days).flatMap { (1...7).contains($0) ? $0 : nil } != nil
    }
}

#Preview("GuestDirectExtendPeriod") {
    GuestDirectExtendPeriodPreview()
}

private struct GuestDirectExtendPeriodPreview: View {
    @State var days = ""
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            GuestDirectExtendPeriodSheet(
                days: $days,
                originalEndDate: "2025.12.25.",
                extendedEndDate: "2025.12.25.",
                onClose: {},
                onCancel: {},
                onApply: {}
            )
            .padding(20)
        }
    }
}
