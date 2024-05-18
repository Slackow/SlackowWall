//
//  ProfileManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/15/24.
//

import SwiftUI
import Combine

class ProfileManager: ObservableObject {
    @AppStorage("profiles") var profiles: [String] = []
    @AppStorage("activeProfile") var activeProfile: String = ""
    @Published var profile: Profile = Profile()
    
    private var cancellables = Set<AnyCancellable>()
    
    var profileNames: [(name: String, id: String)] {
        return profiles.map { profile in
            return (name: UserDefaults.standard.string(forKey: "\(profile).profileName") ?? "Main", id: profile)
        }
    }
    
    static let shared = ProfileManager()
    
    init() {
        observeUserDefaults()
        
        if profiles.isEmpty {
            activeProfile = UUID().uuidString
            profiles.append(activeProfile)
        }
        
        profile = Profile()
        
        print("Active Profile:", activeProfile)
    }
    
    func observeUserDefaults() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    func createNewProfile() {
        activeProfile = UUID().uuidString
        profiles.append(activeProfile)
        
        profile = Profile()
        profile.profileName = "New Profile"
    }
    
    func deleteCurrentProfile() {
        if let idx = profiles.firstIndex(where: { $0 == activeProfile }), profiles.count > 1 {
            profiles.remove(at: idx)
            
            let userDefaults = UserDefaults.standard
            let prefix = "\(activeProfile)."
            
            for key in userDefaults.dictionaryRepresentation().keys {
                if key.hasPrefix(prefix) {
                    userDefaults.removeObject(forKey: key)
                }
            }
            
            userDefaults.synchronize()
            
            activeProfile = profiles[max(0, idx - 1)]
            profile = Profile()
        }
    }
    
    func updateProfileName(_ newName: String) {
        UserDefaults.standard.set(newName, forKey: "\(activeProfile).profileName")
    }
}
