//
//  Web3StorageTokenView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/27/23.
//

import SwiftUI

struct Web3StorageTokenView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var verifier = Web3StorageVerifier()
	var onVerified: (String) -> Void

	var body: some View {
		VStack(alignment: .leading) {
			Spacer()
			Text("XMTP Inbox uses web3.storage to store your attachments")
				.font(.title)
				.padding(.bottom)
			Text("To send attachments with your messages, you’ll need an API token from web3.storage.")
				.padding(.bottom)

			Button(action: {
				UIApplication.shared.open(Web3StorageVerifier.loginURL)
			}) {
				Text("Get an API token")
					.frame(maxWidth: .infinity)
			}
			.controlSize(.large)
			.buttonStyle(.borderedProminent)

			SheetButton(label: {
				Text("Enter your API token")
					.frame(maxWidth: .infinity)
			}, sheet: { dismiss in
				List {
					Section {
						Text("Enter your web3.storage API token:")
							.listRowSeparator(.hidden)
						AutofocusProvider {
							TextEditor(text: $verifier.token)
								.lineLimit(10)
								.textFieldStyle(.roundedBorder)
								.font(.monospaced(.body)())
								.frame(minHeight: 200)
						}
					}

					Section {
						Button(action: {
							withAnimation {
								verifier.status = .verifying
							}
							Task {
								await verifier.verify()

								if verifier.status == .verified {
									await MainActor.run {
										onVerified(verifier.token)
										dismiss()
									}
								}
							}
						}) {
							Text(label)
								.frame(maxWidth: .infinity)
								.opacity(showSpinner ? 0 : 1)
						}
						.overlay {
							if showSpinner {
								ProgressView()
									.foregroundColor(.backgroundPrimary)
							}
						}
						.listRowInsets(.init())
						.listRowSeparator(.hidden)
						.buttonStyle(.borderedProminent)
					}

					Section {
						if case let .error(message) = verifier.status {
							Text(message)
								.frame(maxWidth: .infinity)
								.padding(8)
								.foregroundColor(.white)
								.cornerRadius(8)
								.listRowInsets(.init())
								.listRowBackground(Color.actionNegative)
						}
					}
				}
			})
			.controlSize(.large)
			.buttonStyle(.borderedProminent)

			Spacer()
		}.padding()
	}

	var label: String {
		switch verifier.status {
		case .verified:
			return "Done"
		case .waiting:
			return "Verify"
		case .verifying:
			return "Verifying…"
		case .error:
			return "Verify"
		}
	}

	var showSpinner: Bool {
		switch verifier.status {
		case .verifying:
			return true
		default:
			return false
		}
	}
}

struct Web3StorageTokenView_Previews: PreviewProvider {
	static var previews: some View {
		Web3StorageTokenView { _ in }
	}
}
