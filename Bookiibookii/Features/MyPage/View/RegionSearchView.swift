import SwiftUI

struct RegionSearchView: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: (RegionSelection) -> Void
    let onClose: (() -> Void)?

    @State private var currentCity: String
    @State private var selectedDistricts: [String]
    private let cityNames = RegionData.cities.map(\.name) + ["전국"]

    init(preSelected: RegionSelection, onComplete: @escaping (RegionSelection) -> Void, onClose: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onClose = onClose
        let initialCity = preSelected.isAll ? "서울" : preSelected.city
        _currentCity = State(initialValue: initialCity)
        _selectedDistricts = State(initialValue: preSelected.districts)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                GeometryReader { proxy in
                    HStack(alignment: .top, spacing: 0) {
                        cityList
                            .frame(width: 52)
                            .overlay(alignment: .trailing) { Rectangle().fill(Color("grey200")).frame(width: 1) }
                        districtGrid
                            .frame(width: proxy.size.width - 52)
                            .padding(.leading, 14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }

            Button {
                if currentCity == "전국" { onComplete(.all) }
                else { onComplete(RegionSelection(city: currentCity, districts: selectedDistricts)) }
                onClose?()
                dismiss()
            } label: {
                Text("완료")
                    .font(.pretendard(size: 18, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var topBar: some View {
        HStack {
            Text("지역 검색").font(.pretendard(size: 20, weight: .medium)).foregroundColor(Color("grey900"))
            Spacer()
            Button { onClose?(); dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(Color("grey500")).frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 68)
        .overlay(alignment: .bottom) { Rectangle().fill(Color("grey200")).frame(height: 1) }
    }

    private var cityList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(cityNames, id: \.self) { city in
                    let isSelected = city == currentCity
                    Button {
                        guard currentCity != city else { return }
                        currentCity = city
                        selectedDistricts.removeAll()
                    } label: {
                        HStack(spacing: 0) {
                            Text(city)
                                .font(.pretendard(size: 16, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                            Rectangle().fill(isSelected ? Color("main200") : Color.clear).frame(width: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
        }
    }

    private var districtGrid: some View {
        ScrollView(showsIndicators: false) {
            GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(districtsForCurrentCity, id: \.self) { district in
                    let isAll = district == "전체"
                    let isSelected = isAll ? selectedDistricts.isEmpty : selectedDistricts.contains(district)
                    Button {
                        if district == "전체" { selectedDistricts.removeAll(); return }
                        if selectedDistricts.contains(district) { selectedDistricts.removeAll { $0 == district } }
                        else if selectedDistricts.count < 3 { selectedDistricts.append(district) }
                    } label: {
                        Text(district)
                            .font(.pretendard(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? Color("main200") : Color("grey700"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(isSelected ? Color("main100") : Color("white")))
                            .overlay(Capsule().stroke(isSelected ? Color("main105") : Color("grey200"), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var districtsForCurrentCity: [String] {
        if currentCity == "전국" { return ["전체"] }
        return RegionData.districts(of: currentCity)
    }
}
