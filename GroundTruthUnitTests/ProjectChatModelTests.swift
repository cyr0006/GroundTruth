//
//  GroundTruthTests.swift
//  GroundTruthTests
//
//  Created by Aryan Cyrus  on 21/10/2026.
//

import Testing
@testable import GroundTruth

@MainActor
final class  ProjectChatViewModelTests {
    @Test func testSend_blankInput_doesNothing(){
        let project = Project.sampleProjects[0]
        let viewModel = ProjectChatViewModel(project: project, projectStore: ProjectStore())
        
        viewModel.send("    ")
        
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.isSending == false)
    }
}

