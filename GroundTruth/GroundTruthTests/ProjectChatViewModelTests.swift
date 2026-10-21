//
//  GroundTruthTests.swift
//  GroundTruthTests
//
//  Created by Aryan Cyrus  on 21/10/2026.
//

import Testing
import XCTest

struct GroundTruthTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

@MainActor
final class  ProjectChatViewModelTests: XCTestCase {
    func testSend_blankInput_doesNothing(){
        let project = Project.sampleProjects[0]
        let viewModel = ProjectChatViewModel(project: project)
        
        viewModel.send("    ")
        
        XCTAssertTrue(viewModel.messages.isEmpty, "Whitespace-only input should not be sent")
        XCTAssertFalse(viewModel.isSending)
    }
}
