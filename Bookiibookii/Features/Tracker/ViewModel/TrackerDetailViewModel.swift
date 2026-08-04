import SwiftUI
import Combine

@MainActor
final class TrackerDetailViewModel: ObservableObject {
    @Published var state = TrackerDetailUiState()
    let coordinator: TrackerDialogCoordinator

    private let trackerService: TrackerService
    private let groupId: Int

    init(trackerService: TrackerService, locationService: LocationService, groupId: Int) {
        self.trackerService = trackerService
        self.groupId = groupId
        self.coordinator = TrackerDialogCoordinator(trackerService: trackerService, locationService: locationService)
        self.coordinator.onChanged = { [weak self] in await self?.load() }
    }

    func load() async {
        state.loading = true
        state.error = nil
        do {
            let dto = try await trackerService.fetchDetail(groupId: groupId)
            var next = dto.toUiState()
            next.loading = false
            state = next
        } catch TrackerServiceError.http(404) {
            state.notFound = true
            state.loading = false
        } catch {
            state.error = "트래커를 불러오지 못했어요"
            state.loading = false
        }
    }
}
