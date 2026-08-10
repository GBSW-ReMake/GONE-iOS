//
//  SplashView.swift
//  GONE
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 1
    @State private var logoOpacity = 1.0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image("GONELogo")
                .resizable()
                .scaledToFit()
                .frame(width: 235, height: 64)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .accessibilityLabel("GONE")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("GONE 시작 화면")
        .onAppear(perform: beginTransition)
    }

    private func beginTransition() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.24)
            : Animation.easeInOut(duration: 0.44)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(animation) {
                if reduceMotion {
                    logoOpacity = 0
                } else {
                    logoScale = 0.64
                    logoOpacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.24 : 0.44)) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
