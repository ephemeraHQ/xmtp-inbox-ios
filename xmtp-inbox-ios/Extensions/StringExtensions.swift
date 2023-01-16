//
//  StringExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import Foundation

extension String {

    func truncatedAddress() -> String {
        if self.count > 6 {
            let start = self.index(self.startIndex, offsetBy: 6)
            let end = self.index(self.endIndex, offsetBy: -5)
            return self.replacingCharacters(in: start...end, with: "...")
        }
        return self
    }
}
