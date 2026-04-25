import SwiftUI

// 안드로이드 item_tracker_none.xml 의 독서율 비교 영역.
// "나의 독서율 N%" / 듀얼 프로그레스(내 채움 + 그룹 평균 마커) / "그룹 평균 독서율 M%"
struct TrackerReadingRateBar: View {
    let myReadingRate: Int          // 0...100
    let groupReadingRate: Int       // 0...100

    private let trackHeight: CGFloat = 8
    private let dotSize: CGFloat = 6
    private let barOvershoot: CGFloat = 4   // 도트 중심에서 바 끝까지 추가 길이
    private let staticMessage = "좋아요! 계속 이대로만 읽어주세요 😊"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(staticMessage)
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            HStack {
                Text("나의 독서율")
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("main200"))
                Spacer()
                Text("\(clampedMy)%")
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("main200"))
            }
            .padding(.top, 4)

            progressTrack
                .padding(.top, 4)

            HStack {
                Text("그룹 평균 독서율")
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Spacer()
                Text("\(clampedGroup)%")
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("grey900"))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            let tw = geo.size.width
            let myW = tw * CGFloat(clampedMy) / 100.0
            let groupW = tw * CGFloat(clampedGroup) / 100.0
            let myBarW = clampedMy > 0 ? min(myW + barOvershoot, tw) : 0
            let groupBarW = clampedGroup > 0 ? min(groupW + barOvershoot, tw) : 0
            let myAhead = clampedMy >= clampedGroup

            ZStack(alignment: .leading) {
                // 배경 트랙
                Capsule()
                    .fill(Color("grey200"))
                    .frame(height: trackHeight)

                // 더 진행률 높은 쪽이 뒤(z-order 아래)로 가도록 분기
                if myAhead {
                    // 내가 앞 → 내 채움(orange)이 뒤, 그룹(grey900)이 위
                    Capsule()
                        .fill(Color("main200"))
                        .frame(width: myBarW, height: trackHeight)
                    Capsule()
                        .fill(Color("grey900"))
                        .frame(width: groupBarW, height: trackHeight)
                } else {
                    // 그룹이 앞 → 그룹(grey900)이 뒤, 내 채움(orange)이 위
                    Capsule()
                        .fill(Color("grey900"))
                        .frame(width: groupBarW, height: trackHeight)
                    Capsule()
                        .fill(Color("main200"))
                        .frame(width: myBarW, height: trackHeight)
                }

                // 내 도트 — 바 끝보다 4pt 안쪽에 위치
                // 시작 부분(rate 매우 작을 때) 트랙 라운드 캡에 잘리지 않게 최소 x 보정
                Circle()
                    .fill(Color("grey100"))
                    .frame(width: dotSize, height: dotSize)
                    .position(x: max(5, min(myW, tw)), y: trackHeight / 2)

                // 그룹 평균 도트 — 바 끝보다 4pt 안쪽에 위치
                Circle()
                    .fill(Color("grey100"))
                    .frame(width: dotSize, height: dotSize)
                    .position(x: max(4, min(groupW, tw)), y: trackHeight / 2)
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
    }

    private var clampedMy: Int { max(0, min(myReadingRate, 100)) }
    private var clampedGroup: Int { max(0, min(groupReadingRate, 100)) }
}

#Preview("내가 앞") {
    TrackerReadingRateBar(myReadingRate: 79, groupReadingRate: 53)
        .padding(.vertical, 16)
        .background(Color("white"))
}

#Preview("그룹이 앞") {
    TrackerReadingRateBar(myReadingRate: 32, groupReadingRate: 68)
        .padding(.vertical, 16)
        .background(Color("white"))
}
