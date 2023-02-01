//
//  QRCode.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 1/31/23.
//

import CoreImage.CIFilterBuiltins
import UIKit

struct QRCode {
	static func generate(for data: Data) -> UIImage {
		let context = CIContext()
		let filter = CIFilter.qrCodeGenerator()
		filter.setValue(data, forKey: "inputMessage")

		// swiftlint:disable force_unwrapping
		let outputImage = filter.outputImage!
		let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
		let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!
		// swiftlint:enable force_unwrapping

		let image = UIImage(cgImage: cgImage)

		return image
	}
}
