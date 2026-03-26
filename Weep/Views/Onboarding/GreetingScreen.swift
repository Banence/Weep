import SwiftUI

struct GreetingScreen: View {
    let name: String
    let onContinue: () -> Void

    private let greetingWords = [
        "Hey", "Hola", "Bonjour", "Ciao", "Hej",
        "Olá", "Hallo", "Привет", "こんにちは",
        "안녕", "Merhaba", "Γεια σου", "Здраво",
    ]

    @State private var displayedText = ""
    @State private var cursorVisible = false
    @State private var cursorBlinking = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Greeting text + cursor
                HStack(alignment: .center, spacing: 0) {
                    Text(displayedText)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(WeepColor.textPrimary)

                    Rectangle()
                        .fill(WeepColor.accent)
                        .frame(width: 2.5, height: 34)
                        .opacity(cursorVisible ? (cursorBlinking ? 0 : 1) : 0)
                        .animation(
                            cursorBlinking
                                ? .easeInOut(duration: 0.53).repeatForever(autoreverses: true)
                                : .easeInOut(duration: 0.15),
                            value: cursorBlinking
                        )
                }
                .frame(minHeight: 48)

                Text("Let's set things up so Weep\nworks perfectly for you.")
                    .font(WeepFont.body(17))
                    .foregroundColor(WeepColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 8)
                    .animation(.easeOut(duration: 0.6), value: showSubtitle)
            }

            Spacer()

            BottomButtonBar {
                WeepButton(title: "Let's go") {
                    animationTask?.cancel()
                    onContinue()
                }
            }
            .opacity(showButton ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: showButton)
        }
        .onAppear { startCycle() }
        .onDisappear { animationTask?.cancel() }
    }

    private func startCycle() {
        animationTask = Task { @MainActor in
            // Show cursor with a brief blink before typing
            await wait(300)
            guard alive else { return }
            cursorVisible = true
            cursorBlinking = true
            await wait(600)
            guard alive else { return }

            // Stop blinking, start typing
            cursorBlinking = false
            await wait(100)
            guard alive else { return }

            // Type first greeting
            await typeString("\(greetingWords[0]), \(name)")
            guard alive else { return }

            // Pause with blinking cursor
            cursorBlinking = true
            await wait(400)
            guard alive else { return }

            // Fade in subtitle + button
            showSubtitle = true
            await wait(400)
            guard alive else { return }
            showButton = true
            await wait(2500)

            // Cycle through languages
            while alive {
                for i in 1..<greetingWords.count {
                    guard alive else { return }

                    // Stop blinking, start deleting
                    cursorBlinking = false
                    await wait(80)
                    guard alive else { return }

                    await deleteAll()
                    guard alive else { return }

                    // Brief pause with cursor
                    await wait(200)
                    guard alive else { return }

                    // Type new greeting
                    await typeString("\(greetingWords[i]), \(name)")
                    guard alive else { return }

                    // Blink and hold
                    cursorBlinking = true
                    await wait(2500)
                }
            }
        }
    }

    private var alive: Bool { !Task.isCancelled }

    @MainActor
    private func typeString(_ text: String) async {
        for char in text {
            guard alive else { return }
            displayedText.append(char)
            // Natural cadence: slight pause on punctuation, variable on letters
            let ms: UInt64
            if char == "," { ms = 80 }
            else if char == " " { ms = 50 }
            else { ms = .random(in: 45...75) }
            await wait(ms)
        }
    }

    @MainActor
    private func deleteAll() async {
        while !displayedText.isEmpty, alive {
            displayedText.removeLast()
            await wait(30)
        }
    }

    @MainActor
    private func wait(_ ms: UInt64) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }
}
