# Handoff: AI Advisor Context Grounding (refinement/AI-context)

## The problem
The AI advisor (`ProjectChatView` → `ProjectChatViewModel.swift` → `GeminiService.swift`) only ever sees Gemini's own pretrained general knowledge plus whatever the current project's own data says. `GeminiService.systemInstruction(for:)` (lines 25-58) builds its entire grounding from: project name, status, address, description, roadmap tasks, notes, and uploaded document **filenames only** (explicitly not contents — see the comment on line 53). There is zero actual regulatory source material anywhere in the pipeline, so for anything planning- or building-code-specific it has nothing authoritative to ground an answer in, and (reasonably, if unhelpfully) hedges toward "talk to council" rather than fabricate a confident wrong answer.

## Is this feasible? Yes — but naive "paste everything" is the wrong design
Source doc sizes, confirmed: Building Practice Note ~7 pages (small, fine to include whole), Building Code "10s of pages" minimum, Planning Scheme similarly long. Just concatenating all of that into `systemInstruction(for:)` would technically fit most context windows, but it's still a bad design for three concrete reasons:
1. **It gets resent on every single message, not once.** The system instruction is fixed once per `Chat` at `GeminiService.chatModel(for:)` (called once in `ProjectChatViewModel.init`), but it's part of every request's context for the rest of that conversation — so 30-50+ pages of mostly-irrelevant regulatory text gets paid for (tokens + latency) on *every message*, even a one-word follow-up.
2. **"Lost in the middle."** Long-context models measurably attend worse to a specific relevant paragraph when it's buried in a lot of irrelevant text, even when it technically fits the window. More included text isn't free accuracy — past a point it works against relevance.
3. **Latency.** Bigger prompt = slower time-to-first-token. Chat already shows a "Thinking..." indicator so it's not held to the cost estimator's instant-feeling bar, but a sluggish chat in a live demo is still bad.

**The fix is runtime selection against the full document, not pre-authored per-zone files.** A first design considered hand-splitting the Planning Scheme into files like `zone-GRZ.txt`/`overlay-HO.txt` ahead of time — rejected: that only covers whichever zones someone happened to pre-author a file for, i.e. still cherry-picking, just moved earlier in the pipeline. It wouldn't generalize to a project in a zone nobody thought to extract.

**The generalizable version:** convert each PDF to plain text **once** — a single generic asset, not authored per-zone — and at runtime, do a string search against that full text for whatever zone/overlay the *current* project's address actually resolves to via `VicmapPlanningService`, then extract just the text window around that match. Nothing about which zones are covered is decided in advance; the search key is whatever code comes back live for that project's address, so it works identically for any project, any zone, any overlay — including ones that don't exist in any pre-built demo data.

This is viable because Victorian planning schemes aren't freeform documents — every municipality's scheme (Cardinia included) follows the same state-wide Victorian Planning Provisions structure, so zone/overlay clauses are consistently headed (e.g. "General Residential Zone," "Heritage Overlay"). And the search-key generator already exists and is already tested: `PlanningStyle.zoneCategory(forZoneCode:)` / `overlayCategory(forOverlayCode:)` turns a raw code like `GRZ1` or `HO4` into its general category — reuse it rather than building a new mapping.

Same logic for the Building Code: instead of hardcoding "always include Class 1a and 10," key the search off whatever `project.costEstimateInputs.projectType` actually is *for that project* (New Build/Renovation/Extension → Class 1a section; Outdoor Works → Class 10 section) — driven by that project's real data, not a fixed assumption. If a project hasn't got scope info set yet, include nothing extra from the Building Code for it — same "don't guess" fallback used everywhere else in this app (matches `CostEstimatorService`'s `.unavailable` case).

## What should feed the AI
1. **Project info** — already working, no change needed.
2. **Building Practice Note, in full** — only 7 pages, cheap enough to just always include. Not worth searching/trimming further.
3. **Planning Scheme — runtime-matched excerpt, any zone/overlay.** Resolve the project's zone + overlay(s) via `VicmapPlanningService`, map each code to its category via the existing `PlanningStyle` functions, search the full scheme text for that category's clause heading, extract a window around the match. If the address doesn't resolve, or a match can't be found in the text, include nothing extra from this source for that project.
4. **Building Code — runtime-matched excerpt, keyed off the project's own `projectType`.** Search for the Class 1a or Class 10 heading depending on what the project's cost-estimate scope says it is. Nothing hardcoded about which class "the demo" uses.
5. **A custom instruction file** (new — e.g. `GroundTruth/Resources/AIInstructions.md`) — the role/tone/boundaries text currently hardcoded as Swift string literals in `systemInstruction(for:)`. Moving it to a bundled text file read at runtime (same auto-inclusion mechanism already confirmed working for `CostEstimator.mlmodel` via Xcode's synchronized-folder feature) makes it editable without recompiling. Should explicitly instruct the model to **cite which source it's drawing from** rather than blending regulatory fact with general knowledge indistinguishably, and to only say "confirm with council" for things genuinely outside the provided excerpts, not as a reflexive hedge.
6. **The ML cost estimate** — `CostEstimatorService` already exists and `Project.costEstimateInputs` is already wired up, but `GeminiService` never calls it. Adding its result as one more line (e.g. "Estimated cost: $182,000–$338,000 (preliminary)" or "No cost estimate yet") gives the AI a concrete, locally-computed real number to reference instead of refusing or guessing.

## Recommended approach for next session
1. **Verify the PDF-to-text conversion first, before building any search logic** — same go/no-go discipline as the ML data step. Convert both PDFs to plain text and manually check that zone/overlay/class headings survive as clean, findable strings (planning scheme PDFs are often multi-column, which can scramble extracted text order — this is the actual risk to rule out early, not the search logic itself).
2. Write a small, generic `findExcerpt(in: fullText, matching: searchTerms) -> String?` helper — not zone-specific, just "find a heading-like match for these terms, return N characters of context around it." Reused for zone, overlay, and building class lookups alike.
3. At chat init (`GeminiService.chatModel(for:)`), resolve the project's zone/overlay via `VicmapPlanningService` (likely needs an `async`-friendly entry point, since the function isn't currently callable outside `MapView`'s flow — check call sites), map codes to categories via `PlanningStyle`, run the excerpt search, and concatenate whatever's found alongside the full Building Practice Note and the instructions file.
4. Append the cost-estimate line using the existing service, same call site.
5. This keeps the existing once-per-chat system-instruction architecture intact — the generalization is entirely in *how* the excerpt is found (live search keyed by that project's real data) rather than *what's pre-chosen* to include.

**Not recommended for this timeline:** native PDF attachment via Gemini's document-understanding API (`FirebaseAILogic` may expose an inline/file-data `Part` type for PDFs). Plausible, and would avoid manual text extraction, but the exact SDK surface for this isn't confirmed yet — debugging an unfamiliar API under demo time pressure is a worse trade than the string-search approach above, which only needs plain Swift string handling.

## Open questions for next session
- PDF-to-text conversion quality — does the extracted text preserve clean, searchable zone/overlay/class headings, or does multi-column layout scramble it? Verify this first, before writing any matching logic.
- Does `VicmapPlanningService`'s zone/overlay lookup need to become `async`/independently callable to be used at chat init (outside `MapView`)?
- What should the system instruction say when zone/overlay resolution succeeds but no matching excerpt is found in the text (category exists but the search came up empty) — distinct from "address didn't resolve at all"?
- Exact context-window limit for `gemini-3.1-flash-lite` — low risk now that excerpts are small per-project windows rather than whole documents, but worth a sanity check.
- Whether `FirebaseAILogic` exposes a PDF/document `Part` type for native attachment (stretch goal, not blocking — see above).

## Files likely touched
- `GroundTruth/services/GeminiService.swift` — extend `systemInstruction(for:)` to be project-zone-aware, add the excerpt-search logic (or call out to a new small helper/service for it).
- New bundled resource files: full plain-text Planning Scheme, full plain-text Building Code, full Building Practice Note, and the instructions file (exact filenames/location TBD next session).
- Possibly `GroundTruth/services/VicmapPlanningService.swift` if its lookup needs an `async`-friendly entry point for use outside `MapView`.
- No changes expected to `ProjectChatViewModel.swift` or `ChatMessage.swift` — the send/receive/persist flow doesn't need to change, only what's baked into the system instruction at chat-start.

## Related, already-shipped work (for context)
- `GroundTruth/services/CostEstimatorService.swift` + `GroundTruth/models/Project.swift`'s `CostEstimateInputs` — on-device CoreML cost regressor, trained on real VIC Building Permit Activity Data (see git history on `feature/ML`, now merged to `main`). This is the "resource" referenced in point 4 above.
- `GroundTruth/services/VicmapPlanningService.swift` + `GroundTruth/services/PlanningStyle.swift` — live zone/overlay lookup and categorization, referenced in point 5 above.

## Collaboration note
Default workflow this project has used: give code in chat for the user to paste in, don't use Edit/Write on app source directly unless explicitly asked to. (Exception made recently for `CostEstimateInputSheet.swift`/`ProjectsView.swift` when explicitly asked to "do the remaining views yourself" — that was a one-off, not a standing change to the default.)
