//
//  AppSettings.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import SwiftUI

/// A property wrapper that provides access to a specific preference within the shared `Settings` object.
///
/// Use the `@AppSettings` property wrapper to bind a property to a specific key path in the `Preferences`
/// model. This allows for seamless reading and writing of user preferences throughout your SwiftUI views.
///
/// ```swift
/// @AppSettings(\.somePreference) var somePreference: SomeType
/// ```
///
/// - Note: The `@AppSettings` property wrapper requires that the `Preferences` model conforms to `Equatable`.
///
/// - Parameters:
///   - keyPath: A key path to a specific property within the `Preferences` model.
///
/// - SeeAlso: ``Settings``, ``Preferences``
@propertyWrapper
@MainActor struct AppSettings<T>: DynamicProperty where T: Equatable {
    @ObservedObject var settings: Settings = .shared

    let keyPath: WritableKeyPath<Preferences, T>

    init(_ keyPath: WritableKeyPath<Preferences, T>) {
        self.keyPath = keyPath
    }

    init() where T == Preferences {
        self.keyPath = \.self
    }

    var wrappedValue: T {
        get {
            settings.preferences[keyPath: keyPath]
        }
        nonmutating set {
            settings.preferences[keyPath: keyPath] = newValue
        }
    }

    var projectedValue: Binding<T> {
        Binding {
            settings.preferences[keyPath: keyPath]
        } set: {
            settings.preferences[keyPath: keyPath] = $0
        }
    }
}
