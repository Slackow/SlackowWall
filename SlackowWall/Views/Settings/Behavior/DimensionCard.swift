import SwiftUI

struct DimensionCard: View {
    var name: String
    
    @Binding var x: Int?
    @Binding var y: Int?
    @Binding var width: Int?
    @Binding var height: Int?

    var body: some View {
        SettingsCardView {
            Form {
                VStack {
                    HStack {
                        Text("\(name) Size")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("W", value: $width, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        TextField("H", value: $height, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("\(name) Position")
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
                        Button("Center") {
                            if let s = NSScreen.main?.visibleFrame.size,
                               let width = width, let height = height {
                                x = (Int(s.width) - width)/2
                                y = (Int(s.height) - height)/2
                            }
                        }.disabled(width == nil || height == nil)
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
