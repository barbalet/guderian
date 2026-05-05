import GuderianCore
import SwiftUI

struct ScenarioMapView: View {
    let layout: ScenarioMapLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(layout.title, systemImage: "map")
                .font(.headline)

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(mapBackground)
                    grid(in: proxy.size)

                    ForEach(layout.deploymentZones) { zone in
                        deploymentZone(zone, in: proxy.size)
                    }

                    ForEach(layout.elements) { element in
                        mapElement(element, in: proxy.size)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                }
            }
            .aspectRatio(layout.width / layout.height, contentMode: .fit)
        }
    }

    private var mapBackground: Color {
        Color(red: 0.79, green: 0.82, blue: 0.74)
    }

    private func grid(in size: CGSize) -> some View {
        Path { path in
            let columns = 10
            let rows = 8
            for column in 1..<columns {
                let x = size.width * CGFloat(column) / CGFloat(columns)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 1..<rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
    }

    @ViewBuilder
    private func mapElement(_ element: ScenarioMapElement, in size: CGSize) -> some View {
        if element.points.count > 1 {
            Path { path in
                guard let first = element.points.first else { return }
                path.move(to: point(first, in: size))
                for item in element.points.dropFirst() {
                    path.addLine(to: point(item, in: size))
                }
            }
            .stroke(color(for: element), style: StrokeStyle(lineWidth: element.strokeWidth, lineCap: .round, lineJoin: .round))
            .overlay(alignment: .topLeading) {
                if let middle = element.points.dropFirst().first {
                    mapLabel(element.name, at: middle, in: size)
                }
            }
        } else if let first = element.points.first {
            let center = point(first, in: size)
            ZStack {
                Circle()
                    .fill(color(for: element).opacity(0.82))
                    .frame(width: max(18, element.radius * 5), height: max(18, element.radius * 5))
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    }
                Image(systemName: symbol(for: element.kind))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .position(center)
            mapLabel(element.name, at: first, in: size, yOffset: max(14, element.radius * 3))
        }
    }

    private func deploymentZone(_ zone: ScenarioDeploymentZone, in size: CGSize) -> some View {
        let origin = point(zone.origin, in: size)
        let width = size.width * zone.width / layout.width
        let height = size.height * zone.height / layout.height

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(color(for: zone.side).opacity(0.12))
                .overlay {
                    Rectangle()
                        .stroke(color(for: zone.side).opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            Text(zone.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color(for: zone.side))
                .lineLimit(2)
                .padding(5)
        }
        .frame(width: width, height: height)
        .position(x: origin.x + width / 2, y: origin.y + height / 2)
        .accessibilityLabel(zone.name)
    }

    private func mapLabel(_ text: String, at mapPoint: ScenarioMapPoint, in size: CGSize, yOffset: Double = 10) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 110)
            .position(x: point(mapPoint, in: size).x, y: point(mapPoint, in: size).y + CGFloat(yOffset))
    }

    private func point(_ mapPoint: ScenarioMapPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * mapPoint.x / layout.width,
            y: size.height * mapPoint.y / layout.height
        )
    }

    private func color(for element: ScenarioMapElement) -> Color {
        switch element.kind {
        case .road, .phaseLine:
            return Color(red: 0.43, green: 0.39, blue: 0.34)
        case .river, .canal, .lake:
            return Color(red: 0.16, green: 0.45, blue: 0.72)
        case .marsh:
            return Color(red: 0.32, green: 0.50, blue: 0.42)
        case .railway:
            return Color(red: 0.24, green: 0.23, blue: 0.22)
        case .town, .village, .urbanDistrict:
            return Color(red: 0.56, green: 0.49, blue: 0.45)
        case .forest:
            return Color(red: 0.21, green: 0.47, blue: 0.27)
        case .ridge:
            return Color(red: 0.50, green: 0.44, blue: 0.29)
        case .bunker, .fortifiedLine:
            return Color(red: 0.36, green: 0.36, blue: 0.38)
        case .bridge, .ford, .ferry:
            return Color(red: 0.90, green: 0.64, blue: 0.20)
        case .objective:
            return Color(red: 0.40, green: 0.27, blue: 0.68)
        case .artillery:
            return Color(red: 0.75, green: 0.28, blue: 0.22)
        case .airPressure:
            return Color(red: 0.50, green: 0.53, blue: 0.60)
        case .deployment:
            return color(for: element.side)
        }
    }

    private func color(for side: ScenarioSide) -> Color {
        switch side {
        case .player:
            return Color(red: 0.10, green: 0.36, blue: 0.73)
        case .guderianAI:
            return Color(red: 0.68, green: 0.16, blue: 0.12)
        case .neutral:
            return Color.secondary
        }
    }

    private func symbol(for kind: ScenarioMapElementKind) -> String {
        switch kind {
        case .road:
            return "road.lanes"
        case .river, .canal, .lake:
            return "water.waves"
        case .marsh:
            return "leaf"
        case .railway:
            return "tram"
        case .town, .urbanDistrict:
            return "building.2"
        case .village:
            return "house"
        case .forest:
            return "tree"
        case .ridge:
            return "mountain.2"
        case .bunker, .fortifiedLine:
            return "shield"
        case .bridge:
            return "arrow.left.and.right"
        case .ford:
            return "figure.walk"
        case .ferry:
            return "ferry"
        case .objective:
            return "target"
        case .artillery:
            return "scope"
        case .airPressure:
            return "airplane"
        case .deployment:
            return "square.dashed"
        case .phaseLine:
            return "flag.checkered"
        }
    }
}
