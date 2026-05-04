import SwiftUI

struct BattlefieldViewport<Content: View>: View {
    @Binding var zoom: CGFloat
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let pointsPerBoardUnit: CGFloat
    let content: Content

    init(
        zoom: Binding<CGFloat>,
        boardWidth: CGFloat,
        boardHeight: CGFloat,
        pointsPerBoardUnit: CGFloat = 22,
        @ViewBuilder content: () -> Content
    ) {
        _zoom = zoom
        self.boardWidth = boardWidth
        self.boardHeight = boardHeight
        self.pointsPerBoardUnit = pointsPerBoardUnit
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                content
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .padding(24)
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        alignment: .topLeading
                    )
            }
            .background(Color(red: 0.10, green: 0.14, blue: 0.10))
        }
    }

    private var canvasSize: CGSize {
        CGSize(
            width: boardWidth * pointsPerBoardUnit * zoom,
            height: boardHeight * pointsPerBoardUnit * zoom
        )
    }
}

struct BattleFloatingWindow<Content: View>: View {
    let title: String
    let systemImage: String
    let width: CGFloat
    let maxHeight: CGFloat
    let scrollIdentifier: String
    let onClose: () -> Void
    let content: Content

    @State private var settledOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    init(
        title: String,
        systemImage: String,
        width: CGFloat,
        maxHeight: CGFloat,
        scrollIdentifier: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.width = width
        self.maxHeight = maxHeight
        self.scrollIdentifier = scrollIdentifier
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            ScrollView(.vertical, showsIndicators: true) {
                content
                    .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.08))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier(scrollIdentifier)
        }
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.96, green: 0.93, blue: 0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.24), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 12)
        .offset(
            x: settledOffset.width + dragOffset.width,
            y: settledOffset.height + dragOffset.height
        )
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.86))
            .accessibilityLabel("Hide \(title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.72))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    settledOffset.width += value.translation.width
                    settledOffset.height += value.translation.height
                }
        )
    }
}
