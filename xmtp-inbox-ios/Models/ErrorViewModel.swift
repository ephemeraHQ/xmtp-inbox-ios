//
//  ErrorViewModel.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/25/23.
//

import Foundation

class ErrorViewModel: ObservableObject {

    @Published var errorMessage: String?

    @Published var isShowing = false

    func showError(_ errorMessage: String) {
        self.errorMessage = errorMessage
        self.isShowing = true
        print(errorMessage)
    }
}
