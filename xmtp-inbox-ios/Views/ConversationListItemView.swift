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

    @State private var ethClient: EthereumHttpClient?

    @State private var ensName: String?

    var body: some View {
        HStack(alignment: .top) {
            EnsImageView(imageSize: 48.0, peerAddress: conversation.peerAddress)
            Text(ensName ?? conversation.peerAddress.truncatedAddress())
                .padding(.horizontal, 4.0)
                .lineLimit(1)
                .font(.Body1B)
        }
        .task {
            await loadEnsName()
        }
    }

    func setupEthClient() throws -> EthereumHttpClient {
        guard let ethClient = self.ethClient else {
            guard let infuraUrl = Constants.infuraUrl else {
                throw EnsError.invalidURL
            }
            let newEthClient = EthereumHttpClient(url: infuraUrl, network: .mainnet)
            self.ethClient = newEthClient
            return newEthClient
        }
        return ethClient
    }

    func loadEnsName() async {
        do {
            let ethClient = try setupEthClient()
            let nameService = EthereumNameService(client: ethClient)

            let results = try await nameService.resolve(addresses: [EthereumAddress(conversation.peerAddress)])
            if results.count > 0 {
                switch results[0].output {
                case let .resolved(value):
                    print("Resolved ENS name: \(value)")
                    await MainActor.run {
                        self.ensName = value
                    }
                case let .couldNotBeResolved(error):
                    print("Could not resolve ENS name: \(error)")
                }
            } else {
                print("No ENS name results for address: \(conversation.peerAddress)")
            }
        } catch {
            print("Error resolving ENS name: \(error)")
        }
    }
}
