//
//  DebugPrint.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import Foundation

func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    items.forEach {
        Swift.print($0, separator: separator, terminator: terminator)
    }
    #endif
}
