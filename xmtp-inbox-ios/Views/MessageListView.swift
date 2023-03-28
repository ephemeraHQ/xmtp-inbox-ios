//
//  MessageListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/5/22.
//

import Combine
import Foundation
import GRDB
import GRDBQuery
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
	var timeline: [MessageListEntry]
	var cancellables = [AnyCancellable]()
	var observer: TransactionObserver?
	var isPinnedToBottom = true

	init(loader: MessageLoader, messages: [DB.Message]) {
		self.loader = loader
		timeline = MessagesTableViewController.generateTimeline(messages: messages, isTyping: false)

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

		initScrollToBottomObserver()
	}

	static func generateTimeline(messages: [DB.Message], isTyping: Bool) -> [MessageListEntry] {
		var result: [MessageListEntry] = []
		var lastTimestamp: Date?

		let timestampWindow: TimeInterval = 60 * 10 // 10 minutes

		// swiftlint:disable force_unwrapping
		for message in messages {
			if lastTimestamp != nil, message.createdAt > lastTimestamp!.addingTimeInterval(timestampWindow) {
				lastTimestamp = message.createdAt
				result.append(.timestamp(lastTimestamp!))
			} else if lastTimestamp == nil {
				lastTimestamp = message.createdAt
				result.append(.timestamp(lastTimestamp!))
			}

			result.append(.message(message))
		}
		// swiftlint:enable force_unwrapping

		if isTyping {
			result.append(.typing)
		}

		return result
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

		// Add some extra space in case you're p close to the bottom
		if distanceFromBottom < height + 48 {
			isPinnedToBottom = true
		}
	}

	override func tableView(_: UITableView, willSelectRowAt _: IndexPath) -> IndexPath? {
		return nil
	}

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		return timeline.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var entry = timeline[indexPath.row]
		// swiftlint:disable force_cast
		let newCell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
		// swiftlint:enable force_cast

		if case var .message(message) = entry {
			message.loadPreview()
			entry = .message(message)
		}

		newCell.contentConfiguration = UIHostingConfiguration {
			MessageListEntryView(messagelistEntry: entry)
		}
		.margins(.vertical, 4)
		// Give it a bit more room for the last one
		.margins(.bottom, indexPath.row == timeline.count - 1 ? 8 : 4)

		return newCell
	}

	func scrollToBottom(animated: Bool = true, force: Bool = false) {
		print("Scrolling to bottom \(isPinnedToBottom)")

		if !isPinnedToBottom && !force {
			return
		}

		DispatchQueue.main.async { [self] in
			if timeline.isEmpty {
				return
			}

			tableView.reloadData()

			if let path = tableView.presentationIndexPath(forDataSourceIndexPath: IndexPath(row: timeline.count - 1, section: 0)) {
				tableView.scrollToRow(at: path, at: .bottom, animated: animated)
			}
		}
	}
}

struct MessagesTableView: UIViewControllerRepresentable {
	var loader: MessageLoader
	var messages: [DB.Message]
	var isTyping: Bool

	struct Coordinator {
		var loader: MessageLoader
		var controller: MessagesTableViewController

		init(loader: MessageLoader, messages: [DB.Message]) {
			self.loader = loader
			controller = MessagesTableViewController(loader: loader, messages: messages)
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(loader: loader, messages: messages)
	}

	func makeUIViewController(context: Context) -> MessagesTableViewController {
		context.coordinator.controller
	}

	func updateUIViewController(_ controller: MessagesTableViewController, context _: Context) {
		controller.timeline = MessagesTableViewController.generateTimeline(messages: messages, isTyping: isTyping)
		controller.tableView.reloadData()
		controller.scrollToBottom()
	}
}

struct MessageListView: View {
	let client: Client
	let db: DB
	let conversation: DB.Conversation

	@StateObject private var messageLoader: MessageLoader
	@StateObject private var typingListener: TypingListener
	@Query(ConversationMessagesRequest(conversationID: -1), in: \.dbQueue) var messages

	init(client: Client, conversation: DB.Conversation, db: DB) {
		self.client = client
		self.db = db
		self.conversation = conversation
		_messageLoader = StateObject(wrappedValue: MessageLoader(client: client, db: db, conversation: conversation))
		_messages = Query(ConversationMessagesRequest(conversationID: conversation.id ?? -1), in: \.dbQueue)
		_typingListener = StateObject(wrappedValue: TypingListener(
				websocketURL: AppGroup.defaults.string(forKey: "typingNotificationsServer"),
				topics: conversation.topics(db: db).map(\.topic),
				myAddress: client.address
			))
	}

	var body: some View {
		if messages.isEmpty {
			Text("No messages yet…")
				.foregroundColor(.secondary)
				.task(priority: .high) {
					await messageLoader.streamMessages()
				}
		} else {
			MessagesTableView(loader: messageLoader, messages: messages, isTyping: isTyping)
				.onChange(of: messages) { _ in
					typingListener.isTyping = false
				}
				.task(priority: .background) {
					await listenForTyping()
				}
				.onDisappear {
					typingListener.cancel()
				}
				.task(priority: .high) {
					await messageLoader.streamMessages()
				}
		}
	}

	var isTyping: Bool {
		guard let lastTypedAt = typingListener.lastTypedAt else {
			return false
		}

		if !typingListener.isTyping {
			return false
		}

		if let createdAt = messages.last?.createdAt {
			return lastTypedAt > createdAt
		}

		return true
	}

	func listenForTyping() async {
		do {
			try await typingListener.stream()
		} catch {
			print("Error listening for typing: \(error)")
			await listenForTyping()
		}
	}

	func loadMessages() async {
		do {
			print("loading messages!")
			try await messageLoader.load()
		} catch {
			print("ERROR LOADING MESSAGSE: \(error)")
			await MainActor.run {
				Flash.add(.error("Error loading messages: \(error)"))
			}
		}
	}
}
