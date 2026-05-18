import SwiftUI
import UIKit

struct DoneView: View {

    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var logStore: LogStore

    let minutes: Int
    let isMilestone: Bool
    let category: ActionCategory
    let onGoHome: () -> Void

    @State private var breathe = false
    @State private var showContent = false
    @State private var particlesActive = true

    private var catColor: Color { category.catColor }

    // MARK: – Body

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if isMilestone {
                milestoneContent
            } else {
                normalContent
            }

            // Floating celebration particles
            if particlesActive {
                CelebrationParticles(color: catColor)
                    .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathe = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if isMilestone {
                logStore.milestoneOneHourShown = true
            }
            // Fade out particles after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                particlesActive = false
            }
        }
    }

    // MARK: – Normal Done

    // Category-aware "Ты verb." sentence parts [prefix, verb, suffix]
    private var verbSentence: (String, String, String) {
        switch category {
        case .body:       return ("Ты ", "подвигалась", ".")
        case .calm:       return ("Ты ", "вернулась", " к себе.")
        case .reading:    return ("Ты ", "прочитала", ".")
        case .creativity: return ("Ты ", "создала", " момент.")
        case .home:       return ("Ты ", "позаботилась", " о пространстве.")
        case .social:     return ("Ты ", "связалась", " с близким.")
        }
    }

    private var normalContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // ✦ breathing accent
            Text("✦")
                .font(.system(size: 32))
                .foregroundStyle(catColor)
                .scaleEffect(breathe ? 1.1 : 0.9)
                .padding(.bottom, 36)

            // "Ты verb." with italic verb
            let (prefix, verb, suffix) = verbSentence
            (Text(prefix) +
             Text(verb).font(.newsreader(32)) +
             Text(suffix))
                .font(.dm(32, .medium))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.8)
                .lineSpacing(2)
                .padding(.bottom, 14)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

            // Reclaimed minutes
            Text(verbatim: "\(category.displayName.uppercased()) · +\(minutes) мин")
                .font(.dm(12, .medium))
                .foregroundStyle(theme.textSecondary.opacity(0.55))
                .tracking(0.4)

            Spacer()

            // CTA — primary dark
            TrulyButton("дальше", action: onGoHome)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }

    // MARK: – Milestone (first hour)

    private var milestoneContent: some View {
        ZStack {
            // Bloom rings
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .stroke(theme.accent.opacity(breathe ? 0 : 0.4), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe ? 4.5 : 0.2)
                    .opacity(breathe ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 2).delay(Double(i) * 0.2).repeatForever(autoreverses: false),
                        value: breathe
                    )
            }

            VStack(spacing: 16) {
                Spacer()

                // Big "1ч"
                Text(verbatim: "1ч")
                    .font(.dm(72, .bold))
                    .tracking(-4)
                    .foregroundStyle(theme.accent)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)

                Text(verbatim: "Рекорд разблокирован")
                    .font(.dm(11, .medium))
                    .tracking(1)
                    .foregroundStyle(theme.textSecondary.opacity(0.6))

                Text(verbatim: "Твой первый час")
                    .font(.dm(26, .bold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.top, 8)

                Text(verbatim: "Целый час возвращённого времени.\nЭто только начало.")
                    .font(.dm(15))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Spacer()

                TrulyButton("Продолжить") {
                    onGoHome()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

}

// MARK: – Celebration particles

struct CelebrationParticles: View {
    let color: Color

    @State private var particles: [Particle] = []
    @State private var animating = false

    struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
        let delay: Double
        let drift: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(color.opacity(animating ? 0 : 0.6))
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x + (animating ? p.drift : 0),
                            y: animating ? -20 : geo.size.height * 0.5
                        )
                        .animation(
                            .easeOut(duration: 2.2).delay(p.delay),
                            value: animating
                        )
                }
            }
            .onAppear {
                particles = (0..<16).map { _ in
                    Particle(
                        x: CGFloat.random(in: 40...(geo.size.width - 40)),
                        size: CGFloat.random(in: 3...8),
                        delay: Double.random(in: 0...0.6),
                        drift: CGFloat.random(in: -30...30)
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animating = true
                }
            }
        }
        .ignoresSafeArea()
    }
}
