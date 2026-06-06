import SwiftUI

// MARK: - Color System
enum AppColors {
    static let background    = Color(hex: "#0a0f1a")
    static let cardBackground = Color(hex: "#111827")
    static let cardSurface   = Color(hex: "#1e293b")
    static let green         = Color(hex: "#4ade80")
    static let blue          = Color(hex: "#60a5fa")
    static let orange        = Color(hex: "#f97316")
    static let yellow        = Color(hex: "#facc15")
    static let purple        = Color(hex: "#a78bfa")
    static let red           = Color(hex: "#f43f5e")
    static let textPrimary   = Color(hex: "#f8fafc")
    static let textSecondary = Color(hex: "#94a3b8")
    static let textTertiary  = Color(hex: "#475569")
}

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8)  & 0xFF) / 255.0
        let b = Double(int         & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var tint: Color = .clear
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(tint.opacity(0.06))
                    }
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tint == .clear ? Color.white.opacity(0.07) : tint.opacity(0.2), lineWidth: 1)
                }
            )
    }
}

// MARK: - Tag Pill
struct TagPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(color == AppColors.cardSurface ? 1.0 : 0.18))
            .foregroundColor(color == AppColors.cardSurface ? AppColors.textSecondary : color)
            .clipShape(Capsule())
    }
}

// MARK: - Animated Ring
struct AnimatedRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.cardSurface, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.textTertiary)
            .padding(.leading, 4)
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.largeTitle)
            Text(message).font(.caption).foregroundColor(AppColors.textSecondary).multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shimmer modifier (loading state)
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.08), location: 0.4),
                        .init(color: .white.opacity(0.12), location: 0.5),
                        .init(color: .white.opacity(0.08), location: 0.6),
                        .init(color: .clear, location: 1),
                    ]),
                    startPoint: .init(x: phase - 0.5, y: 0),
                    endPoint:   .init(x: phase + 0.5, y: 0)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Pulsing dot for live indicator
struct PulsingDot: View {
    @State private var scale: CGFloat = 1.0
    let color: Color

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.3))
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scale)
            Circle().fill(color).frame(width: 7, height: 7)
        }
        .frame(width: 14, height: 14)
        .onAppear { scale = 1.6 }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}

// MARK: - Score Ring (for habits / completion)
struct ScoreRing: View {
    let score: Double
    let size: CGFloat
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                AnimatedRing(progress: score, color: color, lineWidth: 6, size: size)
                Text("\(Int(score * 100))%")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.textSecondary)
        }
    }
}

