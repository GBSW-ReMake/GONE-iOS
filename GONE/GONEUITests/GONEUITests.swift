//
//  GONEUITests.swift
//  GONEUITests
//
//  Created by 김은찬 on 8/3/26.
//

import XCTest

final class GONEUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testSchoolCampingParticipantEditOpensWithoutCrash() throws {
        let app = XCUIApplication()
        app.launch()

        let identifierField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(identifierField.waitForExistence(timeout: 3))
        identifierField.tap()
        identifierField.typeText("test")

        let passwordField = app.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("test")
        app.buttons["로그인"].tap()

        let campingTab = app.tabBars.buttons["스쿨캠핑"]
        XCTAssertTrue(campingTab.waitForExistence(timeout: 3))
        campingTab.tap()

        let availableDate = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "schoolCampingAvailableDate-")
        ).firstMatch
        XCTAssertTrue(availableDate.waitForExistence(timeout: 3))
        availableDate.tap()

        let teacherSearchButton = app.buttons["schoolCampingTeacherSearchButton"]
        XCTAssertTrue(teacherSearchButton.waitForExistence(timeout: 3))
        teacherSearchButton.tap()

        let firstTeacher = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "담당 선생님으로 선택")
        ).firstMatch
        XCTAssertTrue(firstTeacher.waitForExistence(timeout: 3))
        firstTeacher.tap()

        let submitButton = app.buttons["schoolCampingSubmitButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
        submitButton.tap()

        let participantListButton = app.buttons["참여 명단 확인 · 수정"]
        XCTAssertTrue(participantListButton.waitForExistence(timeout: 3))
        participantListButton.tap()

        let editButton = app.buttons["참여 명단 수정"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        XCTAssertTrue(app.navigationBars["명단 수정"].waitForExistence(timeout: 3))
        let participantTeacherSearchButton = app.buttons["schoolCampingParticipantTeacherSearchButton"]
        XCTAssertTrue(participantTeacherSearchButton.waitForExistence(timeout: 3))
        participantTeacherSearchButton.tap()

        let replacementTeacher = app.buttons["schoolCampingTeacher-teacher-2"]
        XCTAssertTrue(replacementTeacher.waitForExistence(timeout: 3))
        replacementTeacher.tap()

        let saveButton = app.buttons["schoolCampingParticipantSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        XCTAssertTrue(app.navigationBars["참여 명단"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
