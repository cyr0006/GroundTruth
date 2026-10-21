//
//  PropertyPlanningInfoTests.swift
//  GroundTruthUnitTests
//
//  Created by Aryan Cyrus  on 21/10/2026.
//

import Testing
@testable import GroundTruth

struct PropertyPlanningInfoTests {

    @Test func overlayCategories_matchExpectedPairing() {
        let info = PropertyPlanningInfo(
            zoneName: "General Residential Zone",
            zoneCode: "GRZ1",
            overlayNames: ["Heritage Overlay", "Bushfire Management Overlay"],
            overlayCodes: ["HO123", "BMO"]
        )
        
        let categories = info.overlayCodes.map{PlanningStyle.overlayCategory(forOverlayCode: $0)}
        
        #expect(categories == [.heritage, .bushfireManagement])
        #expect(info.overlayNames.count == info.overlayCodes.count)
    }
    
    @Test func noOverlays_fallBackCorrectly(){
        #expect(PlanningStyle.overlayCategory(forOverlayCode: nil) == .other)
    }

}
