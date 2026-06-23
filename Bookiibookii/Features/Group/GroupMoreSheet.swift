import SwiftUI

// UI/point/red (#FF4D4D) — 피그마 디자인 토큰, 에셋 미등록
private let pointRed = Color(red: 1, green: 77 / 255, blue: 77 / 255)

/// 그룹 세부 화면 우상단 ⋯ 버튼 바텀시트.
/// isHost=true → 그룹 관리 (수정/삭제), false → 신고하기
struct GroupMoreSheet: View {
    let isHost: Bool
    let canEdit: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            handleBar

            if isHost {
                hostContent
            } else {
                guestContent
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .presentationDetents([.height(isHost ? (canEdit ? 236 : 196) : 196)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color("white"))
    }

    // MARK: - 핸들바

    private var handleBar: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
            Spacer()
        }
    }

    // MARK: - 호스트 (그룹 관리)

    private var hostContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 관리")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.bottom, 16)

            Divider().background(Color("grey200"))

            VStack(alignment: .leading, spacing: 16) {
                if canEdit {
                    Button {
                        dismiss()
                        onEdit()
                    } label: {
                        Text("그룹 수정")
                            .pretendardText(size: 18)
                            .foregroundColor(Color("grey900"))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    dismiss()
                    onDelete()
                } label: {
                    Text("그룹 삭제")
                        .pretendardText(size: 18)
                        .foregroundColor(pointRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - 게스트 (신고하기)

    private var guestContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 관리")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.bottom, 16)

            Divider().background(Color("grey200"))

            Button {
                dismiss()
                onReport()
            } label: {
                Text("신고하기")
                    .pretendardText(size: 18)
                    .foregroundColor(pointRed)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview("호스트 — 수정 가능") {
    Color.clear.sheet(isPresented: .constant(true)) {
        GroupMoreSheet(isHost: true, canEdit: true, onEdit: {}, onDelete: {}, onReport: {})
    }
}

#Preview("호스트 — 수정 불가") {
    Color.clear.sheet(isPresented: .constant(true)) {
        GroupMoreSheet(isHost: true, canEdit: false, onEdit: {}, onDelete: {}, onReport: {})
    }
}

#Preview("게스트") {
    Color.clear.sheet(isPresented: .constant(true)) {
        GroupMoreSheet(isHost: false, canEdit: false, onEdit: {}, onDelete: {}, onReport: {})
    }
}
