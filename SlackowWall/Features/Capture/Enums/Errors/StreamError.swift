//
//  StreamError.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

enum StreamError: Equatable {
    case appClosed
    case unknown(errorCode: Int)
    
    init(errorCode: Int) {
        switch errorCode {
            case -3815:
                self = .appClosed
            default:
                self = .unknown(errorCode: errorCode)
        }
    }
}
