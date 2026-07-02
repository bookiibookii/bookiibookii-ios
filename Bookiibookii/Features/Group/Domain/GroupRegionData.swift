import Foundation

enum GroupRegionData {
    static let nationwide = "전국"
    static let all = "전체"

    struct City: Identifiable {
        let name: String
        let districts: [String]
        var id: String { name }
    }

    static let cities: [City] = [
        City(name: "서울", districts: [all, "강남구","강동구","강북구","강서구","관악구","광진구","구로구","금천구","노원구","도봉구","동대문구","동작구","마포구","서대문구","서초구","성동구","성북구","송파구","양천구","영등포구","용산구","은평구","종로구","중구","중랑구"]),
        City(name: "경기", districts: [all, "수원시","성남시","의정부시","안양시","부천시","광명시","평택시","동두천시","안산시","고양시","과천시","구리시","남양주시","오산시","시흥시","군포시","의왕시","하남시","용인시","파주시","이천시","안성시","김포시","화성시","광주시","양주시","포천시","여주시","연천군","가평군","양평군"]),
        City(name: "인천", districts: [all, "계양구","미추홀구","남동구","동구","부평구","서구","연수구","중구","강화군·옹진군"]),
        City(name: "대전", districts: [all, "대덕구","동구","서구","유성구","중구"]),
        City(name: "대구", districts: [all, "남구","달서구","동구","북구","서구","수성구","중구","달성군","군위군"]),
        City(name: "광주", districts: [all, "광산구","남구","동구","북구","서구"]),
        City(name: "울산", districts: [all, "남구","동구","북구","중구","울주군"]),
        City(name: "부산", districts: [all, "강서구","금정구","남구","동구","동래구","부산진구","북구","사상구","사하구","서구","수영구","연제구","영도구","중구","해운대구","기장군"]),
        City(name: "세종", districts: [all, "세종특별자치시"]),
        City(name: "강원", districts: [all, "춘천시","원주시","강릉시","동해시","태백시","속초시","삼척시","홍천군","횡성군","영월군","평창군","정선군","철원군","화천군","양구군","인제군","고성군","양양군"]),
        City(name: "충북", districts: [all, "청주시","충주시","제천시","보은군","옥천군","영동군","증평군","진천군","괴산군","음성군","단양군"]),
        City(name: "충남", districts: [all, "천안시","공주시","보령시","아산시","서산시","논산시","계룡시","당진시","금산군","부여군","서천군","청양군","홍성군","예산군","태안군"]),
        City(name: "전북", districts: [all, "전주시","군산시","익산시","정읍시","남원시","김제시","완주군","진안군","무주군","장수군","임실군","순창군","고창군","부안군"]),
        City(name: "전남", districts: [all, "목포시","여수시","순천시","나주시","광양시","담양군","곡성군","구례군","고흥군","보성군","화순군","장흥군","강진군","해남군","영암군","무안군","함평군","영광군","장성군","완도군","진도군","신안군"]),
        City(name: "경북", districts: [all, "포항시","경주시","김천시","안동시","구미시","영주시","영천시","상주시","문경시","경산시","의성군","청송군","영양군","영덕군","청도군","고령군","성주군","칠곡군","예천군","봉화군","울진군","울릉군"]),
        City(name: "경남", districts: [all, "창원시","진주시","통영시","사천시","김해시","밀양시","거제시","양산시","의령군","함안군","창녕군","고성군","남해군","하동군","산청군","함양군","거창군","합천군"]),
        City(name: "제주", districts: [all, "제주시","서귀포시"]),
    ]

    // 선택 → 토큰. 전국/미선택 → [], 시+전체 → [시], 시+구 다중 → ["시 구", ...] (안드 toRegionTokens)
    static func tokens(region: String, districts: Set<String>, city: City?) -> [String] {
        if region == nationwide || city == nil { return [] }
        if districts.contains(all) || districts.isEmpty { return [city!.name] }
        return city!.districts.filter { $0 != all && districts.contains($0) }.map { "\(city!.name) \($0)" }
    }

    // 토큰 → (시, 구 집합) (안드 fromRegionTokens)
    static func fromTokens(_ tokens: [String]) -> (String, Set<String>) {
        guard let first = tokens.first else { return (nationwide, [all]) }
        let cityName = String(first.prefix(while: { $0 != " " }))
        guard let city = cities.first(where: { $0.name == cityName }) else { return (nationwide, [all]) }
        let districts = Set(tokens.compactMap { token -> String? in
            let d = token.replacingOccurrences(of: city.name, with: "").trimmingCharacters(in: .whitespaces)
            return d.isEmpty ? nil : d
        })
        return districts.isEmpty ? (city.name, [all]) : (city.name, districts)
    }

    // 구역 토글: "전체"는 구체 구역과 상호배타, 항상 1개 이상 유지 (안드 toggleDistrict)
    static func toggle(_ current: Set<String>, _ district: String) -> Set<String> {
        if district == all { return [all] }
        let base = current.subtracting([all])
        let next = base.contains(district) ? base.subtracting([district]) : base.union([district])
        return next.isEmpty ? [all] : next
    }
}

// 필터 칩 라벨 (안드 regionChipLabel). 비어있으면 호출부에서 기본 라벨 사용
func regionChipLabel(_ regions: [String]) -> String {
    guard let first = regions.first else { return "" }
    if regions.count > 1 { return "\(first) 외 \(regions.count - 1)" }
    return first.contains(" ") ? first : "\(first) 전체"
}
