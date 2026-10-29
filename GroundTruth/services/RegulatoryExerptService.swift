//
//  RegulatoryExerptService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 29/10/2026.
//

import Foundation

enum RegulatoryExerptService {
    private static let zoneClauseNames: [String: String] = [
        "GRZ" :"GENERAL RESIDENTIAL ZONE",
        "RGZ" :"RESIDENTIAL GROWTH ZONE",
        "NRZ" :"NEIGHBOURHOOD RESIDENTIAL ZONE",
        "TZ" :"TOWNSHIP ZONE",
        "RLZ" :"RURAL LIVING ZONE",
        "LDRZ" :"LOW DENSITY RESIDENTIAL ZONE",
        "C1Z" :"COMMERCIAL 1 ZONE",
        "C2Z" :"COMMERCIAL 2 ZONE",
        "IN1Z" :"INDUSTRIAL 1 ZONE",
        "IN2Z" :"INDUSTRIAL 2 ZONE",
        "IN3Z" :"INDUSTRIAL 3 ZONE",
        "PUZ" :"PUBLIC USE ZONE",
        "PCRZ" :"PUBLIC CONSERVATION AND RESOURCE ZONE",
        "PPRZ" :"PUBLIC PARK AND RECREATION ZONE",
        "FZ" :"FARMING ZONE",
        "RCZ" :"RURAL CONSERVATION ZONE",
        "RUZ" :"RURAL ACTIVITY ZONE",
        "MUZ" :"MIXED USE ZONE"
    ]
    
    private static let overlayClauseNames: [String: String] = [
        "HO":"HERITAGE OVERLAY",
        "VPO":"VEGETATION PROTECTION OVERLAY",
        "SLO":"SIGNIFICANT LANDSCAPE OVERLAY",
        "ESO":"ENVIRONMENTAL SIGNIFICANCE OVERLAY",
        "BMO":"BUSHFIRE MANAGEMENT OVERLAY",
        "LSIO":"LAND SUBJECT TO INUNDATION OVERLAY",
        "SBO":"SPECIAL BUILDING OVERLAY",
        "FO":"FLOODWAY OVERLAY",
        "DDO":"DESIGN AND DEVELOPMENT OVERLAY",
        "DCPO":"DEVELOPMENT CONTRIBUTIONS PLAN OVERLAY",
        "ICPO":"INFRASTRUCTURE CONTRIBUTION PLAN OVERLAY",
        "PAO":"PUBLIC ACQUISITION OVERLAY"
    ]
    
    private static let topLevelClauseRegex = try! NSRegularExpression(pattern: #"^\s*\d{2}\.\d{2}\s"#)
    
    static func findExcerpt(in fullText: String, headingContaining terms: [String], maxLength: Int = 6000) -> String? {
        guard !terms.isEmpty else {return nil}
        let upperTerms = terms.map {$0.uppercased()}
        let lines = fullText.components(separatedBy: "\n")
        
        var matchLineIndex: Int?
        for (index,line) in lines.enumerated(){
            guard isTopLevelClauseLine(line) else {continue}
            let lookahead = lines[index..<min(index+3, lines.count)].joined(separator: " ").uppercased()
            if upperTerms.allSatisfy({lookahead.contains($0) }) {
                matchLineIndex = index
                break
            }
        }
        
        let startLineIndex: Int
        if let matchLineIndex {
            startLineIndex = matchLineIndex
        } else {
            let needle = upperTerms.joined(separator: " ")
            guard let range = fullText.uppercased().range(of: needle) else {return nil}
            let prefixLineCount = fullText[fullText.startIndex..<range.lowerBound].components(separatedBy: "\n").count
            startLineIndex = prefixLineCount - 1
        }
        
        var endLineIndex = lines.count
        for index in (startLineIndex + 1)..<lines.count{
            if isTopLevelClauseLine(lines[index]){
                endLineIndex = index
                break
            }
        }
        
        let excerptLines = lines[startLineIndex..<endLineIndex]
        let excerpt = excerptLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !excerpt.isEmpty else {return nil}
        return String(excerpt.prefix(maxLength))
    }
    
    private static func isTopLevelClauseLine(_ line: String) -> Bool {
        topLevelClauseRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
    }
    
    static func planningSchemeExcerpts(zoneCode: String?, overlayCodes: [String?], fullText: String) -> [String]{
        var excerpts: [String] = []
        
        if let zoneCode, let clauseName = clauseName(for: zoneCode, in: zoneClauseNames){
            if let hit = findExcerpt(in: fullText, headingContaining: [clauseName]){
                excerpts.append(hit)
            }
        }
        
        for code in overlayCodes{
            guard let code, let clauseName = clauseName(for: code, in: overlayClauseNames) else {continue}
            if let hit = findExcerpt(in: fullText, headingContaining: [clauseName]){
                excerpts.append(hit)
            }
        }
        
        return excerpts
    }
    
    private static func clauseName(for code: String, in table: [String: String]) -> String? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else {return nil}
        
        return table.first{normalized.hasPrefix($0.key)}?.value
    }
    
    static func planningSchemeFullText() -> String? {
        bundledText(resource: "PlanningScheme", extension: "txt")
    }
    
    static func buildingPracticeNoteText() -> String? {
        bundledText(resource: "BuildingPracticeNote", extension: "txt")
    }
    
    private static func bundledText(resource: String, extension ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {return nil}
        return try? String(contentsOf: url, encoding: .utf8)
                
    }
}

