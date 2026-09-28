import SwiftUI

/// The ball's window: dark purple liquid with the die floating up to the glass.
struct LiquidWindow: View {
    let phase: EightBallModel.Phase

    /// 1 = die sunk out of sight, 0 = pressed against the glass.
    @State private var depth: CGFloat = 1
    @State private var tilt: Double = 0
    @State private var answer = ""
    @State private var bubbleStart = Date.distantPast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bubbleCount = 12

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            let sunk = min(max(depth, 0), 1)
            ZStack {
                RadialGradient(
                    colors: [Color(red: 0.17, green: 0.05, blue: 0.33), Color(red: 0.07, green: 0.02, blue: 0.16), Color(red: 0.02, green: 0.0, blue: 0.06)],
                    center: .center, startRadius: 0, endRadius: w * 0.55
                )

                TimelineView(.animation(paused: phase == .idle)) { timeline in
                    murk(time: timeline.date.timeIntervalSinceReferenceDate)
                }

                TimelineView(.animation(paused: phase == .idle || reduceMotion)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    DieView(answer: answer)
                        .frame(width: w * 0.86, height: w * 0.86)
                        .rotationEffect(.degrees(reduceMotion ? 0 : sin(t * 0.9) * 1.2))
                        .offset(x: reduceMotion ? 0 : cos(t * 0.7) * w * 0.006,
                                y: reduceMotion ? 0 : sin(t * 1.3) * w * 0.008)
                }
                .rotationEffect(.degrees(tilt))
                .scaleEffect(1 - 0.58 * depth)
                .offset(y: w * 0.10 * depth)
                .blur(radius: w * 0.09 * sunk)
                .opacity(1 - 0.97 * sunk)

                TimelineView(.animation(paused: phase == .idle)) { timeline in
                    bubbles(elapsed: timeline.date.timeIntervalSince(bubbleStart))
                }

                // The liquid darkens toward the edge of the window.
                RadialGradient(
                    colors: [.clear, .clear, Color(red: 0.03, green: 0.0, blue: 0.08).opacity(0.85)],
                    center: .center, startRadius: w * 0.2, endRadius: w * 0.52
                )
                .allowsHitTesting(false)
            }
            .frame(width: w, height: w)
            .clipShape(Circle())
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .idle:
                break
            case .shaking:
                bubbleStart = .now
                withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .easeIn(duration: 0.45)) {
                    depth = 1
                    if !reduceMotion { tilt += 130 }
                }
            case .answered(let newAnswer):
                answer = newAnswer
                let rest = reduceMotion ? 0 : Double.random(in: -9...9)
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { tilt = reduceMotion ? 0 : rest - 55 }
                withAnimation(reduceMotion ? .easeInOut(duration: 0.5) : .spring(response: 1.5, dampingFraction: 0.6)) {
                    depth = 0
                    tilt = rest
                }
            }
        }
    }

    private func murk(time t: Double) -> some View {
        Canvas { context, size in
            for i in 0..<5 {
                let n = Double(i)
                let x = size.width * (0.5 + 0.32 * sin(t * (0.23 + 0.05 * n) + n * 1.7))
                let y = size.height * (0.5 + 0.32 * cos(t * (0.19 + 0.04 * n) + n * 2.3))
                let r = size.width * (0.30 + 0.06 * sin(t * 0.3 + n))
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color(red: 0.45, green: 0.18, blue: 0.80).opacity(0.20), .clear]),
                        center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func bubbles(elapsed: TimeInterval) -> some View {
        Canvas { context, size in
            guard elapsed >= 0, elapsed < 3.5 else { return }
            for i in 0..<bubbleCount {
                // Cheap deterministic scatter per bubble.
                let seed = Double(i) * 12.9898
                let a = abs(sin(seed) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let b = abs(sin(seed * 1.7 + 4) * 24634.6345).truncatingRemainder(dividingBy: 1)
                let c = abs(sin(seed * 2.9 + 1.3) * 35791.2468).truncatingRemainder(dividingBy: 1)
                let delay = c * 1.1
                let life = 1.1 + b * 1.2
                let p = (elapsed - delay) / life
                guard p > 0, p < 1 else { continue }

                let radius = size.width * (0.008 + 0.014 * b)
                let x = size.width * (0.18 + 0.64 * a) + sin(elapsed * 6 + seed) * size.width * 0.012
                let y = size.height * (0.95 - 0.9 * p)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                let fade = sin(.pi * p)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.35 * fade)), lineWidth: max(0.6, radius * 0.25))
                context.fill(
                    Path(ellipseIn: rect.insetBy(dx: radius * 0.45, dy: radius * 0.45).offsetBy(dx: -radius * 0.3, dy: -radius * 0.3)),
                    with: .color(.white.opacity(0.45 * fade))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    LiquidWindow(phase: .answered("Without a doubt"))
        .frame(width: 240, height: 240)
        .padding(40)
        .background(.black)
}
