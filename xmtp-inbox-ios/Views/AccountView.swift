//
//  AccountView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/26/23.
//

import SwiftUI
import XMTP

struct AccountView: View {

    let client: Client

    private let supportUrl = "https://github.com/xmtp-labs/xmtp-inbox-ios/issues"

    private let privacyUrl = "https://xmtp.org/privacy"

    @EnvironmentObject var auth: Auth

    @State private var showSignOutAlert = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
                List {
                    VStack(alignment: .center) {
                        EnsImageView(imageSize: 80, peerAddress: client.address)
                            .padding()

                        HapticButton(action: {
                            UIPasteboard.general.string = client.address
                        }) {
                            HStack {
                                Image("EthereumIcon")
                                    .renderingMode(.template)
                                    .colorMultiply(.textPrimary)
                                    .frame(width: 20.0, height: 20.0)

                                Text(client.address.truncatedAddress())
                                    .font(.Body1B)
                                    .foregroundColor(.textPrimary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.backgroundPrimary)
                            .clipShape(Capsule())
                            .shadow(color: .backgroundSecondary, radius: 3, x: 0, y: 1)
                        }
                    }
                    .listRowBackground(Color.backgroundPrimary)
                    .frame(maxWidth: .infinity)

                    Section {
                        HapticButton {
                            guard let url = URL(string: privacyUrl) else {
                                return
                            }
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            UIApplication.shared.open(url)
                        } label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.actionPrimary)
                                        .opacity(0.2)
                                        .frame(width: 40, height: 40)

                                    Image("PrivacyIcon")
                                        .foregroundColor(Color.actionPrimary)
                                        .frame(width: 24.0, height: 24.0)
                                }
                                .padding(.trailing, 4)

                                Text("privacy")
                                    .font(.Body1B)
                                    .foregroundColor(Color.textPrimary)
                            }
                        }
                        .listRowBackground(Color.backgroundTertiary)
                        .listRowSeparator(.hidden)

                        HapticButton {
                            guard let url = URL(string: supportUrl) else {
                                return
                            }
                            UIApplication.shared.open(url)
                        } label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.actionPrimary)
                                        .opacity(0.2)
                                        .frame(width: 40, height: 40)

                                    Image("SupportIcon")
                                        .foregroundColor(Color.actionPrimary)
                                        .frame(width: 24.0, height: 24.0)
                                }
                                .padding(.trailing, 4)

                                Text("support")
                                    .font(.Body1B)
                                    .foregroundColor(Color.textPrimary)
                            }
                        }
                        .listRowBackground(Color.backgroundTertiary)
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        HapticButton {
                            showSignOutAlert.toggle()
                        } label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.actionNegative)
                                        .opacity(0.2)
                                        .frame(width: 40, height: 40)

                                    Image("DisconnectIcon")
                                        .foregroundColor(Color.actionNegative)
                                        .frame(width: 24.0, height: 24.0)
                                }
                                .padding(.trailing, 4)

                                Text("disconnect-wallet")
                                    .font(.Body1B)
                                    .foregroundColor(Color.textPrimary)
                            }
                        }
                        .listRowBackground(Color.backgroundTertiary)
                        .listRowSeparator(.hidden)
                    }

                    VStack(alignment: .center) {
                        Text(footer)
                            .font(.Body2)
                            .foregroundColor(Color.textScondary)
                            .listRowSeparator(.hidden)
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollContentBackground(.hidden)
                .background(Color.backgroundPrimary)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("account")
            .navigationBarItems(trailing: Button {
                dismiss()
            } label: {
                Image("XIcon")
                    .renderingMode(.template)
                    .colorMultiply(.textPrimary)
            })
            .navigationBarTitleDisplayMode(.inline)
            .alert("disconnect-cta", isPresented: $showSignOutAlert) {
                Button("cancel", role: .cancel) { }
                Button("disconnect", role: .destructive) {
                    auth.signOut()
                }
            }
        }
    }

    var footer: String {
        "\(Constants.version) (\(Constants.buildNumber)) \(Constants.xmtpEnv)"
    }
}
