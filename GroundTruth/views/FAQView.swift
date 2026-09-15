//
//  FAQView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI

struct FAQView: View {
    private let faqs = FAQItem.sampleFAQs
    @State private var searchText = ""

    private var groupedFAQs: [(category: String, items: [FAQItem])] {
        let filtered = searchText.isEmpty
            ? faqs
            : faqs.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }

        let grouped = Dictionary(grouping: filtered, by: \.category)
        return grouped
            .map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedFAQs, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.items) { faq in
                            DisclosureGroup {
                                Text(faq.answer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            } label: {
                                Text(faq.question)
                                    .font(.body)
                            }
                        }
                    }
                }

                if groupedFAQs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("FAQ")
            .searchable(text: $searchText, prompt: "Search planning & building topics")
        }
    }
}

#Preview {
    FAQView()
}
