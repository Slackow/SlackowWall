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
            profile = Profile()
            
            DispatchQueue.main.async {
                ShortcutManager.shared.resetKeybinds()
            }
        } else {
            profile = Profile()
        }
        
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
        guard profiles.count < 10 else { return }
        
        activeProfile = UUID().uuidString
        profiles.append(activeProfile)
        
        profile = Profile()
        ShortcutManager.shared.resetKeybinds()
        
        let nameSet = Set(profileNames.map { $0.name })
        var newName = "New Profile"
        var x = 1
        
        while nameSet.contains(newName) {
            newName = "New Profile \(x)"
            x += 1
        }
        
        profile.profileName = newName
    }
    
    func deleteCurrentProfile() {
        if let idx = profiles.firstIndex(where: { $0 == activeProfile }), profiles.count > 1 {
            profiles.remove(at: idx)
            let oldProfilePrefix = "\(activeProfile)."
            
            Task {
                let userDefaults = UserDefaults.standard
                let prefix = oldProfilePrefix
                
                for key in userDefaults.dictionaryRepresentation().keys {
                    if key.hasPrefix(prefix) {
                        userDefaults.removeObject(forKey: key)
                    }
                }
                
                userDefaults.synchronize()
            }
            
            activeProfile = profiles[max(0, idx - 1)]
            profile = Profile()
        }
    }
    
    func autoSwitch() {
        for profile in profiles {
            let defaults = UserDefaults.standard
            let widthKey = "\(profile).expectedMWidth"
            let heightKey = "\(profile).expectedMHeight"
            
            let monitorWidth = defaults.integer(forKey: widthKey)
            let monitorHeight = defaults.integer(forKey: heightKey)
            
            if monitorWidth > 0 && monitorHeight > 0 {
                if let frame = NSScreen.main?.frame, Int(frame.width) == monitorWidth, Int(frame.height) == monitorHeight {
                    if activeProfile != profile {
                        activeProfile = profile
                        self.profile = Profile()
                        return
                    }
                }
            }
        }
    }
}
