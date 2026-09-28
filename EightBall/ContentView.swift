import SwiftUI

struct ContentView: View {
    @State private var model = EightBallModel()
    @State private var sounds = SoundPlayer()
    @State private var dragOffset: CGSize = .zero
    @State private var dragTravel: CGFloat = 0
    @State private var lastDragPoint: CGPoint?
    @State private var jiggles: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Finger travel needed for a drag to count as a wiggle.
    private let wiggleThreshold: CGFloat = 150
    /// Finger travel below which a touch counts as a tap.
    private let tapSlop: CGFloat = 10
    private let maxDragOffset: CGFloat = 70
    /// Delay after the die starts rising before the gong sounds, so it lands as the answer becomes readable.
    private let gongDelay: Duration = .milliseconds(450)

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.16, green: 0.10, blue: 0.32), Color(red: 0.03, green: 0.02, blue: 0.08)],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                BallView(phase: model.phase)
                    .padding(.horizontal, 36)
                    .modifier(Jiggle(progress: jiggles))
                    .offset(dragOffset)
                    .contentShape(Circle())
                    .gesture(wiggle)
                    .accessibilityElement()
                    .accessibilityLabel("Magic 8 Ball")
                    .accessibilityValue(accessibilityValue)
                    .accessibilityHint("Shake your phone or double tap to ask")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { model.ask() }

                Text(hint)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .opacity(model.phase == .shaking ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: model.phase == .shaking)
                    .padding(.horizontal, 24)
                    .accessibilityHidden(true)

                Spacer()
            }
        }
        .onShake { model.ask() }
        .onChange(of: model.phase) { _, phase in
            switch phase {
            case .idle:
                break
            case .shaking:
                sounds.playSlosh()
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.9)) { jiggles += 1 }
                }
            case .answered:
                Task {
                    try? await Task.sleep(for: gongDelay)
                    sounds.playGong()
                }
            }
        }
        .sensoryFeedback(trigger: model.phase) { _, phase in
            switch phase {
            case .idle: nil
            case .shaking: .impact(weight: .heavy)
            case .answered: .success
            }
        }
    }

    private var hint: String {
        switch model.phase {
        case .idle: "Ask a yes-or-no question, then\nshake your phone or wiggle the ball…"
        case .shaking, .answered: "Shake your phone or wiggle the ball\nto ask again…"
        }
    }

    private var accessibilityValue: String {
        switch model.phase {
        case .idle: ""
        case .shaking: "Thinking"
        case .answered(let answer): answer
        }
    }

    /// Handles both taps and wiggles. Global coordinates, because the ball moves under the finger.
    private var wiggle: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if let last = lastDragPoint {
                    dragTravel += hypot(value.location.x - last.x, value.location.y - last.y)
                }
                lastDragPoint = value.location
                dragOffset = CGSize(
                    width: clamp(value.translation.width * 0.6),
                    height: clamp(value.translation.height * 0.6)
                )
            }
            .onEnded { _ in
                if dragTravel >= wiggleThreshold || dragTravel < tapSlop { model.ask() }
                dragTravel = 0
                lastDragPoint = nil
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                    dragOffset = .zero
                }
            }
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, -maxDragOffset), maxDragOffset)
    }
}

/// Side-to-side rattle that runs once each time `progress` animates up by 1.
private struct Jiggle: GeometryEffect {
    var progress: CGFloat
    var amplitude: CGFloat = 14
    var cycles: CGFloat = 5

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let wave = sin(progress * .pi * 2 * cycles)
        return ProjectionTransform(
            CGAffineTransform(translationX: amplitude * wave, y: amplitude * 0.35 * -abs(wave))
        )
    }
}

#Preview {
    ContentView()
}
