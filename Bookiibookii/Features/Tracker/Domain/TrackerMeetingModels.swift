import Foundation

// 약속 장소(등록 요청에 필요한 좌표/주소만)
struct TrackerMeetingPlace: Equatable {
    let placeName: String
    let address: String
    let zipCode: String?
    let x: Double
    let y: Double
}

// 약속 3스텝 동안 누적되는 초안
struct TrackerMeetingDraft {
    var scheduledAt: String?      // +09:00 오프셋 ISO
    var place: TrackerMeetingPlace?
    var addressDetail: String = ""

    func toRegisterReqDTO() -> MeetingRegisterReqDTO? {
        guard let place, let scheduledAt else { return nil }
        return MeetingRegisterReqDTO(
            placeName: place.placeName,
            address: place.address,
            zipCode: place.zipCode,
            x: place.x,
            y: place.y,
            addressDetail: addressDetail.isEmpty ? nil : addressDetail,
            meetingAt: scheduledAt
        )
    }
}

extension ExchangeAddress {
    func toMeetingPlace() -> TrackerMeetingPlace {
        TrackerMeetingPlace(placeName: placeName, address: address, zipCode: zipCode, x: x, y: y)
    }
}

extension KakaoPlaceResult {
    func toMeetingPlace() -> TrackerMeetingPlace {
        TrackerMeetingPlace(placeName: placeName, address: address, zipCode: zipCode, x: x, y: y)
    }
}
