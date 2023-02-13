//
//  MessageListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/5/22.
//

import Combine
import GRDB
import SwiftUI
import UIKit
import XMTP

class MessageTableViewCell: UITableViewCell {}

class MessageObserver: TransactionObserver {
	var callback: () -> Void

	init(callback: @escaping () -> Void) {
		self.callback = callback
	}

	func databaseDidCommit(_: GRDB.Database) {}

	func databaseDidRollback(_: GRDB.Database) {}

	func databaseDidChange(with _: GRDB.DatabaseEvent) {
		callback()
	}

	func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool {
		if case let .insert(tableName) = eventKind, tableName == "message" {
			return true
		} else {
			return false
		}
	}
}

class MessagesTableViewController: UITableViewController {
	var loader: MessageLoader
	var cancellables = [AnyCancellable]()
	var observer: TransactionObserver?

	init(loader: MessageLoader) {
		self.loader = loader

		super.init(style: .plain)

		tableView.dataSource = self
		tableView.delegate = self

		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "messageCell")

		tableView.separatorInset = .zero
		tableView.separatorStyle = .none
		tableView.keyboardDismissMode = .interactive

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)

		observer = MessageObserver {
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
				self.tableView.reloadData()
				self.scrollToBottom(animated: true)
			}
		}

		if let observer {
			do {
				try DB.read { db in
					db.add(transactionObserver: observer)
				}
			} catch {
				print("Error adding observer")
			}
		}
	}

	override var inputAccessoryView: UIView? {
		return UIHostingController(rootView: Text("Hi")).view
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func keyboardWasShown(notification _: NSNotification) {
		scrollToBottom(animated: true)
	}

	override func viewDidAppear(_: Bool) {
		Task {
			do {
				try await loader.load()
				await MainActor.run {
					tableView.reloadData()
					scrollToBottom(animated: false)
				}
			} catch {
				print("Error loading messages: \(error)")
			}
		}
	}

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		loader.messages.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = loader.messages[indexPath.row]
		// swiftlint:disable force_cast
		let newCell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
		// swiftlint:enable force_cast

		newCell.contentConfiguration = UIHostingConfiguration {
			MessageCellView(isFromMe: message.senderAddress == loader.client.address, message: message)
		}

		return newCell
	}

	func scrollToBottom(animated: Bool = true) {
		if loader.messages.isEmpty {
			return
		}

		tableView.scrollToRow(at: IndexPath(row: loader.messages.count - 1, section: 0), at: .bottom, animated: animated)
	}
}

struct MessagesTableView: UIViewControllerRepresentable {
	var loader: MessageLoader

	struct Coordinator {
		var loader: MessageLoader
		var controller: MessagesTableViewController

		init(loader: MessageLoader) {
			self.loader = loader
			controller = MessagesTableViewController(loader: loader)
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(loader: loader)
	}

	func makeUIViewController(context: Context) -> MessagesTableViewController {
		context.coordinator.controller
	}

	func updateUIViewController(_: MessagesTableViewController, context _: Context) {
		print("hi updateuiview")
		// nothin yet
	}
}

struct MessageListView: View {
	let client: Client
	let conversation: DB.Conversation

	@State private var errorViewModel = ErrorViewModel()
	@StateObject private var messageLoader: MessageLoader

	init(client: Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation
		_messageLoader = StateObject(wrappedValue: MessageLoader(client: client, conversation: conversation))
	}

	// TODO(elise and pat): Paginate list of messages
	var body: some View {
		MessagesTableView(loader: messageLoader)
	}

	func loadMessages() async {
		do {
			print("loading messages!")
			try await messageLoader.load()
		} catch {
			print("ERROR LOADING MESSAGSE: \(error)")
			await MainActor.run {
				self.errorViewModel.showError("Error loading messages: \(error)")
			}
		}
	}
}
