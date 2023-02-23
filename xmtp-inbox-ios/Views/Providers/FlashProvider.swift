//
//  ToastProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import SwiftUI

enum FlashMessageType {
	case error(String), success(String), info(String)
}

enum FlashMessagePosition {
	case top, bottom
}

struct FlashMessage: Identifiable {
	var id = UUID()
	var type: FlashMessageType
	var position: FlashMessagePosition = .top
}

class Flash: ObservableObject {
	static let shared = Flash()

	@Published var messages: [FlashMessage] = []

	private init() {}

	static func add(_ type: FlashMessageType, position: FlashMessagePosition = .top) {
		let message = FlashMessage(type: type, position: position)

		shared.messages.append(message)

		Task {
			try? await Task.sleep(for: .seconds(3))

			await MainActor.run {
				withAnimation {
					remove(message)
				}
			}
		}
	}

	static func remove(_ message: FlashMessage) {
		shared.messages.removeAll { $0.id == message.id }
	}
}

struct FlashMessageView: View {
	@GestureState var offset: CGFloat = 0
	var message: FlashMessage

	var title: String {
		switch message.type {
		case let .error(message):
			return message
		case let .success(message):
			return message
		case let .info(message):
			return message
		}
	}

	var background: Color {
		switch message.type {
		case .error:
			return Color.actionNegative
		case .success:
			return Color.actionPositive
		case .info:
			return Color.actionPrimary
		}
	}

	var body: some View {
		HStack {
			Text(title)
			Spacer()
		}
		.padding()
		.background(background)
		.foregroundColor(Color.actionPrimaryText)
		.cornerRadius(8)
		.shadow(radius: 8)
		.offset(x: offset)
		.gesture(DragGesture().updating($offset) { event, state, _ in
			state = event.translation.width
		}.onEnded { event in
			if abs(event.predictedEndTranslation.width) > 300 {
				withAnimation {
					Flash.remove(message)
				}
			}
		})
		.animation(.spring(), value: offset)
	}
}

struct FlashProvider<Content: View>: View {
	var content: () -> Content
	@ObservedObject var flash = Flash.shared

	var body: some View {
		ZStack {
			content()

			VStack(spacing: 16) {
				ForEach(topMessages) { message in
					FlashMessageView(message: message)
						.padding(.horizontal)
						.transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
				}
				.animation(.spring())

				Spacer()

				ForEach(bottomMessages) { message in
					FlashMessageView(message: message)
						.padding(.horizontal)
						.transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
				}
				.animation(.spring())
			}
		}
	}

	var topMessages: [FlashMessage] {
		flash.messages.filter { $0.position == .top }
	}

	var bottomMessages: [FlashMessage] {
		flash.messages.filter { $0.position == .bottom }
	}
}

struct FlashProvider_Previews: PreviewProvider {
	static var previews: some View {
		FlashProvider {
			NavigationView {
				List {
					Text("Some Content")
				}
				.task {
					try? await Task.sleep(for: .seconds(1))
					await MainActor.run {
						withAnimation {
							Flash.add(.error("This is an error.\nDoes the text wrap? Hopefully! Ok cool."))
							Flash.add(.info("This is info.\nDoes the text wrap? Hopefully! Ok cool."))
							Flash.add(.success("This is a success.\nDoes the text wrap? Hopefully! Ok cool."), position: .bottom)
						}
					}
				}
			}
		}
	}
}
