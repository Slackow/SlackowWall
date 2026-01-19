import SwiftUI

enum ImageType {
    case system(String)
    case asset(String)
    case nsImage(NSImage)
}

extension Image {
    init(_ imageType: ImageType) {
        switch imageType {
            case .asset(let name):
                self.init(name)
            case .system(let systemName):
                self.init(systemName: systemName)
            case .nsImage(let nsImage):
                self.init(nsImage: nsImage)
        }
    }
}
