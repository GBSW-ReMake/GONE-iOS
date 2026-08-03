//
//  SignupViewModelTests.swift
//  GONETests
//
//  Created by Codex on 2026-08-04.
//

import XCTest
@testable import GONE

@MainActor
final class SignupViewModelTests: XCTestCase {
    func testIdentifierStepMovesToPasswordWhenIdentifierIsEntered() {
        let viewModel = SignupViewModel()
        viewModel.identifier = "goneUser"

        viewModel.proceed()

        XCTAssertEqual(viewModel.currentStep, .password)
    }

    func testPasswordStepRequiresMatchingConfirmation() {
        let viewModel = SignupViewModel()
        viewModel.identifier = "goneUser"
        viewModel.proceed()
        viewModel.password = "password"
        viewModel.passwordConfirmation = "different"

        viewModel.proceed()

        XCTAssertEqual(viewModel.currentStep, .password)
        XCTAssertEqual(viewModel.confirmationErrorMessage, "비밀번호가 일치하지 않습니다.")
    }

    func testPhoneNumberIsFormattedAndEnablesVerificationRequest() {
        let viewModel = SignupViewModel()
        viewModel.phoneNumber = "01012345678"

        XCTAssertEqual(viewModel.phoneNumber, "010-1234-5678")
        XCTAssertTrue(viewModel.isVerificationRequestEnabled)
    }
}
