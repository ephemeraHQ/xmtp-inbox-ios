//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI

struct SplashView: View {

    var isLoading: Bool
    var onNewDemo: () -> Void

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
            if isLoading {
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
            } else {
                Button(action: onNewDemo) {
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
    static var onNewDemo: () -> Void = { }
    static var previews: some View {
        SplashView(isLoading: false, onNewDemo: onNewDemo)
    }
}
