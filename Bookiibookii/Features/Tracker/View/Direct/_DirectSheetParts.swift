import SwiftUI

// 직접교환 시트들이 공유하는 부품. 안드 fragment_direct_*.xml 의 반복 카드/폼 요소.

// MARK: - 약속 정보 카드 (datetime + place 한 줄)
//
// 안드 card_appointment 대응 — 직접교환 appointmentEdit / appointmentStatus 시트 공통.
// dateTime 텍스트 색만 host(main200) / guest(sub200)로 다르게 들어옴.

struct AppointmentInfoCard: View {
    let dateTime: String
    let place: String
    let dateTimeColor: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(dateTime)
                .pretendardText(size: 14)
                .foregroundColor(dateTimeColor)
            Text(place)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 약속 등록/수정 폼 다이얼로그 본체
//
// 안드 fragment_direct_*_set_appointment / appointment_edit_dialog 대응.
// "약속 등록" / "약속 수정" 두 케이스에서 텍스트만 바꿔 사용.

struct AppointmentFormDialog: View {
    let title: String                  // "약속 등록" / "약속 수정"
    let actionTitle: String            // "등록하기" / "수정하기"
    @Binding var dateTime: String
    @Binding var place: String
    let onClose: () -> Void
    let onPickDateTime: () -> Void     // 일시 입력 필드 탭 시 외부에서 picker 띄우기
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            label("일시").padding(.top, 24)
            dateTimeField.padding(.top, 8)
            label("장소").padding(.top, 20)
            placeField.padding(.top, 8)
            submitButton.padding(.top, 32)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var header: some View {
        HStack {
            Text(title)
                .pretendardText(size: 20, weight: .medium)
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

    private func label(_ text: String) -> some View {
        Text(text)
            .pretendardText(size: 14)
            .foregroundColor(Color("grey700"))
    }

    /// 안드 et_date 는 clickable=true 라 키보드가 아닌 picker로 입력. iOS도 read-only + onTapGesture.
    private var dateTimeField: some View {
        Button(action: onPickDateTime) {
            HStack {
                Text(dateTime.isEmpty ? " " : dateTime)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey900"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var placeField: some View {
        HStack {
            TextField("", text: $place)
                .pretendardText(size: 15)
                .foregroundColor(Color("grey900"))
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var submitButton: some View {
        Button(action: onSubmit) {
            Text(actionTitle)
                .pretendardText(size: 15)
                .foregroundColor(canSubmit ? Color("white") : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(canSubmit ? Color("grey900") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private var canSubmit: Bool {
        !dateTime.trimmingCharacters(in: .whitespaces).isEmpty
            && !place.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - 약속 일시 picker 시트
//
// AppointmentFormDialog의 dateTime 필드 탭 시 외부에서 띄우는 picker.
// 안드는 별도 DatePickerDialog를 띄움 — iOS는 graphical DatePicker를 sheet로 노출.

struct DateTimePickerSheet: View {
    @Binding var date: Date
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 과거 일시 선택 차단 — 현재 시각 이후만 허용.
            DatePicker(
                "",
                selection: $date,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Button(action: onConfirm) {
                Text("선택")
                    .pretendardText(size: 15, weight: .medium)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 이슈 다이얼로그 (만남/수령 실패)
//
// 안드 fragment_direct_*_meet_issue_dialog / fragment_direct_*_receive_issue_dialog 대응.
// 제목만 "책을 전달하지 못했나요?" / "책을 받지 못했나요?" 로 다름. 본문/버튼 동일.
// 신고하기(grey200) / 약속 다시 잡기(grey900) 두 버튼.

struct DirectIssueDialog: View {
    let title: String
    let onClose: () -> Void
    let onReport: () -> Void
    let onReschedule: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text("상대방과 연락하여 약속을 다시 잡거나, 일방적인\n노쇼라면 신고를 진행해 주세요.")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey700"))
                .padding(.top, 16)
            buttons.padding(.top, 24)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var header: some View {
        HStack {
            Text(title)
                .pretendardText(size: 20, weight: .medium)
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

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onReport) {
                Text("신고하기")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button(action: onReschedule) {
                Text("약속 다시 잡기")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}
