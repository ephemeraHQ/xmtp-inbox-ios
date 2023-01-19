//
//  EnsImageView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import SwiftUI
import web3
import ENSKit
import IGIdenticon

enum EnsError: Error {
    case invalidURL
}

struct EnsImageView: View {

    var imageSize: CGFloat

    var peerAddress: String

    @State private var ethClient: EthereumHttpClient?

    @State private var ensKit: ENSKit?

    @State private var ensImage: UIImage?

    var body: some View {
        let identicon = Identicon().icon(
            from: peerAddress,
            size: CGSize(width: imageSize, height: imageSize)
        )
        ZStack {
            if self.ensImage != nil {
                // swiftlint:disable force_unwrapping
                Image(uiImage: self.ensImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(width: imageSize, height: imageSize)
                // swiftlint:enable force_unwrapping
            } else if identicon != nil {
                // swiftlint:disable force_unwrapping
                Image(uiImage: identicon!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(width: imageSize, height: imageSize)
                // swiftlint:enable force_unwrapping
            } else {
                Color.backgroundSecondary
                    .clipShape(Circle())
                    .frame(width: imageSize, height: imageSize)
            }
        }
        .task {
            await loadEnsData()
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

    func loadEnsData() async {
        do {
            let ethClient = try setupEthClient()
            let nameService = EthereumNameService(client: ethClient)

            let results = try await nameService.resolve(addresses: [EthereumAddress(peerAddress)])
            if results.count > 0 {
                switch results[0].output {
                case let .resolved(value):
                    await loadEnsImage(ensName: value)
                case .couldNotBeResolved:
                    return
                }
            }
        } catch {
            print("Error resolving ENS name: \(error)")
        }
    }

    func setupEnsKit() throws -> ENSKit {
        guard let ensKit = self.ensKit else {
            guard let infuraUrl = Constants.infuraUrl else {
                throw EnsError.invalidURL
            }
            let newEnsKit = ENSKit(jsonrpcClient: InfuraEthereumAPI(url: infuraUrl))
            self.ensKit = newEnsKit
            return newEnsKit
        }
        return ensKit
    }

    // ENSKit relies on an ENS name to resolve an avatar. We can load images
    // and ENS names in parallel once we can resolve data using addresses:
    // https://github.com/Planetable/ENSKit/issues/5
    func loadEnsImage(ensName: String) async {
        do {
            let ensKit = try setupEnsKit()
            let avatar = await ensKit.avatar(name: ensName)

            guard let imageData = avatar else {
                print("No image set for ENS name: \(ensName)")
                return
            }
            await MainActor.run {
                withAnimation {
                    self.ensImage = UIImage(data: imageData)
                }
            }
        } catch {
            print("Error resolving ENS avatar: \(error)")
        }
    }
}
