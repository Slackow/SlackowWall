import SwiftUI

struct DimensionCard: View {
    var name: String
    var description: String?
    
    @Binding var x: Int?
    @Binding var y: Int?
    @Binding var width: Int?
    @Binding var height: Int?

    var body: some View {
        SettingsCardView {
            Form {
                VStack {
                    VStack(spacing: 2) {
                        Text("\(name) Mode")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let description = description {
                            Text(description)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    HStack {
                        Text("Size")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("W", value: $width, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        TextField("H", value: $height, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Position")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("X", value: $x, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        TextField("Y", value: $y, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Scale to Monitor") {
                            if let s = NSScreen.main?.visibleFrame.size,
                               let width = width, let height = height,
                               Int(s.width) < width || Int(s.height) < height {
                                let scale = max(CGFloat(width)/s.width, CGFloat(height)/s.height)
                                self.width = Int(CGFloat(width) / scale)
                                self.height = Int(CGFloat(height) / scale)
                            }
                        }
                        .disabled(width == nil || height == nil ||
                                  ((NSScreen.main?.visibleFrame.width).map {Int($0) >= width ?? 0} ?? true &&
                                  (NSScreen.main?.visibleFrame.height).map {Int($0) >= height ?? 0} ?? true))
                        Button("Center"){
                            if let s = NSScreen.main?.visibleFrame.size,
                               let width = width, let height = height {
                                x = (Int(s.width) - width)/2
                                y = (Int(s.height) - height)/2
                            }
                        }
                        .disabled(width == nil || height == nil)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        let instM = InstanceManager.shared
        DimensionCard(name: "Wide", x: instM.$wideX, y: instM.$wideY, width: instM.$wideWidth, height: instM.$wideHeight)
    }.padding(20)
}
