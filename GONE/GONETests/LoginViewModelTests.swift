//
//  LoginViewModelTests.swift
//  GONETests
//
//  Created by Codex on 2026-08-03.
//

import XCTest
@testable import GONE

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testLoginIsDisabledWhenIdentifierIsEmpty() {
        let viewModel = LoginViewModel()
        viewModel.password = "password"

        XCTAssertFalse(viewModel.isLoginEnabled)
    }

    func testMakeCredentialsTrimsIdentifier() {
        let viewModel = LoginViewModel()
        viewModel.identifier = "  goneUser  "
        viewModel.password = "password"

        XCTAssertEqual(
            viewModel.makeCredentials(),
            LoginCredentials(identifier: "goneUser", password: "password", role: .student)
        )
    }

    func testMakeCredentialsUsesInjectedRole() {
        let viewModel = LoginViewModel(role: .teacher)
        viewModel.identifier = "teacher"
        viewModel.password = "password"

        XCTAssertEqual(viewModel.makeCredentials()?.role, .teacher)
    }

    func testMakeCredentialsShowsFieldErrorsForEmptyInput() {
        let viewModel = LoginViewModel()

        XCTAssertNil(viewModel.makeCredentials())
        XCTAssertEqual(viewModel.identifierErrorMessage, "아이디 또는 전화번호를 입력해주세요.")
        XCTAssertEqual(viewModel.passwordErrorMessage, "비밀번호를 입력해주세요.")
    }
}
