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

        XCTAssertFalse(viewModel.isPrimaryActionEnabled)

        viewModel.proceed()

        XCTAssertEqual(viewModel.currentStep, .password)
        XCTAssertEqual(viewModel.confirmationErrorMessage, "비밀번호가 일치하지 않습니다.")
    }

    func testPasswordStepEnablesActionOnlyWhenConfirmationMatches() {
        let viewModel = SignupViewModel()
        viewModel.identifier = "goneUser"
        viewModel.proceed()
        viewModel.password = "password"
        viewModel.passwordConfirmation = "password"

        XCTAssertTrue(viewModel.isPrimaryActionEnabled)
    }

    func testPhoneNumberIsFormattedAndEnablesVerificationRequest() {
        let viewModel = SignupViewModel()
        viewModel.updatePhoneNumber("01012345678")

        XCTAssertEqual(viewModel.phoneNumber, "010-1234-5678")
        XCTAssertTrue(viewModel.isVerificationRequestEnabled)
    }

    func testStudentInformationStepRequiresBothStudentNumberAndName() {
        let viewModel = makeViewModelAtStudentInformationStep()

        XCTAssertFalse(viewModel.isPrimaryActionEnabled)

        viewModel.studentNumber = "3206"
        XCTAssertFalse(viewModel.isPrimaryActionEnabled)

        viewModel.proceed()
        XCTAssertEqual(viewModel.currentStep, .studentInformation)
        XCTAssertNil(viewModel.studentNumberErrorMessage)
        XCTAssertEqual(viewModel.nameErrorMessage, "이름을 입력해주세요.")

        viewModel.name = "김은찬"
        XCTAssertTrue(viewModel.isPrimaryActionEnabled)
    }

    func testStudentInformationStepMovesToOptionalProfileImageStep() {
        let viewModel = makeViewModelAtStudentInformationStep()
        viewModel.studentNumber = "3206"
        viewModel.name = "김은찬"

        viewModel.proceed()

        XCTAssertEqual(viewModel.currentStep, .profileImage)
        XCTAssertEqual(viewModel.currentStep.actionTitle, "시작하기")
        XCTAssertTrue(viewModel.isPrimaryActionEnabled)
    }

    func testProfileImageDataIsStoredWhenSelected() {
        let viewModel = SignupViewModel()
        let imageData = Data([0x01, 0x02])

        viewModel.updateProfileImage(data: imageData)

        XCTAssertEqual(viewModel.profileImageData, imageData)
        XCTAssertNil(viewModel.profileImageErrorMessage)
    }

    private func makeViewModelAtStudentInformationStep() -> SignupViewModel {
        let viewModel = SignupViewModel()
        viewModel.identifier = "goneUser"
        viewModel.proceed()
        viewModel.password = "password"
        viewModel.passwordConfirmation = "password"
        viewModel.proceed()
        viewModel.updatePhoneNumber("01012345678")
        viewModel.verificationCode = "123456"
        viewModel.proceed()
        return viewModel
    }
}
