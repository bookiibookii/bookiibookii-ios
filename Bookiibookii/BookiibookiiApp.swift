//
//  BookiibookiiApp.swift
//  Bookiibookii
//
//  Created by jungee on 3/30/26.
//

import SwiftUI

@main
struct BookiibookiiApp: App {
    @StateObject private var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $container.navigationRouter.destinations) {
                SplashView {
                    container.navigationRouter.hardReset(to: .mainTab)
                }
                .environmentObject(container)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationRoutingView(destination: destination)
                        .environmentObject(container)
                }
            }
        }
    }
}
