import SwiftUI

struct KakaoPlaceSearchView: View {
    @StateObject private var viewModel = KakaoPlaceSearchViewModel()

    let onSelect: (KakaoPlaceResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider().overlay(Color("grey200"))

            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let message = viewModel.errorMessage {
                    Text(message)
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey600"))
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.results.isEmpty, !viewModel.query.isEmpty {
                    Text("검색 결과가 없습니다.")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey600"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.results) { place in
                                Button {
                                    onSelect(place)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.placeName)
                                            .pretendardText(size: 16, weight: .medium)
                                            .foregroundColor(Color("grey900"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(place.address)
                                            .pretendardText(size: 14, weight: .regular)
                                            .foregroundColor(Color("grey600"))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                Divider().overlay(Color("grey100"))
                            }
                        }
                    }
                }
            }
        }
        .background(Color("white"))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Button { Task { await viewModel.search() } } label: {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey500"))
            }
            .buttonStyle(.plain)

            TextField("", text: $viewModel.query, prompt: Text("키워드로 장소 검색")
                .font(.pretendard(size: 15))
                .foregroundColor(Color("grey500")))
            .font(.pretendard(size: 15))
            .foregroundColor(Color("grey900"))
            .submitLabel(.search)
            .onSubmit { Task { await viewModel.search() } }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                    viewModel.results = []
                    viewModel.errorMessage = nil
                } label: {
                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color("grey500"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("grey300"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@MainActor
private final class KakaoPlaceSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [KakaoPlaceResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let searchService = KakaoLocalSearchService()

    func search() async {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            results = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            results = try await searchService.searchByKeyword(query: keyword)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
    }
}
