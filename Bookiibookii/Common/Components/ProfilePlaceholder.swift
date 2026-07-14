import SwiftUI
import Kingfisher

// 안드 profile_bg.xml (44×44 viewport) squircle path 이식. rect 크기에 스케일.
struct ProfileSquircle: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 44
        let sy = rect.height / 44
        func pt(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + px * sx, y: rect.minY + py * sy)
        }
        var p = Path()
        p.move(to: pt(0, 22))
        p.addCurve(to: pt(22, 0), control1: pt(0, 3.883), control2: pt(3.883, 0))
        p.addCurve(to: pt(44, 22), control1: pt(40.117, 0), control2: pt(44, 3.883))
        p.addCurve(to: pt(22, 44), control1: pt(44, 40.117), control2: pt(40.117, 44))
        p.addCurve(to: pt(0, 22), control1: pt(3.883, 44), control2: pt(0, 40.117))
        p.closeSubpath()
        return p
    }
}

// 안드 ProfilePlaceholder 대응.
// - imageUrl 없음/blank → ic_profile_placeholder (grey300 squircle + 실루엣)
// - imageUrl 있음 → 위에 이미지 오버레이
// - innerStroke → 안쪽 1dp grey100 stroke. 책 표지와 겹칠 때만 true.
struct ProfilePlaceholder: View {
    let imageUrl: String?
    let size: CGFloat
    var innerStroke: Bool = false

    init(imageUrl: String? = nil, size: CGFloat, innerStroke: Bool = false) {
        self.imageUrl = imageUrl
        self.size = size
        self.innerStroke = innerStroke
    }

    var body: some View {
        ZStack {
            Image("ic_profile_placeholder")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
            if let imageUrl, !imageUrl.isEmpty {
                KFImage(URL(string: imageUrl))
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(ProfileSquircle())
        .overlay {
            if innerStroke {
                ProfileSquircle().stroke(Color("grey100"), lineWidth: 1)
            }
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        ProfilePlaceholder(size: 20)
        ProfilePlaceholder(size: 40)
        ProfilePlaceholder(size: 44, innerStroke: true)
        ProfilePlaceholder(size: 48)
    }
    .padding()
    .background(Color("grey100"))
}
#endif
