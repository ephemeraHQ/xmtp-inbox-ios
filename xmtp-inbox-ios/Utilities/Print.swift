//
//  Print.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import Foundation

func print(_ object: Any...) {
    #if DEBUG
    object.forEach { item in
        Swift.print(item)
    }
    #endif
}

func print(_ object: Any) {
    #if DEBUG
    Swift.print(object)
    #endif
}
