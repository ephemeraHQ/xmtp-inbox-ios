//
//  ConversationListItemView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/12/23.
//

import SwiftUI
import XMTP
import web3

struct ConversationListItemView: View {

    enum EnsError: Error {
        case invalidURL
    }

    var conversation: XMTP.Conversation

    @State private var ensClient: EthereumHttpClient?

    @State private var displayName: String?

    var body: some View {
        ZStack {
            Text(displayName ?? conversation.peerAddress)
        }
        .task {
            await loadEnsName()
        }
    }

    func setupEnsClient() throws -> EthereumHttpClient {
        guard let ensClient = self.ensClient else {
            guard let clientUrl = URL(string: ProcessInfo.processInfo.environment["INFURA_MAINNET_URL"] ?? "") else {
                throw EnsError.invalidURL
            }
            let newEnsClient = EthereumHttpClient(url: clientUrl, network: .mainnet)
            self.ensClient = newEnsClient
            return newEnsClient
        }
        return ensClient
    }

    func loadEnsName() async {
        do {
            let ensClient = try setupEnsClient()
            let nameService = EthereumNameService(client: ensClient)

            let results = try await nameService.resolve(addresses: [EthereumAddress(conversation.peerAddress)])
            if results.count > 0 {
                switch results[0].output {
                case let .resolved(value):
                    print("Resolved ENS: \(value)")
                    await MainActor.run {
                        self.displayName = value
                    }
                case let .couldNotBeResolved(error):
                    print("Could not resolve ENS: \(error)")
                }
            } else {
                print("No ENS results for address: \(conversation.peerAddress)")
            }
        } catch {
            print("Error resolving ens: \(error)")
        }
    }
}
