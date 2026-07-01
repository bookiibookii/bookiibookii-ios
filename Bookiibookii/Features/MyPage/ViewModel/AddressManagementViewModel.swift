import Foundation
import Combine

enum AddressManagementTab: String, CaseIterable {
    case delivery
    case exchange

    var title: String {
        switch self {
        case .delivery: return "배송지"
        case .exchange: return "교환 희망 장소"
        }
    }
}

struct DeliveryAddressFormState: Equatable {
    var placeName: String = ""
    var address: String = ""
    var zipCode: String = ""
    var addressDetail: String = ""
    var receiverName: String = ""
    var phone: String = ""
    var isDefault: Bool = false

    static let empty = DeliveryAddressFormState()

    init() {}

    init(from delivery: DeliveryAddress) {
        placeName = delivery.placeName
        address = delivery.address
        zipCode = delivery.zipCode
        addressDetail = delivery.addressDetail ?? ""
        receiverName = delivery.receiverName
        phone = delivery.phone
        isDefault = delivery.isDefault
    }

    var canSubmit: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !receiverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Self.isValidPhone(phone)
    }

    func toRequest() -> DeliveryAddressRequest {
        let trimmedNickname = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return DeliveryAddressRequest(
            placeName: trimmedNickname.isEmpty ? "배송지" : trimmedNickname,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            addressDetail: addressDetail.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            receiverName: receiverName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    static func isValidPhone(_ value: String) -> Bool {
        let pattern = #"^\d{2,3}-\d{3,4}-\d{4}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    mutating func apply(postcode: DaumPostcodeResult) {
        address = postcode.roadAddress
        zipCode = postcode.zonecode
        if placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !postcode.buildingName.isEmpty {
            placeName = postcode.buildingName
        }
    }

    mutating func updatePhone(_ input: String) {
        phone = Self.formatPhone(input)
    }

    static func formatPhone(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        let limited = String(digits.prefix(11))
        switch limited.count {
        case 0...3:
            return limited
        case 4...7:
            let first = limited.prefix(3)
            let second = limited.dropFirst(3)
            return "\(first)-\(second)"
        default:
            let first = limited.prefix(3)
            let middle = limited.dropFirst(3).prefix(4)
            let last = limited.dropFirst(7)
            return "\(first)-\(middle)-\(last)"
        }
    }
}

struct ExchangeAddressFormState: Equatable {
    var placeName: String = ""
    var searchDisplayText: String = ""
    var searchedPlaceName: String = ""
    var address: String = ""
    var zipCode: String = ""
    var x: Double?
    var y: Double?
    var addressDetail: String = ""
    var isDefault: Bool = false

    static let empty = ExchangeAddressFormState()

    init() {}

    init(from exchange: ExchangeAddress) {
        placeName = exchange.placeName
        searchedPlaceName = exchange.placeName
        address = exchange.address
        zipCode = exchange.zipCode ?? ""
        x = exchange.x
        y = exchange.y
        addressDetail = exchange.addressDetail ?? ""
        isDefault = exchange.isDefault
        searchDisplayText = exchange.address
    }

    var canSubmit: Bool {
        x != nil && y != nil && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    mutating func apply(postcode: DaumPostcodeResult) {
        searchedPlaceName = postcode.buildingName.isEmpty ? postcode.roadAddress : postcode.buildingName
        address = postcode.roadAddress
        zipCode = postcode.zonecode
        x = postcode.x
        y = postcode.y
        searchDisplayText = postcode.roadAddress
        if placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !postcode.buildingName.isEmpty {
            placeName = postcode.buildingName
        }
    }

    mutating func apply(place: KakaoPlaceResult) {
        searchedPlaceName = place.placeName
        address = place.address
        zipCode = place.zipCode ?? ""
        x = place.x
        y = place.y
        searchDisplayText = place.address
    }

    func toRequest() -> ExchangeAddressRequest {
        let nickname = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = nickname.isEmpty
            ? (searchedPlaceName.isEmpty ? "교환 장소" : searchedPlaceName)
            : nickname
        return ExchangeAddressRequest(
            placeName: resolvedName,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "",
            x: x ?? 0,
            y: y ?? 0,
            addressDetail: addressDetail.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

@MainActor
final class AddressManagementViewModel: ObservableObject {
    @Published var selectedTab: AddressManagementTab = .delivery

    @Published var deliveries: [DeliveryAddress] = []
    @Published var exchanges: [ExchangeAddress] = []
    @Published var isLoading = false
    @Published var alertMessage: String?

    @Published var isDeliveryFormSheetPresented = false
    @Published var editingDelivery: DeliveryAddress?
    @Published var deliveryFormState = DeliveryAddressFormState.empty

    @Published var isExchangeFormSheetPresented = false
    @Published var editingExchange: ExchangeAddress?
    @Published var exchangeFormState = ExchangeAddressFormState.empty

    @Published var isSaving = false

    @Published var menuDeliveryId: Int?
    @Published var menuExchangeId: Int?
    @Published var showPostcode = false
    @Published var showPlaceSearch = false

    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    var deliveryEmptyMessage: (String, String) {
        (
            "등록한 주소가 존재하지 않아요.",
            "택배 교환 그룹에 참여하려면 배송지를 등록해주세요."
        )
    }

    var exchangeEmptyMessage: (String, String) {
        (
            "등록한 주소가 존재하지 않아요.",
            "직접 교환 그룹에 참여하려면 장소를 등록해주세요."
        )
    }

    func load() async {
        switch selectedTab {
        case .delivery:
            await reloadDeliveries()
        case .exchange:
            await reloadExchanges()
        }
    }

    func reloadCurrentTab() async {
        switch selectedTab {
        case .delivery:
            await reloadDeliveries()
        case .exchange:
            await reloadExchanges()
        }
    }

    /// GET /api/mypage/addresses/deliveries
    func reloadDeliveries() async {
        isLoading = true
        defer { isLoading = false }
        do {
            deliveries = try await locationService.fetchDeliveries()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    /// GET /api/mypage/addresses/exchanges
    func reloadExchanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            exchanges = try await locationService.fetchExchanges()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func openAddForm() {
        menuDeliveryId = nil
        menuExchangeId = nil

        switch selectedTab {
        case .delivery:
            editingDelivery = nil
            deliveryFormState = DeliveryAddressFormState()
            deliveryFormState.isDefault = deliveries.isEmpty
            isDeliveryFormSheetPresented = true
        case .exchange:
            editingExchange = nil
            exchangeFormState = ExchangeAddressFormState()
            exchangeFormState.isDefault = exchanges.isEmpty
            isExchangeFormSheetPresented = true
        }
    }

    func openEditDeliveryForm(for address: DeliveryAddress) {
        editingDelivery = address
        deliveryFormState = DeliveryAddressFormState(from: address)
        menuDeliveryId = nil
        isDeliveryFormSheetPresented = true
    }

    func openEditExchangeForm(for address: ExchangeAddress) {
        editingExchange = address
        exchangeFormState = ExchangeAddressFormState(from: address)
        menuExchangeId = nil
        isExchangeFormSheetPresented = true
    }

    func closeDeliveryForm() {
        isDeliveryFormSheetPresented = false
        editingDelivery = nil
        deliveryFormState = .empty
        showPostcode = false
    }

    func closeExchangeForm() {
        isExchangeFormSheetPresented = false
        editingExchange = nil
        exchangeFormState = .empty
        showPlaceSearch = false
    }

    func applyPostcode(_ result: DaumPostcodeResult) {
        deliveryFormState.apply(postcode: result)
        showPostcode = false
    }

    func applyExchangePostcode(_ result: DaumPostcodeResult) {
        exchangeFormState.apply(postcode: result)
        showPlaceSearch = false
    }

    func saveDeliveryForm() async {
        guard deliveryFormState.canSubmit else { return }
        isSaving = true
        defer { isSaving = false }

        let request = deliveryFormState.toRequest()
        let shouldSetDefault = deliveryFormState.isDefault

        do {
            if let editing = editingDelivery {
                try await locationService.updateDelivery(id: editing.id, body: request)
                if shouldSetDefault && !editing.isDefault {
                    try await locationService.setDefaultDelivery(id: editing.id)
                }
            } else {
                let hadDeliveries = !deliveries.isEmpty
                try await locationService.addDelivery(request)
                await reloadDeliveries()
                if shouldSetDefault, hadDeliveries,
                   let target = deliveries.first(where: {
                       $0.address == request.address &&
                       $0.receiverName == request.receiverName &&
                       $0.phone == request.phone
                   }) {
                    try await locationService.setDefaultDelivery(id: target.id)
                    await reloadDeliveries()
                }
                closeDeliveryForm()
                return
            }
            closeDeliveryForm()
            await reloadDeliveries()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func saveExchangeForm() async {
        guard exchangeFormState.canSubmit else { return }
        isSaving = true
        defer { isSaving = false }

        let request = exchangeFormState.toRequest()
        let shouldSetDefault = exchangeFormState.isDefault

        do {
            if let editing = editingExchange {
                try await locationService.updateExchange(id: editing.id, body: request)
                if shouldSetDefault && !editing.isDefault {
                    try await locationService.setDefaultExchange(id: editing.id)
                }
            } else {
                let hadExchanges = !exchanges.isEmpty
                try await locationService.addExchange(request)
                await reloadExchanges()
                if shouldSetDefault, hadExchanges,
                   let target = exchanges.first(where: {
                       $0.address == request.address &&
                       $0.x == request.x &&
                       $0.y == request.y
                   }) {
                    try await locationService.setDefaultExchange(id: target.id)
                    await reloadExchanges()
                }
                closeExchangeForm()
                return
            }
            closeExchangeForm()
            await reloadExchanges()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func deleteDelivery(_ address: DeliveryAddress) async {
        menuDeliveryId = nil
        do {
            try await locationService.deleteDelivery(id: address.id)
            await reloadDeliveries()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func deleteExchange(_ address: ExchangeAddress) async {
        menuExchangeId = nil
        do {
            try await locationService.deleteExchange(id: address.id)
            await reloadExchanges()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
