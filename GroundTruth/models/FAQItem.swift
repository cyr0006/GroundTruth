//
//  FAQItem.swift
//  GroundTruth
//
//  Static information library model - technical FAQ entries.
//

import Foundation

struct FAQItem: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var answer: String
    var category: String
}

extension FAQItem {
    static let sampleFAQs: [FAQItem] = [
        FAQItem(
            question: "Do I need a planning permit to build a deck?",
            answer: "In most residential zones a deck under a certain height and setback from boundaries doesn't require a planning permit, but this depends on the applicable zone and any overlays on your property. Check the Map screen to see what applies to your address.",
            category: "Planning Permits"
        ),
        FAQItem(
            question: "What's the difference between a planning permit and a building permit?",
            answer: "A planning permit deals with land use and development under the planning scheme (zones, overlays, neighbourhood character). A building permit certifies that the physical construction complies with the National Construction Code and structural safety requirements.",
            category: "Permits"
        ),
        FAQItem(
            question: "What is a Bushfire Management Overlay?",
            answer: "The Bushfire Management Overlay (BMZO) identifies areas where bushfire risk must be considered in planning and building decisions. Properties affected may need a bushfire attack level (BAL) assessment before a permit is issued.",
            category: "Overlays"
        ),
        FAQItem(
            question: "How long does a planning permit application take?",
            answer: "Councils generally have a statutory 60-day timeframe to make a decision, though this can be extended if further information is requested or if the application is notified to neighbours and objections are received.",
            category: "Planning Permits"
        ),
        FAQItem(
            question: "Can I get a rough cost estimate for my project before applying for permits?",
            answer: "Yes. Once you create a project, GroundTruth can generate an approximate cost estimate based on project type, size, and current supplier pricing data.",
            category: "Costs"
        )
    ]
}
