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

class MessageTableViewCell: UITableViewCell {
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		selectionStyle = .none
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
}

class MessagesTableViewController: UITableViewController {
	var loader: MessageLoader
	var cancellables = [AnyCancellable]()
	var observer: TransactionObserver?
	var isPinnedToBottom = true

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

		tableView.refreshControl = UIRefreshControl()
		tableView.refreshControl?.addTarget(self, action: #selector(loadEarlier), for: .valueChanged)

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)

		initDBObserver()
		initScrollToBottomObserver()
	}

	func initDBObserver() {
		observer = MessageObserver {
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
				self?.tableView.reloadData()
				self?.scrollToBottom(animated: true)
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

	deinit {
		for cancellable in cancellables {
			cancellable.cancel()
		}
	}

	func initScrollToBottomObserver() {
		loader.$mostRecentMessageID.removeDuplicates().sink { [weak self] _ in
			self?.scrollToBottom(animated: true)
		}.store(in: &cancellables)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func loadEarlier() {
		Task {
			do {
				try await loader.fetchEarlier()
			} catch {
				print("Error fetching earlier  \(error)")
			}

			await MainActor.run {
				tableView.refreshControl?.endRefreshing()
			}
		}
	}

	@objc private func keyboardWasShown(notification _: NSNotification) {
		scrollToBottom(animated: true)
	}

	override func viewWillAppear(_: Bool) {
		scrollToBottom(animated: false)
	}

	override func viewDidAppear(_: Bool) {
		Task {
			do {
				try await loader.load()
				await MainActor.run {
					tableView.reloadData()
					scrollToBottom(animated: true)
				}
			} catch {
				print("Error loading messages: \(error)")
			}
		}
	}

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.contentOffset.y == 0 {
			tableView.refreshControl?.beginRefreshing()

			loadEarlier()

			return
		}

		let height = scrollView.frame.size.height
		let contentYOffset = scrollView.contentOffset.y
		let distanceFromBottom = scrollView.contentSize.height - contentYOffset

		if distanceFromBottom < height + 48 {
			self.isPinnedToBottom = true
		}
	}

	override func tableView(_: UITableView, willSelectRowAt _: IndexPath) -> IndexPath? {
		return nil
	}

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		return loader.timeline.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let entry = loader.timeline[indexPath.row]
		// swiftlint:disable force_cast
		let newCell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
		// swiftlint:enable force_cast

		newCell.contentConfiguration = UIHostingConfiguration {
			MessageListEntryView(messagelistEntry: entry)
		}
		.margins(.vertical, 4)
		// Give it a bit more room for the last one
		.margins(.bottom, indexPath.row == loader.timeline.count - 1 ? 8 : 4)

		return newCell
	}

	func scrollToBottom(animated: Bool = true, force: Bool = false) {
		print("Scrolling to bottom \(isPinnedToBottom)")

		if !isPinnedToBottom && !force {
			return
		}

		DispatchQueue.main.async { [self] in
			if loader.timeline.isEmpty {
				return
			}

			tableView.reloadData()

			if let path = tableView.presentationIndexPath(forDataSourceIndexPath: IndexPath(row: loader.timeline.count - 1, section: 0)) {
				tableView.scrollToRow(at: path, at: .bottom, animated: animated)
			}
		}
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
