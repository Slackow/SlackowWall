//
//  RefreshObserver.swift
//  SlackowWall
//
//  Created by Kihron on 5/5/25.
//

import SwiftUI

@MainActor protocol RefreshObserver: AnyObject, Sendable {
    func handleRefreshNotification() async throws
}

extension RefreshObserver {
    func setupRefreshObserver() {
        NotificationCenter.default.addObserver(
            forName: .shouldRefreshCapture, object: nil, queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task {
                try await self.handleRefreshNotification()
            }
        }
    }
}
