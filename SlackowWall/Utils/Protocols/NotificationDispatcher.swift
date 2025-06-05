//
//  NotificationDispatcher.swift
//  SlackowWall
//
//  Created by Kihron on 5/5/25.
//

import SwiftUI

@MainActor protocol NotificationDispatcher {}

extension NotificationDispatcher {
    func sendNotification(_ notification: Notification.Name) {
        NotificationCenter.default.post(Notification(name: notification))
    }
}
