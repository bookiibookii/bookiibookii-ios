import Foundation
import Combine

protocol NavigationRoutable: AnyObject {
    var destinations: [NavigationDestination] { get set }

    func push(to: NavigationDestination)
    func pop()
    func popToRoot()
    /// 스택을 비우고 단일 목적지로 교체합니다.
    func hardReset(to: NavigationDestination)
}

final class NavigationRouter: NavigationRoutable, ObservableObject {
    @Published var destinations: [NavigationDestination] = []
    /// COM-03 공통 에러 전체 화면 (안드 `ErrorActivity` 대응)
    @Published var presentedComError: BookiiErrorType?
    /// 메인 탭 선택 상태. 다른 화면(예: 트래커 '서재로 이동')에서 탭을 전환할 수 있도록 라우터가 소유.
    @Published var selectedTab: BookiiTabCase = .home

    func push(to destination: NavigationDestination) {
        destinations.append(destination)
    }

    func pop() {
        if !destinations.isEmpty { destinations.removeLast() }
    }

    func popToRoot() {
        destinations = [.mainTab]
    }

    func hardReset(to destination: NavigationDestination) {
        destinations = [destination]
    }
}
