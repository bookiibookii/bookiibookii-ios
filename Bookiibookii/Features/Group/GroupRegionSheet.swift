import SwiftUI

/// 지역별 바텀시트 — 좌측 시·도 리스트 + 우측 구·군 칩.
/// 안드로이드 `GrpRegionBottomSheetFragment` 포팅.
struct GroupRegionSheet: View {
    let preSelected: RegionSelection
    let onConfirm: (RegionSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentCity: String
    @State private var selectedDistricts: [String]
    @State private var toast: String? = nil

    init(preSelected: RegionSelection, onConfirm: @escaping (RegionSelection) -> Void) {
        self.preSelected = preSelected
        self.onConfirm = onConfirm
        let initialCity = preSelected.isAll ? "서울" : preSelected.city
        _currentCity = State(initialValue: initialCity)
        _selectedDistricts = State(initialValue: preSelected.districts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            handleBar
                .padding(.top, 12)

            header
                .padding(.horizontal, 24)
                .padding(.top, 20)

            twoColumnBody

            actionRow
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .background(Color("white"))
        .toast($toast)
    }

    // 안드로이드 grp_bottom_sheet_region_handle 대응 (40×4 grey200)
    private var handleBar: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(Color("grey200"))
                .frame(width: 40, height: 4)
            Spacer()
        }
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("지역")
                .font(.pretendard(size: 18, weight: .bold))
                .foregroundColor(Color("grey900"))
            summaryText
            Spacer()
        }
    }

    private var summaryText: some View {
        Group {
            if selectedDistricts.isEmpty {
                Text("전체")
                    .foregroundColor(Color("main200"))
            } else {
                Text(selectedDistricts.joined(separator: " · "))
                    .foregroundColor(Color("main200"))
            }
        }
        .font(.pretendard(size: 14, weight: .medium))
    }

    // MARK: - 본문 (좌: 시·도 / 우: 구·군)

    private var twoColumnBody: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                cityList
                    .frame(width: proxy.size.width * 0.5 / 3.0)
                districtGrid
                    .frame(width: proxy.size.width * 2.5 / 3.0)
                    .padding(.leading, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .frame(height: 230)
    }

    private var cityList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(RegionData.cities) { city in
                    cityRow(city)
                }
            }
        }
    }

    private func cityRow(_ city: KoreaRegion) -> some View {
        let isSelected = city.name == currentCity
        return Button {
            guard currentCity != city.name else { return }
            currentCity = city.name
            selectedDistricts.removeAll()
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(isSelected ? Color("main200") : Color.clear)
                    .frame(width: 3, height: 24)
                Text(city.name)
                    .font(.pretendard(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color("grey900") : Color("grey500"))
                Spacer()
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
    }

    private var districtGrid: some View {
        ScrollView(showsIndicators: false) {
            GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(RegionData.districts(of: currentCity), id: \.self) { district in
                    districtChip(district)
                }
            }
        }
    }

    private func districtChip(_ district: String) -> some View {
        let isAll = district == "전체"
        let isSelected: Bool = isAll ? selectedDistricts.isEmpty : selectedDistricts.contains(district)
        return Button {
            handleTap(district)
        } label: {
            Text(district)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color("main200") : Color("grey700"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(isSelected ? Color("main100") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color("main200") : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func handleTap(_ district: String) {
        if district == "전체" {
            selectedDistricts.removeAll()
            return
        }
        if selectedDistricts.contains(district) {
            selectedDistricts.removeAll { $0 == district }
        } else {
            if selectedDistricts.count >= 3 {
                toast = "최대 3개까지 선택 가능합니다."
                return
            }
            selectedDistricts.append(district)
        }
    }

    // MARK: - 하단 버튼

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
            }

            Button {
                onConfirm(RegionSelection(city: currentCity, districts: selectedDistricts))
                dismiss()
            } label: {
                Text("확인")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey900")))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("초기 — 서울") {
    GroupRegionSheet(preSelected: .all, onConfirm: { _ in })
        .frame(height: 346)
}

#Preview("서울 강남·서초 선택") {
    GroupRegionSheet(
        preSelected: RegionSelection(city: "서울", districts: ["강남구", "서초구"]),
        onConfirm: { _ in }
    )
    .frame(height: 346)
}
