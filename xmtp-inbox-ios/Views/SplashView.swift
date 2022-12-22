//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI

struct SplashView: View {
    
    var isLoading: Bool
    var generateWallet: () -> Void
    
    var body: some View {
        VStack {
            Image("XMTPGraphic")
                .resizable()
                .scaledToFit()
            
            Text("Your interoperable web3 inbox")
                .kerning(0.5)
                .font(.Display1)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
                .padding(.horizontal)
            
            Text ("You’re just a few steps away from secure, wallet-to-wallet messaging")
                .font(.Body1)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
                .padding(.horizontal)
            
            let buttonHeight = 58.0;
            if (isLoading) {
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
        }
    }
}
    
struct SplashView_Previews: PreviewProvider {
    static var fakeGenerate : () -> Void = { }
    static var previews: some View {
        SplashView(isLoading: false, generateWallet: fakeGenerate)
    }
}
