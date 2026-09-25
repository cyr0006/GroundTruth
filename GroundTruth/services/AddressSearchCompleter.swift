//
//  AddressSearchCompleter.swift
//  GroundTruth
//

import Foundation
import MapKit
import Contacts

@MainActor
final class AddressSearchCompleter: NSObject, ObservableObject {
    @Published var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
            if queryFragment.isEmpty {
                results = []
            }
        }
    }
    @Published private(set) var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    /// Resolves a tapped completion into a full formatted address and its coordinate.
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> (address: String, coordinate: CLLocationCoordinate2D?) {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        let fallback = [completion.title, completion.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")

        guard let item = response.mapItems.first else {
            return (fallback, nil)
        }

        let address = item.placemark.postalAddress
            .map { CNPostalAddressFormatter().string(from: $0).replacingOccurrences(of: "\n", with: ", ") }
            ?? fallback

        return (address, item.placemark.coordinate)
    }
}

extension AddressSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
