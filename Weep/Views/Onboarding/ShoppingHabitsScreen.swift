import SwiftUI

// MARK: - Shopping Frequency

struct ShoppingFrequencyScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("How often do you\nshop for groceries?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 32)

                    VStack(spacing: 10) {
                        ForEach(ShoppingFrequency.allCases, id: \.self) { frequency in
                            SelectionCard(
                                title: frequency.rawValue,
                                subtitle: frequency.description,
                                isSelected: viewModel.shoppingFrequency == frequency
                            ) {
                                viewModel.shoppingFrequency = frequency
                            }
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            BottomButtonBar {
                WeepButton(
                    title: "Continue",
                    isEnabled: viewModel.shoppingFrequency != nil
                ) { onContinue() }
            }
        }
    }
}

// MARK: - Shopping Locations

struct ShoppingLocationsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 40)

                    Text("Where do you\nusually shop?")
                        .font(WeepFont.largeTitle(32))
                        .foregroundColor(WeepColor.textPrimary)
                        .staggeredAppear(delay: 0.1)

                    Spacer().frame(height: 6)

                    Text("Select all that apply")
                        .font(WeepFont.caption())
                        .foregroundColor(WeepColor.textSecondary)
                        .staggeredAppear(delay: 0.15)

                    Spacer().frame(height: 32)

                    VStack(spacing: 10) {
                        ForEach(ShoppingLocation.allCases, id: \.self) { location in
                            SelectionCard(
                                title: location.rawValue,
                                isSelected: viewModel.shoppingLocations.contains(location)
                            ) {
                                if viewModel.shoppingLocations.contains(location) {
                                    viewModel.shoppingLocations.remove(location)
                                } else {
                                    viewModel.shoppingLocations.insert(location)
                                }
                            }
                        }
                    }
                    .staggeredAppear(delay: 0.2)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            BottomButtonBar {
                WeepButton(title: "Continue") { onContinue() }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}
