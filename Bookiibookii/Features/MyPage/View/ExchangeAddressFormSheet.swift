import SwiftUI

struct ExchangeAddressFormSheet: View {
    let mode: Mode
    @Binding var formState: ExchangeAddressFormState
    @Binding var isSearchPresented: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    let onSelectPlace: (KakaoPlaceResult) -> Void

    enum Mode {
        case add
        case edit

        var title: String {
            switch self {
            case .add: return "희망 교환 장소 추가"
            case .edit: return "희망 교환 장소 수정"
            }
        }
    }

    var body: some View {
        formContent
            .background(Color("white"))
            .fullScreenCover(isPresented: $isSearchPresented) {
                ExchangePlaceSearchOverlay(
                    onClose: { isSearchPresented = false },
                    onSelect: onSelectPlace
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
                        placeholder: "예) 학교 앞 카페, 집 근처 역",
                        text: $formState.placeName
                    )

                    placeSearchField

                    optionalField(
                        title: "상세 안내",
                        placeholder: "예) 정문 앞, 주차장 입구",
                        text: $formState.addressDetail
                    )

                    HStack {
                        Text("대표 희망 교환 장소로 설정")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Spacer()
                        ExchangeMainToggle(isOn: $formState.isDefault)
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

    private var placeSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("장소 검색")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("*")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("main200"))
            }

            Button { isSearchPresented = true } label: {
                HStack(spacing: 8) {
                    Image("ic_search")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("grey500"))

                    Text(
                        formState.searchDisplayText.isEmpty
                            ? "키워드로 장소 검색"
                            : formState.searchDisplayText
                    )
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(formState.searchDisplayText.isEmpty ? Color("grey500") : Color("grey900"))
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
}

private struct ExchangeMainToggle: View {
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
