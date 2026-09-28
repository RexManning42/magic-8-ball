import SwiftUI

struct BallView: View {
    let phase: EightBallModel.Phase

    /// 0 = the "8" faces the viewer, 1 = the window does.
    @State private var spin: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let w = d * 0.56
            ZStack {
                // Contact shadow on the floor.
                Ellipse()
                    .fill(.black.opacity(0.6))
                    .frame(width: d * 0.74, height: d * 0.09)
                    .blur(radius: d * 0.035)
                    .offset(y: d * 0.51)

                sphere(diameter: d)

                eightFace(diameter: w)
                    .frame(width: w, height: w)
                    .modifier(SphereSpin(angle: spin * .pi, radius: d / 2))

                window(diameter: w)
                    .frame(width: w, height: w)
                    .modifier(SphereSpin(angle: (spin - 1) * .pi, radius: d / 2))

                gloss(diameter: d)
            }
            .frame(width: d, height: d)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: phase) { _, newPhase in
            guard newPhase != .idle, spin != 1 else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.75)) { spin = 1 }
        }
    }

    // MARK: Sphere

    private func sphere(diameter d: CGFloat) -> some View {
        ZStack {
            Circle().fill(
                RadialGradient(
                    colors: [Color(white: 0.24), Color(white: 0.09), Color(white: 0.02), .black],
                    center: UnitPoint(x: 0.36, y: 0.27), startRadius: 0, endRadius: d * 0.78
                )
            )
            // Limb darkening.
            Circle().fill(
                RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: d * 0.36, endRadius: d * 0.5)
            )
            // Purple light bounced up from the floor onto the lower right edge.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.clear, .clear, Color(red: 0.55, green: 0.40, blue: 0.95).opacity(0.55)],
                        startPoint: UnitPoint(x: 0.2, y: 0.1), endPoint: UnitPoint(x: 0.85, y: 0.95)
                    ),
                    lineWidth: d * 0.035
                )
                .blur(radius: d * 0.02)
                .clipShape(Circle())
        }
        .frame(width: d, height: d)
    }

    /// Reflections that sit on top of everything, as on polished plastic.
    private func gloss(diameter d: CGFloat) -> some View {
        ZStack {
            // Broad, soft reflection of the room above.
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.20), .white.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                .frame(width: d * 0.72, height: d * 0.40)
                .offset(y: -d * 0.27)
                .blur(radius: d * 0.025)
            // Light source.
            Ellipse()
                .fill(RadialGradient(colors: [.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: d * 0.13))
                .frame(width: d * 0.30, height: d * 0.17)
                .rotationEffect(.degrees(-32))
                .offset(x: -d * 0.22, y: -d * 0.31)
            Ellipse()
                .fill(.white.opacity(0.9))
                .frame(width: d * 0.085, height: d * 0.04)
                .rotationEffect(.degrees(-32))
                .offset(x: -d * 0.235, y: -d * 0.325)
                .blur(radius: d * 0.008)
        }
        .frame(width: d, height: d)
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    // MARK: Faces

    private func eightFace(diameter w: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white, Color(white: 0.93), Color(white: 0.74)],
                    center: UnitPoint(x: 0.35, y: 0.28), startRadius: 0, endRadius: w * 0.8
                )
            )
            .overlay {
                Text("8")
                    .font(.system(size: w * 0.70, weight: .bold, design: .serif))
                    .foregroundStyle(Color(white: 0.04))
            }
            .padding(w * 0.06)
    }

    private func window(diameter w: CGFloat) -> some View {
        ZStack {
            LiquidWindow(phase: phase)
                .padding(w * 0.04)

            // Inner shadow cast by the rim onto the glass.
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [.black.opacity(0.9), .black.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: w * 0.07
                )
                .blur(radius: w * 0.025)
                .padding(w * 0.03)
                .clipShape(Circle())

            // Bevelled rim: recessed, so the top edge is in shadow and the bottom edge catches light.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(white: 0.03), Color(white: 0.14), Color(white: 0.42)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: w * 0.045
                )
            Circle()
                .strokeBorder(Color.black.opacity(0.8), lineWidth: w * 0.008)
                .padding(w * 0.043)

            // Glass.
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.13), .clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(w * 0.05)
            Circle()
                .trim(from: 0.56, to: 0.70)
                .stroke(.white.opacity(0.45), style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
                .padding(w * 0.11)
                .blur(radius: w * 0.008)
            Circle()
                .trim(from: 0.08, to: 0.17)
                .stroke(.white.opacity(0.14), style: StrokeStyle(lineWidth: w * 0.015, lineCap: .round))
                .padding(w * 0.10)
                .blur(radius: w * 0.008)
        }
        .allowsHitTesting(false)
    }
}

/// Moves a disc as if it were painted on a sphere turning about its vertical axis.
private struct SphereSpin: GeometryEffect {
    var angle: Double
    let radius: CGFloat

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let facing = cos(angle)
        guard facing > 0.001 else {
            // On the far side of the ball.
            return ProjectionTransform(CGAffineTransform(scaleX: 0.0001, y: 0.0001))
        }
        let transform = CGAffineTransform(translationX: size.width / 2 - radius * sin(angle), y: 0)
            .scaledBy(x: facing, y: 1)
            .translatedBy(x: -size.width / 2, y: 0)
        return ProjectionTransform(transform)
    }
}

#Preview {
    BallView(phase: .idle)
        .padding(40)
        .background(Color(red: 0.08, green: 0.04, blue: 0.16))
}
