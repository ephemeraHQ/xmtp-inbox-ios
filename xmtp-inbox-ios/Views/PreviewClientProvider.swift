//
//  PreviewClientProvider.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import Foundation
import SwiftUI
import XMTP

struct PreviewClientProvider<Content: View>: View {
    @State private var client: Client?
    @State private var error: String?
    var content: (Client) -> Content

    init(@ViewBuilder _ content: @escaping (Client) -> Content) {
        self.content = content
    }

    var body: some View {
        if let error {
            Text(error)
        }

        if let client {
            content(client)
        } else {
            Text("Creating client…")
                .task {
                    do {
                        let wallet = try PrivateKey.generate()
                        let client = try await Client.create(account: wallet)
                        await MainActor.run {
                            self.client = client
                        }
                    } catch {
                        self.error = "Error creating preview client: \(error)"
                    }
                }
        }
    }
}

struct PreviewClientProvider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewClientProvider { client in
                Text(client.address)
            }
        }
    }
}
