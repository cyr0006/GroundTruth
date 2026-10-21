//
//  PlannnigStyleZoneTests.swift
//  GroundTruthTests
//
//  Created by Aryan Cyrus  on 21/10/2026.
//


import Testing
@testable import GroundTruth

struct PlanningStyleZoneTests {

    @Test func knownResidentialCode_mapsToResidential()  {
        #expect(PlanningStyle.zoneCategory(forZoneCode: "GRZ1") == .residential)
    }

    @Test func knownCommercialCode_mapsToCommercial()  {
        #expect(PlanningStyle.zoneCategory(forZoneCode: "C1Z") == .commercial)
    }

    @Test func nilOrUnknownCode_fallsBackToOther()  {
        #expect(PlanningStyle.zoneCategory(forZoneCode: nil) == .other)
        #expect(PlanningStyle.zoneCategory(forZoneCode: "LMAO09") == .other)
    }

}

