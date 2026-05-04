import SwiftUI

// 안드 fragment_*_bottom_dialog.xml에서 반복되는 카드/요소들의 SwiftUI 부품.
// 호스트/게스트 양쪽 시트에서 import 없이 같은 모듈에서 사용.

// MARK: - Drag handle

struct SheetGrabber: View {
    var body: some View {
        Capsule()
            .fill(Color("grey200"))
            .frame(width: 40, height: 4)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - 예정 독서 기간 카드 (회색 박스 안에 시작일 ~ 종료일)

struct ReadingPeriodCard: View {
    enum Style {
        /// "예정 독서 기간 " + start(grey500)  — Start 시트
        case start
        /// "예정 독서 기간 | " + start(grey900) — Reading/ReadingStatus 시트
        case ongoing
    }

    let style: Style
    let startDate: String
    let endDate: String
    /// 호스트는 main200(주황), 게스트는 sub200(파랑). 기본값 main200.
    var endColor: Color = Color("main200")

    var body: some View {
        HStack(spacing: 0) {
            Text(prefix)
                .foregroundColor(Color("grey900"))
            Text("\(startDate) ")
                .foregroundColor(startColor)
            Text("~ ")
                .foregroundColor(Color("main200"))
            Text(endDate)
                .foregroundColor(endColor)
            Spacer(minLength: 0)
        }
        .font(.pretendard(size: 14))
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var prefix: String {
        switch style {
        case .start:   return "예정 독서 기간 "
        case .ongoing: return "예정 독서 기간 | "
        }
    }

    private var startColor: Color {
        switch style {
        case .start:   return Color("grey500")
        case .ongoing: return Color("grey900")
        }
    }
}

// MARK: - 정보 알림 카드 (연두 배경 + info 아이콘 + 메시지)

struct InfoBannerCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("ic_info")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(InfoBannerCard.green200)
                .frame(width: 20, height: 20)
            Text(message)
                .font(.pretendard(size: 14))
                .foregroundColor(InfoBannerCard.green200)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(InfoBannerCard.greenPale)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(InfoBannerCard.green150, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    static let greenPale = Color(red: 0xE7/255, green: 0xFF/255, blue: 0xEA/255)
    static let green150  = Color(red: 0x74/255, green: 0xD2/255, blue: 0x7F/255)
    static let green200  = Color(red: 0x3C/255, green: 0xCF/255, blue: 0x4D/255)
}

// MARK: - 시트 1차 버튼 (검은 배경)

struct PrimarySheetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 15))
                .foregroundColor(Color("grey100"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 시트 2차 버튼 (외곽선)

struct OutlineSheetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 15))
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 시트 컨테이너 (안드 fragment_*_bottom_dialog.xml 외곽 LinearLayout 대응)
//
// 안드로이드: padding=24dp + background=white + 상단 라운드 24dp.
// iOS: 시트 본체 자체에 background/cornerRadius를 .presentationBackground / .presentationCornerRadius로 적용하므로
// 여기서는 라운드/배경을 그리지 않는다. (그렸을 경우 시트 본체 라운드와 어긋난 카드처럼 보임)
struct SheetContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber()
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

