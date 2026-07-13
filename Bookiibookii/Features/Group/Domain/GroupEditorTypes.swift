import Foundation

// 안드 group/model/ExchangeType.kt, ReadingStyle.kt, SelectablePlace.kt 대응.
// 그룹 생성/수정(GroupEditor) 화면 전용 타입.

// MARK: - 교환 유형

enum ExchangeType {
    case direct, delivery
}

extension ExchangeType {
    // 주소관리 화면 진입 시 열 탭. direct=희망교환장소, delivery=배송지.
    var addressManagementTab: AddressManagementTab {
        switch self {
        case .direct:   return .exchange
        case .delivery: return .delivery
        }
    }
}

// MARK: - 그룹 규칙 프리셋

enum ReadingStyle: CaseIterable, Equatable {
    case comment, postit, photo, any

    var label: String {
        switch self {
        case .comment: return "책에 직접 코멘트를 남겨요!"
        case .postit:  return "직접 메모 대신 포스트잇이나 인덱스를 활용해요!"
        case .photo:   return "직접 메모 대신 사진으로 기록해요!"
        case .any:     return "어떤 방식이든 좋아요!"
        }
    }
    var iconName: String {
        switch self {
        case .comment: return "ic_edit"
        case .postit:  return "ic_bookmark"
        case .photo:   return "ic_camera"
        case .any:     return "ic_book"
        }
    }
    var apiTag: String {
        switch self {
        case .comment: return "MEMO"
        case .postit:  return "POSTIT"
        case .photo:   return "PHOTO"
        case .any:     return "All_ROUNDER"   // 안드 원본 표기 그대로(오타 아님, 서버계약)
        }
    }
}

// MARK: - 주소 선택 카드용 공통 UI 모델

// ExchangeAddress/DeliveryAddress를 공통으로 표현. 안드 SelectablePlace.kt 대응.
struct SelectablePlace: Identifiable, Equatable {
    let id: Int
    let placeName: String
    let address: String
    let isDefault: Bool
}

// MARK: - ExchangeAddress/DeliveryAddress → SelectablePlace 매퍼

extension ExchangeAddress {
    func toSelectablePlace() -> SelectablePlace {
        SelectablePlace(
            id: id,
            placeName: placeName,
            address: GroupEditorAddressFormat.join(address, addressDetail),
            isDefault: isDefault
        )
    }
}

extension DeliveryAddress {
    func toSelectablePlace() -> SelectablePlace {
        SelectablePlace(
            id: id,
            placeName: placeName,
            address: GroupEditorAddressFormat.join(address, addressDetail),
            isDefault: isDefault
        )
    }
}

// 안드 joinAddress(address, addressDetail) 대응 — 주소 + 상세주소 한 줄로 합침
enum GroupEditorAddressFormat {
    static func join(_ address: String, _ detail: String?) -> String {
        [address, detail?.trimmingCharacters(in: .whitespaces)]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
