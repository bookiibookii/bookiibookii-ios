import Foundation

// UI 라벨 ↔ API enum.
enum DeliveryCompany: String, CaseIterable, Identifiable {
    case cjLogistics = "CJ_LOGISTICS"
    case hanjin = "HANJIN"
    case lotte = "LOTTE"
    case postOffice = "POST_OFFICE"
    case logen = "LOGEN"
    case cu = "CU"
    case gs = "GS"

    var id: String { rawValue }
    var apiValue: String { rawValue }
    var label: String {
        switch self {
        case .cjLogistics: return "CJ대한통운"
        case .hanjin:      return "한진택배"
        case .lotte:       return "롯데택배"
        case .postOffice:  return "우체국택배"
        case .logen:       return "로젠택배"
        case .cu:          return "CU편의점택배"
        case .gs:          return "GS25편의점택배"
        }
    }
}

// 택배사 코드 → 조회 URL.
func deliveryTrackingUrl(companyCode: String?, trackingNumber: String?) -> URL? {
    guard let number = trackingNumber?.trimmingCharacters(in: .whitespaces), !number.isEmpty else { return nil }
    let template: String
    switch companyCode {
    case "CJ_LOGISTICS": template = "https://www.cjlogistics.com/ko/tool/parcel/newTracking?gnbInvcNo=%@"
    case "HANJIN":       template = "https://www.hanjin.com/kor/CMS/DeliveryMgr/WaybillResult.do?mCode=MN038&schLang=KR&wblnumText2=%@"
    case "LOTTE":        template = "https://www.lotteglogis.com/home/reservation/tracking/linkView?InvNo=%@"
    case "POST_OFFICE":  template = "https://service.epost.go.kr/trace.RetrieveDomRigiTraceList.comm?displayHeader=N&sid1=%@"
    case "LOGEN":        template = "https://www.ilogen.com/m/personal/trace.pop/%@"
    case "CU":           template = "https://www.cupost.co.kr/postbox/delivery/localResult.cupost?invoice_no=%@"
    case "GS":           template = "https://www.cvsnet.co.kr/invoice/tracking.do?invoice_no=%@"
    default: return nil
    }
    return URL(string: String(format: template, number))
}

// "나의 배송지" 항목.
struct DeliveryAddressOption: Identifiable {
    let userDeliveryId: Int
    let title: String
    let address: String
    let addressDetail: String
    let zipCode: String

    var id: Int { userDeliveryId }
    // 버튼 표시용 전체 주소 (도로명 + 상세)
    var displayAddress: String {
        [address, addressDetail].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// 배송정보 다이얼로그 표시 모델.
struct TrackerDeliveryAddressDisplay {
    var receiverName: String = ""
    var phoneNumber: String = ""
    var address: String = ""
    var addressDetail: String = ""
}

extension Optional where Wrapped == DeliveryAddressItemDTO {
    func toDisplay() -> TrackerDeliveryAddressDisplay {
        TrackerDeliveryAddressDisplay(
            receiverName: self?.receiverName ?? "",
            phoneNumber: self?.phoneNumber ?? "",
            address: self?.address ?? "",
            addressDetail: self?.addressDetail ?? ""
        )
    }
}

extension DeliveryAddress {
    // 마이페이지 배송지 → 옵션.
    func toDeliveryAddressOption() -> DeliveryAddressOption {
        DeliveryAddressOption(
            userDeliveryId: id,
            title: placeName,
            address: address,
            addressDetail: addressDetail ?? "",
            zipCode: zipCode
        )
    }
}

extension Array where Element == DeliveryAddress {
    // 현재 교환 myAddress와 zip+address+addressDetail이 일치하는 저장 배송지의 id.
    func matchUserDeliveryId(_ snapshot: DeliveryAddressItemDTO?) -> Int? {
        guard let snapshot else { return nil }
        return first { saved in
            saved.zipCode == (snapshot.zipCode ?? "") &&
            saved.address == (snapshot.address ?? "") &&
            (saved.addressDetail ?? "") == (snapshot.addressDetail ?? "")
        }?.id
    }
}
