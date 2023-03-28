//
//  TypingListener.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 3/27/23.
//

import Foundation

class TypingListener: ObservableObject {
	@Published var isTyping = false
	@Published var lastTypedAt: Date?

	struct Message: Codable {
		var kind: String
		var sender: String
		var topic: String
		var timestamp: Date
	}

	var websocket: URLSessionWebSocketTask?
	var topics: [String]
	var myAddress: String
	var task: Task<Void, Never>?
	var isSubscribed: Bool = false
	var session: URLSession?
	var error: Error?

	init(websocketURL: String?, topics: [String], myAddress: String) {
		print("WEBSOCKET URL IS \(websocketURL)")

		if let websocketURL,
			 let url = URL(string: websocketURL) {
			session = URLSession(configuration: .ephemeral)
			websocket = session?.webSocketTask(with: url)
			print("GOT WEBSOCKET URL AND MADE ONE")
		} else {
			print("DID NOT GET WEBSOCKET URL")
		}

		self.topics = topics
		self.myAddress = myAddress
	}

	func subscribe() async throws {
		guard let websocket else {
			return
		}

		if isSubscribed {
			return
		}

		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601

		for topic in topics {
			let data = try encoder.encode(Message(
				kind: "subscribe",
				sender: "",
				topic: topic,
				timestamp: Date()
			))

			try await websocket.send(.data(data))
		}

		isSubscribed = true
	}

	func stream() async throws {
		guard let websocket else {
			return
		}

		websocket.resume()

		try await subscribe()
		websocket.receive { [weak self] result in
			do {
				switch result {
				case let .success(message):
					switch message {
					case let .data(data):
						try self?.handle(data: data)
					case let .string(string):
						try self?.handle(data: Data(string.utf8))
					@unknown default:
						print("??")
					}
					print("message")
				case let .failure(error):
					throw error
				}
			} catch {
				self?.error = error
			}
		}

		if error == nil {
			try await stream()
		}
	}

	func cancel() {
		guard let websocket else {
			return
		}

		websocket.cancel(with: .normalClosure, reason: nil)
	}

	func handle(data: Data) throws {
		Task {
			let jsonDecoder = JSONDecoder()

			let dateFormatter = ISO8601DateFormatter()
			dateFormatter.formatOptions.insert(.withFractionalSeconds)

			jsonDecoder.dateDecodingStrategy = .custom { decoder -> Date in
				let container = try decoder.singleValueContainer()
				let dateString = try container.decode(String.self)

				if let date = dateFormatter.date(from: dateString) {
					return date
				} else {
					throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
				}
			}
			let message = try jsonDecoder.decode(Message.self, from: data)

			print("HANDLING MESSAGE: \(message)")

			if message.kind != "typing" || message.sender == myAddress {
				return
			}

			await MainActor.run {
				self.isTyping = true
				self.lastTypedAt = message.timestamp
			}

			// swiftlint:disable force_try
			try! await Task.sleep(for: .seconds(1))

			await MainActor.run {
				// swiftlint:disable force_unwrapping
				self.isTyping = self.lastTypedAt != nil && (Date().addingTimeInterval(-1) < self.lastTypedAt!)
				print("[in task] \(self.lastTypedAt != nil && (Date().addingTimeInterval(-1) < self.lastTypedAt!))")
				// swiftlint:enable force_unwrapping
			}
		}
	}
}
