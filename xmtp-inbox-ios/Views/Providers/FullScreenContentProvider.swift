//
//  FullScreenContentProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import SwiftUI

struct FullScreenContentKey: EnvironmentKey {
	static var defaultValue = FullScreenContentContainer()
}

struct FullScreenContentNamespace: EnvironmentKey {
	static var defaultValue = Namespace().wrappedValue
}

extension EnvironmentValues {
	var fullScreenContent: FullScreenContentContainer {
		get { self[FullScreenContentKey.self] }
		set { self[FullScreenContentKey.self] = newValue }
	}

	var fullScreenContentNamespace: Namespace.ID {
		get { self[FullScreenContentNamespace.self] }
		set { self[FullScreenContentNamespace.self] = newValue }
	}
}

enum FullScreenContentType {
	case image(Image)
}

class FullScreenContentContainer: ObservableObject {
	@Published var id: String = ""
	@Published var isVisible: Bool = false
	@Published var content: FullScreenContentType?
	@Namespace var namespace

	func show(id: String, content: FullScreenContentType) {
		self.id = id

		withAnimation(.easeInOut(duration: 0.3)) {
			self.isVisible = true
			self.content = content
		}
	}
}

struct FullScreenContentProvider<Content: View>: View {
	@StateObject var fullScreenContent = FullScreenContentContainer()

	@Namespace var namespace

	@GestureState var dragDistance: CGFloat = 0
	@State var dragAmount = 0.0

	var content: () -> Content

	var body: some View {
		ZStack {
			content()
				.environment(\.fullScreenContent, fullScreenContent)
				.environment(\.fullScreenContentNamespace, namespace)

			if fullScreenContent.isVisible {
				Color.black
					.ignoresSafeArea(.all)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.transition(.opacity)
					.opacity(self.fullScreenContent.content == nil ? 0 : 1 - dragAmount)
					.animation(.easeIn)

				VStack {
					HStack(alignment: .top) {
						Button(action: dismiss) {
							Image(systemName: "xmark.circle.fill")
								.foregroundColor(.secondary)
						}
						.padding(.leading)
						Spacer()
					}
					Spacer()
				}
				.transition(.move(edge: .leading))
			}

			if let fullScreenContent = fullScreenContent.content {
				VStack {
					switch fullScreenContent {
					case let .image(image):
						image
							.resizable()
							.scaledToFit()
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.matchedGeometryEffect(id: self.fullScreenContent.id, in: namespace, isSource: true)
							.animation(.easeInOut)
					}
				}
				.scaleEffect(max(1 - dragAmount, 0.4))
				.offset(y: dragDistance)
				.gesture(DragGesture()
					.onEnded { event in
						self.dragAmount = 0

						if abs(event.predictedEndTranslation.height) > 100 {
							withAnimation(.easeInOut) {
								dismiss()
							}
						}
					}
					.updating($dragDistance) { event, state, _ in
						state = event.translation.height
					})
				.onChange(of: dragDistance) { distance in
					self.dragAmount = min(1, distance / (Double(UIScreen.main.bounds.height) / 2))
				}
			}
		}
	}

	func dismiss() {
		withAnimation(.easeInOut(duration: 0.3)) {
			self.fullScreenContent.content = nil
		}

		Task {
			try await Task.sleep(for: .milliseconds(200))
			await MainActor.run {
				withAnimation(.easeInOut(duration: 0.3)) {
					self.fullScreenContent.isVisible = false
				}
			}
		}
	}
}

struct FullScreenable: ViewModifier {
	@Environment(\.fullScreenContent) var fullScreenContent
	@Environment(\.fullScreenContentNamespace) var fullScreenContentNamespace

	var id = UUID().uuidString
	var content: FullScreenContentType

	func body(content this: Content) -> some View {
		this.overlay {
			if !fullScreenContent.isVisible {
				Color.clear
					.contentShape(Rectangle())
					.onTapGesture {
						fullScreenContent.show(id: id, content: content)
					}
					.matchedGeometryEffect(id: id, in: fullScreenContentNamespace, isSource: !fullScreenContent.isVisible)
					.animation(.easeInOut)
			}
		}
	}
}

extension View {
	func fullScreenable(content: FullScreenContentType) -> some View {
		modifier(FullScreenable(content: content))
	}
}

struct FullScreenImageViewerProviderPreviewsContent: View {
	@Environment(\.fullScreenContent) var fullScreenContent

	var body: some View {
		VStack {
			Spacer()
			HStack {
				Text("Hi")
				Spacer()
				Image("XMTPGraphic")
					.resizable()
					.scaledToFit()
					.frame(height: 200)
					.fullScreenable(content: .image(Image("XMTPGraphic")))
			}
		}
	}
}

struct FullScreenImageViewerProvider_Previews: PreviewProvider {
	static var previews: some View {
		FullScreenContentProvider {
			List {
				FullScreenImageViewerProviderPreviewsContent()
			}
		}
	}
}
