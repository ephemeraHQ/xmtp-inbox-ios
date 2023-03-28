import Foundation
import SwiftUI

struct TypingIndicator: View {
	@State private var current = 3

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			ForEach(0 ..< 3) { i in
				Capsule()
					.foregroundColor((self.current == i) ? .backgroundTertiary : .secondary)
					.frame(width: self.ballSize, height: self.ballSize)
			}
		}
		.animation(Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.1).speed(2))
		.onAppear {
			var i = 0
			Timer.scheduledTimer(withTimeInterval: self.speed, repeats: true) { _ in
				i += 1
				self.current = i % 3
			}
		}
	}

	// MAKR: - Drawing Constants
	let ballSize: CGFloat = 8
	let speed: Double = 0.3
}

struct TypingIndicator_Previews: PreviewProvider {
	static var previews: some View {
		TypingIndicator()
			.padding()
			.background(Color.backgroundSecondary)
			.cornerRadius(8)
	}
}
