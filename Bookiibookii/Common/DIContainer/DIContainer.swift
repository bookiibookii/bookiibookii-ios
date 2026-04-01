import SwiftUI
import Combine

/// 앱 수준 의존성: 네비게이션 / API 레이어를 한곳에서 주입합니다.
final class DIContainer: ObservableObject {
    var navigationRouter: NavigationRouter
    let api: APIContainer

    private var cancellables = Set<AnyCancellable>()

    init(
        navigationRouter: NavigationRouter = NavigationRouter(),
        api: APIContainer = APIContainer()
    ) {
        self.navigationRouter = navigationRouter
        self.api = api

        navigationRouter.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
