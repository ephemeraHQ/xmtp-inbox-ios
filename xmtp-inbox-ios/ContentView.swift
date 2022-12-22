//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP


struct ContentView: View {
    
    enum AuthStatus {
        case unknown, connecting, connected(Client), error(String)
    }
    
    @State private var status: AuthStatus = .unknown

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

            let buttonHeight = 58.0

            switch status {
            case .unknown:
                VStack {
                    Image("XMTPGraphic")
                        .resizable()
                        .scaledToFit()

                    Button(action: generateWallet) {
                        Text("Try demo mode")
                            .kerning(0.5)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                            .background(Color.actionPrimary)
                            .foregroundColor(.actionPrimaryText)
                            .font(.H1)
                            .clipShape(Capsule())
                            .padding()
                    }
                }
            case .connecting:
                VStack {
                    Image("XMTPGraphic")
                        .resizable()
                        .scaledToFit()
                    
                    ZStack {
                        Text("")
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                            .background(Color.actionPrimary)
                            .clipShape(Capsule())
                            .padding()
                        
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: .actionPrimaryText)
                            )
                    }
                }
            case let .connected(client):
                HomeView(client: client)
            case let .error(error):
                Text("Error: \(error)").foregroundColor(.actionNegative)
            }
        }
    }

    func generateWallet() {
        Task {
            do {
                await MainActor.run {
                    self.status = .connecting
                }
                let wallet = try PrivateKey.generate()
                let client = try await Client.create(account: wallet)
                
                await MainActor.run {
                    withAnimation {
                        self.status = .connected(client)
                    }
                }
            } catch {
                await MainActor.run {
                    self.status = .error("Error generating wallet: \(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
