//
//  ProfileManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/15/24.
//

import SwiftUI

class ProfileManager: ObservableObject {
    @AppStorage("profiles") private var profiles: [String] = []
    @AppStorage("activeProfile") var activeProfile: String = UUID().uuidString
    @Published var profile: Profile
    
    static let shared = ProfileManager()
    
    init() {
        profile = Profile()
        
        if profiles.isEmpty {
            profiles.append(activeProfile)
        }
        
        print("Active Profile:", activeProfile)
    }
    
    func changeProfile() {
        activeProfile = activeProfile == "lol" ? "one" : "lol"
        profile = Profile()
        print(activeProfile)
    }
}
