//
//  ContentView.swift
//  GONE
//
//  Created by 김은찬 on 8/3/26.
//

import SwiftUI

struct ContentView: View {
    private enum Destination {
        case login
        case signup
        case home(AccountRole)
    }

    @State private var destination: Destination = .login

    var body: some View {
        ZStack {
            switch destination {
            case .login:
                LoginView(
                    onLogin: { credentials in transition(to: .home(credentials.role)) },
                    onSignUpTapped: { transition(to: .signup) }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .signup:
                SignupView(onDismiss: { transition(to: .login) })
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
            case .home(let role):
                AppTabView(role: role)
                    .transition(.opacity)
            }
        }
    }

    private func transition(to destination: Destination) {
        withAnimation(.snappy(duration: 0.32)) {
            self.destination = destination
        }
    }
}

#Preview {
    ContentView()
}
