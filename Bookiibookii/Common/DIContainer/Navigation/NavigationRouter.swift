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
