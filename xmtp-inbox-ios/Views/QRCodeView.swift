//
//  QRCodeVIew.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 1/31/23.
//

import SwiftUI

struct QRCodeView: View {
	var data: Data

	@State private var image: Image?

	var body: some View {
		if let image {
			VStack {
				image
				Text("Scan this QR code with your phone.")
			}
		} else {
			ProgressView("Generating…")
				.onAppear {
					loadImage()
				}
		}
	}

	private func loadImage() {
		let uiImage = QRCode.generate(for: data)
		withAnimation {
			self.image = Image(uiImage: uiImage)
		}
	}
}

struct QRCodeVIew_Previews: PreviewProvider {
	static var previews: some View {
		QRCodeView(data: Data("hello world".utf8))
	}
}
