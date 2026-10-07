# Handoff: Vicmap Planning Zones & Overlays (feature/mapping)

## What this feature does
`MapView.swift` shows an address-searchable map with two togglable layers — Planning Zones and Planning Overlays — colored polygons pulled live from Victoria's open Vicmap Planning data, plus a property info card showing the real zone/overlay name(s) for whatever address is selected.

## Data source (verified working, no API key)
Public Esri ArcGIS REST FeatureServer (not a `*.vic.gov.au` host, but it's the API DataVic's own dataset page designates — see https://discover.data.vic.gov.au/dataset/vicmap-planning-api):

- Base: `https://services-ap1.arcgis.com/P744lA0wf4LlBZ84/ArcGIS/rest/services/Vicmap_Planning/FeatureServer`
- Layer **3 = PLAN_ZONE** (zones), layer **2 = PLAN_OVERLAY** (overlays)
- Query via plain GET to `.../FeatureServer/{layerId}/query` with `geometryType=esriGeometryEnvelope` (bbox, for rendering) or `esriGeometryPoint` (single address lookup), `f=geojson` — response decodes directly with `MKGeoJSONDecoder`
- `where=1=1` is fine — checked `zone_status` across a sample, it's always `"g"` (gazetted), no historical-record filtering needed
- `maxRecordCount: 2000`/layer; ArcGIS sets `exceededTransferLimit: true` if a query is truncated — handled in `VicmapPlanningService` by logging a warning, not erroring

## Files
- **`GroundTruth/models/PlanningFeature.swift`** — `PlanningFeatureProperties` (generic `code`/`description`/`lga`/`status`, decoded from wire fields `zone_code`/`zone_description`/`lga`/`zone_status` — those wire names are reused by Vicmap for *both* zone and overlay layers, hence the generic Swift-side naming), `PlanningFeature` (id + `[MKPolygon]` + properties), `PropertyPlanningInfo` (zoneName + overlayNames, for the info card).
- **`GroundTruth/services/PlanningZoneStyle.swift`** — zone-code → color and overlay-code → color lookups (prefix-based, e.g. `GRZ1` → residential family, `HO1` → Heritage brown). **Pending rename** (discussed, not yet confirmed applied): rename file + enum to `PlanningStyle` (it styles both zones and overlays now, "Zone" in the name is stale), and rename `overlayColor(forOverlayCode:)` → `color(forOverlayCode:)` to overload the existing `color(forZoneCode:)` instead of two differently-shaped names.
- **`GroundTruth/services/VicmapPlanningService.swift`** — the REST client: `fetchZonePolygons(in:)`, `fetchOverlayPolygons(in:)` (bbox queries), `fetchPlanningInfo(at:)` (point query, both layers).
- **`GroundTruth/views/MapView.swift`** — wires it all in: debounced viewport fetch on `.onMapCameraChange`, point fetch on address selection, `PlanningPolygonItem` flat arrays (`zonePolygonItems`/`overlayPolygonItems`) feeding single-level `ForEach`s in the `Map` builder, real data in `propertyInfoCard`, attribution badge + overlay color legend.

## Non-obvious decisions / gotchas hit this session
1. **Nested `ForEach`-in-`ForEach` inside `Map { }` caused "unable to type-check in reasonable time."** Not primarily a hardware issue (though slower Macs hit it sooner) — `MapContentBuilder` chokes on deeply nested generic builder expressions. Fixed by flattening `[PlanningFeature]` → flat `[PlanningPolygonItem]` arrays as plain computed properties *before* the view builder sees them, so each `Map` content branch is a single flat `ForEach`.
2. **Zone/overlay naming conflation**: the shared properties struct originally used zone-flavored field names (`zoneCode`/`zoneDescription`) even when holding overlay data, because Vicmap's wire format reuses those field names on both layers. Renamed to neutral `code`/`description`/`status`. The fetch logic itself was always correctly separated (separate layer IDs, separate arrays) — this was a naming/readability fix, not a bug fix.
3. Overlays all looked identical at first (one hardcoded `.brown` stroke) — fixed with a second color lookup keyed by overlay code prefix (HO/VPO/SLO/ESO/BMO/etc.), plus a small on-map legend, since color alone without a key isn't informative.

## Not yet done
- Confirm the three pending renames above are actually applied (`PlanningZoneStyle` → `PlanningStyle`, `overlayColor` → `color(forOverlayCode:)`) — they were dictated in chat, not written to disk by Claude (this session's workflow: code is given to paste in manually, not auto-applied).
- **Tap-to-identify**: tapping an arbitrary polygon on the map to see its name, the way selecting an address already does. Discussed as a possible follow-up, explicitly not built yet — would need `MapReader`/`MapProxy` coordinate hit-testing.
- Full verification pass from the original plan hasn't been explicitly re-confirmed after the latest styling/legend changes: search a real address, toggle each layer, pan to an area with a known overlay (e.g. heritage-listed inner-Melbourne suburb), test an address with no overlay, test with network off.
- Original plan file (if still useful for reference): `C:\Users\Aryan\.claude\plans\i-aim-to-implement-inherited-locket.md`.

## Collaboration note
This session's workflow: give code in chat for the user to paste into Xcode themselves; don't use Edit/Write on actual app source files unless explicitly asked to write directly.
