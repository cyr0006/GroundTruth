//
//  AddressSearchField.swift
//  GroundTruth
//

import SwiftUI
import MapKit

/// A text field with live address autocomplete, backed by MapKit's on-device
/// search completer. Drop in anywhere a plain address `TextField` was used.
struct AddressSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search an address"
    var leadingIcon: String? = nil
    var onSelect: (String, CLLocationCoordinate2D?) -> Void = { _, _ in }

    @StateObject private var completer = AddressSearchCompleter()
    @FocusState private var isFocused: Bool
    @State private var isResolving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(.secondary)
                }

                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        completer.queryFragment = newValue
                    }

                if isResolving {
                    ProgressView()
                } else if !text.isEmpty {
                    Button {
                        text = ""
                        completer.queryFragment = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isFocused && !completer.results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(completer.results.enumerated()), id: \.offset) { _, result in
                        Button {
                            select(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        isFocused = false
        isResolving = true
        Task {
            defer { isResolving = false }
            do {
                let (address, coordinate) = try await completer.resolve(completion)
                text = address
                onSelect(address, coordinate)
            } catch {
                let fallback = [completion.title, completion.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
                text = fallback
                onSelect(fallback, nil)
            }
        }
    }
}

#Preview {
    @Previewable @State var address = ""
    AddressSearchField(text: $address, leadingIcon: "magnifyingglass")
        .padding()
}
