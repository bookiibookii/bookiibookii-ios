import SwiftUI
import UIKit

// 안드 fragment_guest_shipping_input_dialog.xml (GuestShippingInputDialogFragment) 대응.
// 회수 운송장 입력 다이얼.
struct GuestShippingInputSheet: View {
    @Binding var courier: String
    @Binding var trackingNumber: String
    let courierOptions: [String]
    let pickedImage: UIImage?
    let onClose: () -> Void
    let onPickImage: () -> Void
    let onRegister: () -> Void

    @State private var isDropdownOpen: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            label("택배사 *").padding(.top, 24)
            courierField.padding(.top, 6)
            label("운송장 번호 *").padding(.top, 20)
            trackingField.padding(.top, 8)
            label("배송 인증 사진 *").padding(.top, 20)
            photoField.padding(.top, 8)

            Button(action: onRegister) {
                Text("등록하기")
                    .font(.pretendard(size: 15))
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlayPreferenceValue(CourierFieldBoundsKey.self) { anchor in
            GeometryReader { geo in
                if isDropdownOpen, let anchor = anchor {
                    let rect = geo[anchor]
                    courierDropdown
                        .frame(width: rect.width)
                        .offset(x: rect.minX, y: rect.maxY + 4)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("배송 정보 입력")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()
            Button(action: onClose) {
                Image("ic_fab_close")
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
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey700"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var courierField: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isDropdownOpen.toggle() } }) {
            HStack {
                Text(courier.isEmpty ? "택배사 선택" : courier)
                    .font(.pretendard(size: 14))
                    .foregroundColor(courier.isEmpty ? Color("grey500") : Color("grey800"))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color("grey500"))
                    .rotationEffect(.degrees(isDropdownOpen ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .anchorPreference(key: CourierFieldBoundsKey.self, value: .bounds) { $0 }
    }

    private var courierDropdown: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(courierOptions, id: \.self) { option in
                    Button {
                        courier = option
                        withAnimation(.easeInOut(duration: 0.15)) { isDropdownOpen = false }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.pretendard(size: 14))
                                .foregroundColor(Color("grey800"))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 240)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var trackingField: some View {
        TextField("", text: $trackingNumber)
            .font(.pretendard(size: 15))
            .foregroundColor(Color("grey800"))
            .keyboardType(.numberPad)
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

    private var photoField: some View {
        Button(action: onPickImage) {
            ZStack {
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 8) {
                        Image("ic_upload")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color("grey800"))
                            .frame(width: 32, height: 32)
                        Text("배송 인증 사진을 업로드해주세요")
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey800"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(Color("grey100"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// 시트 내부 좌표계에서 택배사 필드 위치를 잡기 위한 anchor preference.
private struct CourierFieldBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

#Preview("GuestShippingInput") {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State var courier = ""
    @State var tracking = ""
    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()
            GuestShippingInputSheet(
                courier: $courier,
                trackingNumber: $tracking,
                courierOptions: CourierOptions.all,
                pickedImage: nil,
                onClose: {},
                onPickImage: {},
                onRegister: {}
            )
            .padding(20)
        }
    }
}
