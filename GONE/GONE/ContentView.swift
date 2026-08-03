//
//  ContentView.swift
//  GONE
//
//  Created by 김은찬 on 8/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingSignup = false

    var body: some View {
        ZStack {
            if isShowingSignup {
                SignupView {
                    withAnimation(.snappy(duration: 0.32)) {
                        isShowingSignup = false
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )
            } else {
                LoginView(onSignUpTapped: {
                    withAnimation(.snappy(duration: 0.32)) {
                        isShowingSignup = true
                    }
                })
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
