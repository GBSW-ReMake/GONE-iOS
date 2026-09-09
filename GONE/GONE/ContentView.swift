//
//  ContentView.swift
//  GONE
//
//  Created by 김은찬 on 8/3/26.
//

import SwiftUI

struct ContentView: View {
    private enum Destination {
        case splash
        case roleSelection
        case login(AccountRole)
        case signup(AccountRole)
        case home(AccountRole)
    }

    @State private var destination: Destination = .splash

    private let loginUseCase = LoginUseCase(
        repository: RemoteAuthRepository(client: MoyaAPIClient()),
        sessionStore: KeychainSessionStore()
    )

    var body: some View {
        ZStack {
            switch destination {
            case .splash:
                SplashView(onFinished: { transition(to: .roleSelection) })
                    .transition(.opacity)
            case .roleSelection:
                RoleSelectionView(onRoleSelected: { role in transition(to: .login(role)) })
                    .transition(.opacity)
            case .login(let role):
                LoginView(
                    role: role,
                    loginUseCase: loginUseCase,
                    onLogin: { credentials in transition(to: .home(credentials.role)) },
                    onSignUpTapped: { transition(to: .signup(role)) },
                    onBackTapped: { transition(to: .roleSelection) }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .signup(let role):
                SignupView(onDismiss: { transition(to: .login(role)) })
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
