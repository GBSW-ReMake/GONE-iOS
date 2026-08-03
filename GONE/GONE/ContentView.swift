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
        Group {
            if isShowingSignup {
                SignupView {
                    isShowingSignup = false
                }
            } else {
                LoginView(onSignUpTapped: {
                    isShowingSignup = true
                })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingSignup)
    }
}

#Preview {
    ContentView()
}
