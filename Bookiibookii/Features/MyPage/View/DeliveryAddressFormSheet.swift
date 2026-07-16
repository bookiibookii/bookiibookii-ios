import SwiftUI

struct DeliveryAddressFormSheet: View {
    let mode: Mode
    @Binding var formState: DeliveryAddressFormState
    @Binding var isSearchPresented: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    let onSelectAddress: (DaumPostcodeResult) -> Void

    enum Mode {
        case add
        case edit

        var title: String {
            switch self {
            case .add: return "배송지 추가"
            case .edit: return "배송지 수정"
            }
        }
    }

    var body: some View {
        formContent
            .background(Color("white"))
            .fullScreenCover(isPresented: $isSearchPresented) {
                AddressSearchOverlay(
                    title: "주소 검색",
                    onClose: { isSearchPresented = false },
                    onSelect: onSelectAddress
                )
            }
    }

    private var formContent: some View {
        VStack(spacing: 0) {
            sheetHandle
                .padding(.top, 8)

            Text(mode.title)
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    optionalField(
                        title: "별명",
                        placeholder: "예) 집, 학교, 회사",
                        text: $formState.placeName
                    )

                    addressSearchField

                    optionalField(
                        title: "상세 주소",
                        placeholder: "상세 주소를 입력해주세요",
                        text: $formState.addressDetail
                    )

                    requiredField(
                        title: "수령인",
                        placeholder: "수령인을 입력해주세요",
                        text: $formState.receiverName
                    )

                    phoneField

                    HStack {
                        Text("대표 배송지로 설정")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Spacer()
                        MainToggle(isOn: $formState.isDefault)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("취소")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("white"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color("grey200"), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                Button(action: onSave) {
                    Group {
                        if isSaving {
                            ProgressView().tint(Color("white"))
                        } else {
                            Text("저장")
                                .pretendardText(size: 16, weight: .regular)
                                .foregroundColor(formState.canSubmit ? Color("white") : Color("grey500"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(formState.canSubmit ? Color("grey900") : Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .disabled(!formState.canSubmit || isSaving)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var sheetHandle: some View {
        RoundedRectangle(cornerRadius: 300)
            .fill(Color("grey200"))
            .frame(width: 44, height: 4)
    }

    private var addressSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel("주소 검색")

            Button { isSearchPresented = true } label: {
                HStack(spacing: 8) {
                    Image("ic_search")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("grey500"))

                    Text(
                        formState.address.isEmpty
                            ? "지번, 도로명, 건물명으로 검색"
                            : formState.address
                    )
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(formState.address.isEmpty ? Color("grey500") : Color("grey900"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("grey300"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private func optionalField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("(선택)")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey400"))
            }

            textField(placeholder: placeholder, text: text)
        }
    }

    private func requiredField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel(title)
            textField(placeholder: placeholder, text: text)
        }
    }

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel("전화번호")
            TextField("", text: Binding(
                get: { formState.phone },
                set: { formState.updatePhone($0) }
            ), prompt: Text("전화번호를 입력해주세요")
                .font(.pretendard(size: 15))
                .foregroundColor(Color("grey500")))
            .font(.pretendard(size: 15))
            .foregroundColor(Color("grey900"))
            .keyboardType(.numberPad)
            .padding(16)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("grey300"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
            Text("*")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("main200"))
        }
    }

    private func textField(placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder)
            .font(.pretendard(size: 15))
            .foregroundColor(Color("grey500")))
        .font(.pretendard(size: 15))
        .foregroundColor(Color("grey900"))
        .padding(16)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("grey300"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MainToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color("main200") : Color("grey300"))
                    .frame(width: 44, height: 24)
                Circle()
                    .fill(Color("white"))
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
    }
}
