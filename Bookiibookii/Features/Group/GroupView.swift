import SwiftUI

// 안드로이드 GroupFragment 대응 (구현 예정)
struct GroupView: View {
    var body: some View {
        VStack {
            Text("그룹")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
    }
}

#Preview {
    GroupView()
}
