import SwiftUI

private let LITERATURE = "문학"
private let NON_LITERATURE = "비문학"
private let ALL = "전체"

private let literatureGenres = ["한국소설","세계소설","장르소설","로맨스","역사소설","시/에세이","희곡/문학","기타"]
private let nonLiteratureGenres = ["경제/경영","과학/IT","인문/역사","가정/취미","예술/문화","자기계발","정치/사회","기타"]
private let literatureCodes = ["KOREAN_NOVEL","WORLD_NOVEL","GENRE_NOVEL","ROMANCE","HISTORICAL_NOVEL","POETRY_ESSAY","PLAY_LITERATURE","LITERATURE_ETC"]
private let nonLiteratureCodes = ["ECONOMY_BUSINESS","SCIENCE_IT","HUMANITIES_HISTORY","HOME_HOBBY","ART_CULTURE","SELF_DEVELOPMENT","POLITICS_SOCIETY","NON_LITERATURE_ETC"]

private let literatureLabelToCode = Dictionary(uniqueKeysWithValues: zip(literatureGenres, literatureCodes))
private let nonLiteratureLabelToCode = Dictionary(uniqueKeysWithValues: zip(nonLiteratureGenres, nonLiteratureCodes))

private func genresOf(_ category: String?) -> [String] {
    switch category {
    case LITERATURE: return literatureGenres
    case NON_LITERATURE: return nonLiteratureGenres
    default: return []
    }
}

// 선택 → 코드 (안드 computeCategories)
private func computeCategories(_ category: String?, _ subs: Set<String>) -> [String] {
    switch category {
    case LITERATURE:
        return subs.isEmpty ? ["LITERATURE_ALL"] : literatureGenres.filter { subs.contains($0) }.map { literatureLabelToCode[$0]! }
    case NON_LITERATURE:
        return subs.isEmpty ? ["NON_LITERATURE_ALL"] : nonLiteratureGenres.filter { subs.contains($0) }.map { nonLiteratureLabelToCode[$0]! }
    default:
        return []
    }
}

// 코드 → 선택 (안드 selectionOf)
private func selectionOf(_ codes: [String]) -> (String?, Set<String>) {
    if codes.isEmpty { return (nil, []) }
    if codes == ["LITERATURE_ALL"] { return (LITERATURE, []) }
    if codes == ["NON_LITERATURE_ALL"] { return (NON_LITERATURE, []) }
    if codes.contains(where: { literatureCodes.contains($0) }) {
        return (LITERATURE, Set(literatureGenres.filter { codes.contains(literatureLabelToCode[$0]!) }))
    }
    if codes.contains(where: { nonLiteratureCodes.contains($0) }) {
        return (NON_LITERATURE, Set(nonLiteratureGenres.filter { codes.contains(nonLiteratureLabelToCode[$0]!) }))
    }
    return (nil, [])
}

// 필터 칩 라벨 (안드 genreChipLabel)
func genreChipLabel(_ categories: [String]) -> String {
    let (category, subs) = selectionOf(categories)
    guard let category else { return "" }
    if subs.isEmpty { return "\(category) 전체" }
    let ordered = genresOf(category).filter { subs.contains($0) }
    guard let first = ordered.first else { return "\(category) 전체" }
    return ordered.count > 1 ? "\(first) 외 \(ordered.count - 1)" : first
}

struct GroupGenreSheet: View {
    let initial: [String]
    let onApply: ([String]) -> Void
    let onCancel: () -> Void

    @State private var selectedCategory: String?
    @State private var selectedSubs: Set<String>

    private let categories = [ALL, LITERATURE, NON_LITERATURE]

    init(initial: [String], onApply: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.onApply = onApply
        self.onCancel = onCancel
        let (c, s) = selectionOf(initial)
        _selectedCategory = State(initialValue: c)
        _selectedSubs = State(initialValue: s)
    }

    private var subGenres: [String] { genresOf(selectedCategory) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            grabber
            HStack(spacing: 8) {
                Text("장르")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Text(headSummary)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("main200"))
                    .lineLimit(1)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(categories.indices, id: \.self) { i in
                        BottomSheetChip(text: categories[i], selected: selectedCategory == categories[i]) {
                            // 시트 높이 변경(확장)을 애니메이션 없이 즉시 전환
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) {
                                selectedCategory = categories[i]
                                selectedSubs = []
                            }
                        }
                        .fixedSize()
                        if i < categories.count - 1 {
                            Rectangle().fill(Color("grey200")).frame(width: 1, height: 32)
                        }
                    }
                    Spacer()
                }
                if !subGenres.isEmpty {
                    GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(subGenres, id: \.self) { g in
                            BottomSheetSubChip(text: g, selected: selectedSubs.contains(g)) {
                                if selectedSubs.contains(g) { selectedSubs.remove(g) } else { selectedSubs.insert(g) }
                            }
                            .fixedSize()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 12) {
                BottomSheetButton(text: "취소", style: .white, action: onCancel)
                BottomSheetButton(text: "적용", style: .dark) {
                    onApply(computeCategories(selectedCategory, selectedSubs))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .presentationDetents([.height(subGenres.isEmpty ? 256 : 388)])
    }

    private var grabber: some View {
        Capsule().fill(Color("grey200")).frame(width: 44, height: 4).frame(maxWidth: .infinity)
    }

    // 안드 headSummary
    private var headSummary: String {
        guard let category = selectedCategory else { return "" }
        if category == ALL || selectedSubs.isEmpty { return category }
        let ordered = subGenres.filter { selectedSubs.contains($0) }
        let body = ordered.count <= 3 ? ordered.joined(separator: " · ")
            : ordered.prefix(3).joined(separator: " · ") + " 외 \(ordered.count - 3)개"
        return "\(category) | \(body)"
    }
}
