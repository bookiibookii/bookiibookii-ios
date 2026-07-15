import SwiftUI

// 운송장 등록 다이얼로그. 택배사 선택 + 운송장 번호 입력.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryTrackingNumberDialog: View {
    let onDismiss: () -> Void
    let onConfirm: (_ deliveryCompany: String, _ trackingNumber: String) -> Void

    @State private var selectedCompany: DeliveryCompany?
    @State private var trackingInput: String = ""

    private var canSubmit: Bool {
        selectedCompany != nil && trackingInput.count >= 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            DeliveryCompanyField(selected: selectedCompany, onSelect: { selectedCompany = $0 })
                // 드롭다운 overlay가 아래 필드/버튼보다 앞에 그려지도록
                .zIndex(1)
            TrackingNumberField(
                value: $trackingInput,
                onChange: { newValue in trackingInput = newValue.filter { $0.isNumber } }
            )
            submitButton
        }
        .padding(20)
        // 드롭다운이 카드 밖으로 떠도 잘리지 않도록 clip 대신 배경만 라운드 처리
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color("white")))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("운송장 등록")
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

    // MARK: - 완료 버튼

    private var submitButton: some View {
        CardButton(
            text: "완료",
            style: canSubmit ? .main : .grey,
            height: 56,
            corner: 20,
            action: {
                guard let selectedCompany else { return }
                onConfirm(selectedCompany.apiValue, trackingInput)
                onDismiss()
            }
        )
        .disabled(!canSubmit)
    }
}

private struct RequiredLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
            Text("*")
                .pretendardText(size: 14)
                .foregroundColor(Color("main200"))
        }
    }
}

private struct DeliveryCompanyField: View {
    let selected: DeliveryCompany?
    let onSelect: (DeliveryCompany) -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RequiredLabel(text: "택배사")

            Button(action: { expanded.toggle() }) {
                HStack(spacing: 8) {
                    Text(selected?.label ?? "택배사를 선택해주세요")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(selected == nil ? Color("grey500") : Color("grey900"))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("ic_chevron")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey500"))
                        .rotationEffect(.degrees(-90))
                }
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey100")))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
            }
            .buttonStyle(.plain)
            // 드롭다운은 레이아웃에 영향 주지 않는 overlay로 띄운다(다이얼로그가 커지지 않도록).
            .overlay(alignment: .top) {
                if expanded {
                    dropdownList
                        .offset(y: 52)
                        .zIndex(1)
                }
            }
        }
    }

    private var dropdownList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(DeliveryCompany.allCases.enumerated()), id: \.element.id) { index, company in
                Button(action: {
                    onSelect(company)
                    expanded = false
                }) {
                    Text(company.label)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 44)
                        .overlay(alignment: .bottom) {
                            if index < DeliveryCompany.allCases.count - 1 {
                                Rectangle().fill(Color("grey100")).frame(height: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color("white")))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color("grey200"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 0)
    }
}

private struct TrackingNumberField: View {
    @Binding var value: String
    let onChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RequiredLabel(text: "운송장 번호")

            ZStack(alignment: .leading) {
                if value.isEmpty {
                    Text("숫자만 입력해주세요")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey500"))
                }
                TextField("", text: $value)
                    .keyboardType(.numberPad)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
                    .onChange(of: value) { _, newValue in onChange(newValue) }
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .frame(height: 48)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    TrackerDeliveryTrackingNumberDialog(
        onDismiss: {},
        onConfirm: { _, _ in }
    )
    .padding(24)
    .background(Color("uiBg"))
}
