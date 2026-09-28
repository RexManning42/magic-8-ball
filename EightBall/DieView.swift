import SwiftUI

/// An octahedral die seen face-on: the answer face in the middle, three neighbouring
/// faces angled away around it, together forming a hexagonal silhouette.
struct DieView: View {
    let answer: String

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            ZStack {
                Canvas { context, size in
                    draw(in: &context, center: CGPoint(x: size.width / 2, y: size.height / 2), radius: r)
                }
                Text(answer.uppercased())
                    .font(.system(size: r * 0.155, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color(red: 0.93, green: 0.95, blue: 1.0))
                    .shadow(color: Color(red: 0.02, green: 0.02, blue: 0.25).opacity(0.9), radius: 0, x: r * 0.008, y: r * 0.012)
                    .frame(width: r * 0.9, height: r * 0.66)
                    .offset(y: r * 0.1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func draw(in context: inout GraphicsContext, center: CGPoint, radius r: CGFloat) {
        func vertex(_ degrees: Double) -> CGPoint {
            let a = degrees * .pi / 180
            return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        }
        func polygon(_ points: [CGPoint]) -> Path {
            var path = Path()
            path.addLines(points)
            path.closeSubpath()
            return path
        }
        func blue(_ brightness: Double) -> Color {
            Color(red: 0.20 * brightness, green: 0.26 * brightness, blue: 0.95 * brightness)
        }

        let top = vertex(-90), right = vertex(30), left = vertex(150)
        let joint = StrokeStyle(lineWidth: r * 0.035, lineCap: .round, lineJoin: .round)

        // Side faces, lit from the top left.
        let sides: [(points: [CGPoint], light: Double, dark: Double)] = [
            ([left, vertex(-150), top], 0.95, 0.62),
            ([top, vertex(-30), right], 0.60, 0.36),
            ([right, vertex(90), left], 0.34, 0.16),
        ]
        for side in sides {
            let path = polygon(side.points)
            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [blue(side.light), blue(side.dark)]),
                startPoint: side.points[1], endPoint: center
            )
            context.fill(path, with: shading)
            context.stroke(path, with: .color(blue(side.dark * 0.8)), style: joint)
        }

        // Answer face.
        let face = polygon([top, right, left])
        context.fill(face, with: .linearGradient(
            Gradient(colors: [blue(1.12), blue(0.78), blue(0.52)]),
            startPoint: CGPoint(x: center.x - r * 0.6, y: center.y - r * 0.9),
            endPoint: CGPoint(x: center.x + r * 0.5, y: center.y + r * 0.6)
        ))
        // Plastic sheen across the upper part of the face.
        context.drawLayer { layer in
            layer.clip(to: face)
            layer.addFilter(.blur(radius: r * 0.08))
            layer.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 0.75, y: center.y - r * 1.0, width: r * 0.9, height: r * 0.8)),
                with: .color(.white.opacity(0.22))
            )
        }
        // Bevelled edges: bright where they face the light, dark on the underside.
        var litEdges = Path()
        litEdges.move(to: left); litEdges.addLine(to: top); litEdges.addLine(to: right)
        context.stroke(litEdges, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: r * 0.022, lineCap: .round, lineJoin: .round))
        var shadeEdge = Path()
        shadeEdge.move(to: right); shadeEdge.addLine(to: left)
        context.stroke(shadeEdge, with: .color(blue(1.3).opacity(0.5)), style: StrokeStyle(lineWidth: r * 0.018, lineCap: .round))
    }
}

#Preview {
    DieView(answer: "Concentrate and ask again")
        .padding(40)
        .background(Color(red: 0.08, green: 0.03, blue: 0.16))
}
