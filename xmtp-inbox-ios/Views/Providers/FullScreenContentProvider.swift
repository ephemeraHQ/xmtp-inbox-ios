//
//  FullScreenContentProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import QuickLook
import SDWebImageSwiftUI
import UIKit
import SwiftUI
import UIKit

extension URL: Identifiable {
	public var id: String {
		absoluteString
	}
}

struct QuickLookPreview: UIViewControllerRepresentable {
	let selectedURL: URL
	let urls: [URL]

	func makeUIViewController(context _: Context) -> UIViewController {
		return QuickLookPreviewController(urls: urls, selectedURL: selectedURL)
	}

	func updateUIViewController(_: UIViewController, context _: Context) {}
}

// class AppQLPreviewController: UIViewController {
//	let selectedURL: URL
//	let urls: [URL]
//
//	var qlController: QLPreviewController?
//
//	init(selectedURL: URL, urls: [URL]) {
//		self.selectedURL = selectedURL
//		self.urls = urls
//		super.init(nibName: nil, bundle: nil)
//	}
//
//	@available(*, unavailable)
//	required init?(coder _: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//
//	override func viewWillAppear(_ animated: Bool) {
//		super.viewWillAppear(animated)
//		if qlController == nil {
//			qlController = QLPreviewController()
//			qlController?.dataSource = self
//			qlController?.delegate = self
//			qlController?.currentPreviewItemIndex = urls.firstIndex(of: selectedURL) ?? 0
//			present(qlController!, animated: true)
//		}
//	}
// }

class QuickLookPreviewController: UIViewController, QLPreviewControllerDataSource {
	let urls: [URL]
	let selectedURL: URL
	var fileURL: URL?

	init(urls: [URL], selectedURL: URL) {
		self.urls = urls
		self.selectedURL = selectedURL

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		let quickLookController = QLPreviewController()
		quickLookController.dataSource = self
		quickLookController.delegate = self
		quickLookController.currentPreviewItemIndex = 0

		Task {
			do {
				let data = try await URLSession.shared.data(from: self.selectedURL).0

				// Give the file a name and append it to the file path
				fileURL = URL.temporaryDirectory.appendingPathComponent(
					selectedURL.lastPathComponent
				)

				guard let fileUrl = fileURL else {
					print("no file url?")
					return
				}

				try data.write(to: fileUrl, options: .atomic)

				// Make sure the file can be opened and then present the pdf
				if QLPreviewController.canPreview(fileUrl as QLPreviewItem) {
					quickLookController.currentPreviewItemIndex = 0
					present(quickLookController, animated: true, completion: nil)
				}
			} catch {
				// cant find the url resource
			}
		}
	}

	func numberOfPreviewItems(in _: QLPreviewController) -> Int {
		return urls.count
	}

	func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
		// swiftlint:disable force_unwrapping
		return fileURL! as QLPreviewItem
		// swiftlint:enable force_unwrapping
	}
}

extension QuickLookPreviewController: QLPreviewControllerDelegate {
	func previewController(_: QLPreviewController, editingModeFor _: QLPreviewItem) -> QLPreviewItemEditingMode {
		.createCopy
	}

	func previewControllerWillDismiss(_: QLPreviewController) {
		dismiss(animated: true)
	}
}

@MainActor
public class QuickLook: ObservableObject {
	@Published public var url: URL?
	@Published public var urls: [URL] = []

	public init() {}
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
	@StateObject var quickLook = QuickLook()
	@StateObject var fullScreenContent = FullScreenContentContainer()

	@Namespace var namespace

	@GestureState var dragDistance: CGFloat = 0
	@State var dragAmount = 0.0

	var content: () -> Content

	var body: some View {
		ZStack {
			content()
				.environmentObject(quickLook)
				.fullScreenCover(item: $quickLook.url, content: { url in
					QuickLookPreview(selectedURL: url, urls: quickLook.urls)
						.background(Color.clear)
				})
		}
	}
}

struct FullScreenable: ViewModifier {
	var id = UUID().uuidString
	var url: URL

	@EnvironmentObject var quickLook: QuickLook
	@State private var isLoading = false

	func body(content this: Content) -> some View {
		this.overlay {
			if isLoading {
				ProgressView()
			}
		}
		.onTapGesture {
			quickLook.urls = [url]
			quickLook.url = url
		}
	}
}

extension View {
	func fullScreenable(url: URL) -> some View {
		modifier(FullScreenable(url: url))
	}
}

struct FullScreenImageViewerProviderPreviewsContent: View {
	var body: some View {
		VStack {
			Spacer()
			HStack {
				Text("Hi")
				Spacer()
				WebImage(url: URL(string: "https://media1.giphy.com/media/Fxw4gRt5Yhaw5FdAfc/giphy.webp"))
					.scaledToFit()
					.frame(height: 200)
					.animation(.easeInOut)
					// swiftlint:disable force_unwrapping
					.fullScreenable(url: URL(string: "https://media1.giphy.com/media/Fxw4gRt5Yhaw5FdAfc/giphy.webp")!)
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
