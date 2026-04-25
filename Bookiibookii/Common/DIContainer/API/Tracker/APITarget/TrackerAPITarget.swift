import Foundation

// 안드로이드 TrkApi.getHostTrackers / getGuestTrackers 대응.
enum TrackerAPITarget: APITargetType {
    case hostList   // GET /api/groups/me/trackers/host
    case guestList  // GET /api/groups/me/trackers/guest

    var path: String {
        switch self {
        case .hostList:  return API.Path.trackers + "/host"
        case .guestList: return API.Path.trackers + "/guest"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .hostList, .guestList: return .get
        }
    }
}
