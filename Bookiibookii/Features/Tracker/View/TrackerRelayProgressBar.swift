import SwiftUI
import Kingfisher

// 안드로이드 item_trk.xml 의 4단계 진행도 영역.
// host: 읽는 중 → 배송 중 → 게스트 읽는 중 → 회수 중
// guest: 호스트 읽는 중 → 배송 중 → 읽는 중 → 회수 중
struct TrackerRelayProgressBar: View {
    let role: ExchangeRole
    let currentStep: Int            // 0...3
    let stepDates: [String?]
    let hostProfileUrl: String?
    let guestProfileUrl: String?

    // 안드로이드 item_trk.xml 마진 그대로
    private let trackHorizontalInset: CGFloat = 16   // 카드 → 트랙
    private let dotInsetFromTrack: CGFloat = 20      // 트랙 → 첫/끝 도트
    private let dotSize: CGFloat = 6
    private let trackHeight: CGFloat = 8
    private let profileSize: CGFloat = 16
    private let profileCornerRadius: CGFloat = 6     // 그룹 프로필 8/20(=0.4)과 동일 비율
    private let barOvershoot: CGFloat = 4            // 현재 단계 도트 중심에서 바 끝까지 추가 길이

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            profileRow
            labelRow
                .padding(.top, 4)
            trackBar
                .padding(.top, 4)
            dateRow
                .padding(.top, 4)
        }
        .padding(.horizontal, trackHorizontalInset)
    }

    // MARK: - 프로필 (현재 단계 도트 위에 띄움)

    private var profileRow: some View {
        GeometryReader { geo in
            let centers = dotCenters(in: geo.size.width)
            let url = profileUrlForCurrentStep()
            ZStack(alignment: .topLeading) {
                profileImage(urlString: url)
                    .position(
                        x: centers[clampedStep],
                        y: profileSize / 2
                    )
            }
        }
        .frame(height: profileSize)
    }

    @ViewBuilder
    private func profileImage(urlString: String?) -> some View {
        if let s = urlString, let url = URL(string: s) {
            KFImage(url)
                .placeholder { defaultProfile }
                .retry(maxCount: 1)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .frame(width: profileSize, height: profileSize)
                .clipShape(RoundedRectangle(cornerRadius: profileCornerRadius))
        } else {
            defaultProfile
        }
    }

    private var defaultProfile: some View {
        Image("img_profile_default")
            .resizable()
            .scaledToFill()
            .frame(width: profileSize, height: profileSize)
            .clipShape(RoundedRectangle(cornerRadius: profileCornerRadius))
    }

    // MARK: - 트랙 + 활성 채움 + 4도트

    private var trackBar: some View {
        GeometryReader { geo in
            let tw = geo.size.width
            let centers = dotCenters(in: tw)
            ZStack(alignment: .leading) {
                // 배경 트랙
                Capsule()
                    .fill(Color("grey200"))
                    .frame(height: trackHeight)

                // 활성 채움 (현재 도트의 중심에서 +4pt까지 → 도트가 바 끝 안쪽)
                if clampedStep > 0 {
                    Capsule()
                        .fill(Color("grey900"))
                        .frame(width: min(centers[clampedStep] + barOvershoot, tw), height: trackHeight)
                }

                // 도트 4개 (모두 grey100 — 안드로이드 bg_circle_grey100 매칭)
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color("grey100"))
                        .frame(width: dotSize, height: dotSize)
                        .position(x: centers[i], y: trackHeight / 2)
                }
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
    }

    // MARK: - 라벨 (4개)

    private var labelRow: some View {
        GeometryReader { geo in
            let centers = dotCenters(in: geo.size.width)
            let labels = stepLabels(role: role)
            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { i in
                    Text(labels[i])
                        .font(.pretendard(size: 11, weight: .medium))
                        .foregroundColor(i == clampedStep ? Color("main200") : Color("grey400"))
                        .fixedSize()
                        .position(x: centers[i], y: 7)
                }
            }
        }
        .frame(height: 14)
    }

    // MARK: - 날짜 (4개, 빈 값은 빈 텍스트)

    private var dateRow: some View {
        GeometryReader { geo in
            let centers = dotCenters(in: geo.size.width)
            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { i in
                    Text(formatStepDate(stepDates.indices.contains(i) ? stepDates[i] : nil))
                        .font(.pretendard(size: 11, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .fixedSize()
                        .position(x: centers[i], y: 7)
                }
            }
        }
        .frame(height: 14)
    }

    // MARK: - 계산

    /// 트랙 폭 안에서 4 도트의 중심 x 좌표.
    /// 첫 도트는 leading inset(20) + dotSize/2 만큼 안쪽,
    /// 마지막 도트는 trailing inset(20) + dotSize/2 만큼 안쪽,
    /// 중간 두 도트는 등간격.
    private func dotCenters(in trackWidth: CGFloat) -> [CGFloat] {
        let firstX = dotInsetFromTrack + dotSize / 2
        let lastX = trackWidth - dotInsetFromTrack - dotSize / 2
        let safeFirst = min(firstX, lastX)
        let gap = (lastX - safeFirst) / 3
        return (0..<4).map { safeFirst + CGFloat($0) * gap }
    }

    private var clampedStep: Int { max(0, min(currentStep, 3)) }

    private func profileUrlForCurrentStep() -> String? {
        // 안드로이드 bindStepProfiles: step 0~1 → 호스트, 2~3 → 게스트
        switch clampedStep {
        case 0, 1: return hostProfileUrl
        default:   return guestProfileUrl
        }
    }

    private func stepLabels(role: ExchangeRole) -> [String] {
        switch role {
        case .host:
            return ["읽는 중", "배송 중", "게스트 읽는 중", "회수 중"]
        case .guest:
            return ["호스트 읽는 중", "배송 중", "읽는 중", "회수 중"]
        }
    }

    private func formatStepDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        let datePart = String(raw.prefix(10))
        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "yyyy-MM-dd"
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = inFormatter.date(from: datePart) else { return raw }
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "M. d."
        outFormatter.locale = Locale(identifier: "en_US_POSIX")
        return outFormatter.string(from: date)
    }
}

#Preview("Host - 진행 중 (배송)") {
    TrackerRelayProgressBar(
        role: .host,
        currentStep: 1,
        stepDates: ["2024-12-16", "2024-12-20", nil, nil],
        hostProfileUrl: nil,
        guestProfileUrl: nil
    )
    .padding(.vertical, 16)
    .background(Color("white"))
}

#Preview("Guest - 게스트 읽는 중") {
    TrackerRelayProgressBar(
        role: .guest,
        currentStep: 2,
        stepDates: ["2024-12-16", "2024-12-20", "2024-12-23", nil],
        hostProfileUrl: nil,
        guestProfileUrl: nil
    )
    .padding(.vertical, 16)
    .background(Color("white"))
}
