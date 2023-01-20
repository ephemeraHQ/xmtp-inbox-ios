//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI

struct SplashView: View {

    var isConnecting: Bool
    var onTryDemo: () -> Void
    var onConnectWallet: () -> Void

    var body: some View {
        VStack {
            Image("XMTPGraphic")
                .resizable()
                .scaledToFit()

            Text("splash-title")
                .kerning(0.5)
                .font(.Display1)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
                .padding(.horizontal)

            Text("splash-description")
                .font(.Body1)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
                .padding(.horizontal)

            let buttonHeight = 58.0
            if isConnecting {
                Button(action: onTryDemo) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .actionPrimaryText))
                    Text("awaiting-signature")
                        .kerning(0.5)
                        .foregroundColor(.actionPrimaryText)
                        .font(.H1)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                .background(Color.actionPrimary)
                .clipShape(Capsule())
                .padding()
//                ZStack {
//                    Text("awaiting-signature")
//                        .padding()
//                        .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                        .background(Color.actionPrimary)
//                        .clipShape(Capsule())
//                        .padding()
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: .actionPrimaryText))
//                }
            } else {
                Button(action: onTryDemo) {
                    Text("try-demo-cta")
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
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var onTryDemo: () -> Void = { }
    static var onConnectWallet: () -> Void = { }
    static var previews: some View {
        SplashView(isConnecting: false, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet)
    }
}
