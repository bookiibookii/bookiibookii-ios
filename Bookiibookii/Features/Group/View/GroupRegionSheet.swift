import SwiftUI

// 지역 필터 바텀시트 (안드 RegionBottomSheet)
struct GroupRegionSheet: View {
    let initial: [String]
    let onApply: ([String]) -> Void
    let onCancel: () -> Void

    @State private var selectedRegion: String
    @State private var selectedDistricts: Set<String>

    init(initial: [String], onApply: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.onApply = onApply
        self.onCancel = onCancel
        let (r, d) = GroupRegionData.fromTokens(initial)
        _selectedRegion = State(initialValue: r)
        _selectedDistricts = State(initialValue: d)
    }

    private var currentCity: GroupRegionData.City? {
        GroupRegionData.cities.first(where: { $0.name == selectedRegion })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            grabber
            HStack(spacing: 8) {
                Text("지역")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Text(headSummary)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("main200"))
                    .lineLimit(1)
            }
            .padding(.bottom, 12)

            HStack(alignment: .top, spacing: 16) {
                // 좌: 시/도 — 각 행 우측에 구분선(선택 행은 main200 강조)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        regionItem(GroupRegionData.nationwide) {
                            selectedRegion = GroupRegionData.nationwide
                        }
                        ForEach(GroupRegionData.cities) { city in
                            regionItem(city.name) {
                                selectedRegion = city.name
                                selectedDistricts = [GroupRegionData.all]
                            }
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)

                // 우: 구/군 — 내용 크기 칩, 줄바꿈(말줄임 없음)
                ScrollView(showsIndicators: false) {
                    if let city = currentCity {
                        GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(city.districts, id: \.self) { d in
                                BottomSheetChip(text: d, selected: selectedDistricts.contains(d)) {
                                    selectedDistricts = GroupRegionData.toggle(selectedDistricts, d)
                                }
                                .fixedSize()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        BottomSheetChip(text: GroupRegionData.nationwide, selected: true) {}
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 220)

            HStack(spacing: 12) {
                BottomSheetButton(text: "취소", style: .white, action: onCancel)
                BottomSheetButton(text: "적용", style: .dark) {
                    onApply(GroupRegionData.tokens(region: selectedRegion, districts: selectedDistricts, city: currentCity))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .presentationDetents([.height(420)])
    }

    private var grabber: some View {
        Capsule().fill(Color("grey200")).frame(width: 44, height: 4).frame(maxWidth: .infinity)
    }

    private func regionItem(_ text: String, action: @escaping () -> Void) -> some View {
        let selected = selectedRegion == text
        return Button(action: action) {
            Text(text)
                .pretendardText(size: 16, weight: selected ? .medium : .regular)
                .foregroundColor(selected ? Color("main200") : Color("grey900"))
                .fixedSize()
                .padding(.leading, 4)
                .padding(.trailing, 28)
                .padding(.vertical, 12)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(selected ? Color("main200") : Color("grey200"))
                        .frame(width: 1)
                }
        }
        .buttonStyle(NoEffectButtonStyle())
    }

    // 안드 headSummary
    private var headSummary: String {
        guard let city = currentCity else { return GroupRegionData.nationwide }
        if selectedDistricts.contains(GroupRegionData.all) || selectedDistricts.isEmpty {
            return "\(city.name) | \(GroupRegionData.all)"
        }
        let ordered = city.districts.filter { $0 != GroupRegionData.all && selectedDistricts.contains($0) }
        let body = ordered.count <= 3 ? ordered.joined(separator: " · ")
            : ordered.prefix(3).joined(separator: " · ") + " 외 \(ordered.count - 3)개"
        return "\(city.name) | \(body)"
    }
}
