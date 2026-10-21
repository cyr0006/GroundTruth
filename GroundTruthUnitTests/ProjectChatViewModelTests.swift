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
        #expect(PlanningStyle.ZoneCategory(forZoneCode: "GRZ1") == .residential)
    }

    @Test func knownCommercialCode_mapsToCommercial()  {
        #expect(PlanningStyle.ZoneCategory(forZoneCode: "C1Z") == .commercial)
    }

    @Test func nilOrUnknownCode_fallsBackToOther()  {
        #expect(PlanningStyle.ZoneCategory(forZoneCode: nil) == .other)
        #expect(PlanningStyle.ZoneCategory(forZoneCode: "LMAO09") == .other)
    }

}

