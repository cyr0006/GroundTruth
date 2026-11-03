//
//  FAQItem.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
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
        ),
        FAQItem(
            question: "What is a planning permit?",
            answer: "A planning permit is council approval to use or develop land in a particular way — for example building a new dwelling, subdividing land, removing native vegetation, or running a business from a residential property. It's assessed against the planning scheme that applies to your property (its zone and any overlays), not against the physical building work itself.",
            category: "Planning Permits"
        ),
        FAQItem(
            question: "What is a building permit?",
            answer: "A building permit certifies that your building work — footings, framing, plumbing connections, structural elements — meets the National Construction Code and Australian Standards. It's issued by a registered building surveyor (private or municipal), not the planning department, and is required for most building work regardless of whether a planning permit was also needed.",
            category: "Permits"
        ),
        FAQItem(
            question: "Do I need a planning permit and a building permit, or just one?",
            answer: "It depends on the project. Minor work, like a small deck in an unconstrained zone, might only need a building permit. Major work — a new dwelling, a second dwelling on the block, or anything affected by a heritage or vegetation overlay — usually needs both, with the planning permit issued first since your building surveyor will need it before they can issue the building permit.",
            category: "Permits"
        ),
        FAQItem(
            question: "What's the typical order of steps for a building or renovation project?",
            answer: """
            1. Check your zone and overlays — use the Map screen to see what applies to your address.
            2. Get a concept design from a draftsperson or architect.
            3. Apply for a planning permit, if your project needs one, and wait for council's decision (and any objection/appeal period).
            4. Engage a registered building surveyor and apply for your building permit, including any required reports such as engineering, energy rating, or bushfire assessments.
            5. Arrange any other council permits you need before work starts — see "What other council permits might I need?" below.
            6. Start construction, with mandatory inspections at each stage your building surveyor nominates.
            7. Get your final inspection and Certificate of Final Inspection, or Occupancy Permit for habitable new buildings, before moving in or using the space.
            """,
            category: "Getting Started"
        ),
        FAQItem(
            question: "What other council permits might I need besides planning and building permits?",
            answer: "Depending on your project you may also need: an asset protection permit (protects council infrastructure like kerbs and nature strips during construction), a road or footpath occupation permit for skip bins, scaffolding, or site sheds, a vehicle crossing permit for a new or altered driveway, a septic tank permit if your property isn't connected to mains sewer, a tree removal permit if removing significant or native vegetation, and legal point of discharge approval for stormwater. Heritage overlays and asbestos removal can trigger their own separate approvals too, so it's worth asking council what applies to your specific site.",
            category: "Other Permits"
        ),
        FAQItem(
            question: "How long is a planning or building permit valid for?",
            answer: "A planning permit usually lapses if you haven't started the approved use or development within 2 years of it being issued, and finished within a further timeframe set by council — though you can often apply for an extension before it lapses. A building permit has its own expiry too, generally requiring work to commence within 12 months of issue. Check the specific dates on your permit, since councils and surveyors can set different timeframes.",
            category: "Permits"
        ),
        FAQItem(
            question: "What building work doesn't need a permit at all?",
            answer: "Some minor work is exempt from both planning and building permits — for example small garden sheds under a certain size and height, low fences, and some minor repairs or like-for-like replacements. Exemptions depend on your zone, overlays, and the specific size and height thresholds in the regulations, so it's worth confirming on the Map screen or with council rather than assuming — what's exempt on one property can require a permit on another with an overlay.",
            category: "Permits"
        ),
        FAQItem(
            question: "What is an owner-builder, and do I need a permit to be one?",
            answer: "An owner-builder is someone who takes on the role of a licensed builder for their own project instead of hiring one. In Victoria, if the work is valued over a set threshold, you need an Owner-Builder Certificate of Consent from the Victorian Building Authority before you can apply for your building permit. You're also personally responsible for meeting all the same building standards a licensed builder would be.",
            category: "Permits"
        ),
        FAQItem(
            question: "Will my neighbours be notified about my planning permit application?",
            answer: "Council can require public notice for an application if your project could significantly affect neighbours — for example reduced setbacks, overlooking, or overshadowing. Notified neighbours usually have 14 days to lodge an objection, which can extend the standard decision timeframe. Projects that only involve minor or already-permitted work are often exempt from notice requirements.",
            category: "Planning Permits"
        ),
        FAQItem(
            question: "How does GroundTruth know my zone and overlays?",
            answer: "When you add a project's address, GroundTruth geocodes it and looks up the applicable zone and overlays directly from the official planning scheme data for your council area, rather than relying on a general estimate.",
            category: "Using GroundTruth"
        ),
        FAQItem(
            question: "How accurate is the cost estimate?",
            answer: "The cost estimate is a rough guide based on your floor area and project type, not a quote — actual costs vary with site conditions, finishes, and the builder you choose. Use it for early budgeting, and get a proper quote once you have a design.",
            category: "Using GroundTruth"
        ),
        FAQItem(
            question: "Where do I upload my permit documents?",
            answer: "Open a project and go to its Documents section to upload plans, permits, and other files — they're stored against that project so you can find them again later, including during the AI chat.",
            category: "Using GroundTruth"
        )
    ]
}
