import SwiftUI

struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 3) {
            // Filled portion
            Capsule()
                .fill(WeepColor.textPrimary)
                .frame(width: filledWidth, height: 3.5)

            // Remaining portion
            Capsule()
                .fill(WeepColor.divider)
                .frame(width: remainingWidth, height: 3.5)
        }
        .frame(width: 160)
        .animation(.snappy(duration: 0.3), value: progress)
    }

    private var filledWidth: CGFloat {
        max(20, 160 * progress)
    }

    private var remainingWidth: CGFloat {
        max(0, 160 - filledWidth - 3)
    }
}
