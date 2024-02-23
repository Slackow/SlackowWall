import CoreGraphics

typealias CGSConnectionID = Int
typealias CGSWindowID = UInt32
typealias CGSWindowLevel = Int32

@_silgen_name("CGSSetWindowLevel")
func CGSSetWindowLevel(_ connection: CGSConnectionID, _ window: CGSWindowID, _ level: CGSWindowLevel)

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

