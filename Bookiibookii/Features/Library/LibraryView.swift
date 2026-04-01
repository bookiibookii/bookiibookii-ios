import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("서재")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("서재")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LibraryView()
}
