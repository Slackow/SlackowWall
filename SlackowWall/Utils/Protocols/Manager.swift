//
//  Manager.swift
//  SlackowWall
//
//  Created by Kihron on 5/5/25.
//

import SwiftUI

@MainActor protocol Manager: AnyObject, Sendable, NotificationDispatcher {}
