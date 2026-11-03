# Handoff: UI, QOL, and Functionality Refinement for Demo (refinement/qol)

## Where things stand

Earlier work on this branch (location permission crash, stuck map sheet, stale location dot,
Firestore owner-scoped rules, three accessibility fixes) is done and shipped — see git log
(`c679d01`, `f142840`, `4348d2d`, `130d1f5`) if the detail is needed again. The AI-chat grounding
work from `refinement/AI-context` (regulatory excerpts via `RegulatoryExerptService`, resolved
live via `VicmapPlanningService`) is also done and unchanged.

Since then, this session did a substantial demo-polish pass, working through the "two dead rows"
and "costing is unclear" feedback from the previous handoff, in roughly this order:

- **About page** (`17d6002`): `ProfileView`'s inert "About GroundTruth" row now pushes a real
  `AboutView.swift` — a laymen's description of what the app does, written for a demo audience.
- **Customisable accent colour** (`e7794a1`, `8995ac6`): `ProfileView`'s "Appearance" placeholder
  now pushes `AppearanceView.swift` with a real `ColorPicker`, stored via `AccentColorStore`
  (`@AppStorage`, hex string) and applied with `.tint()` at the app root
  (`GroundTruthApp.swift`). Deliberately does **not** touch light/dark mode — Apple's HIG says
  that should stay under the system setting, not be overridden by the app. Default is the brand
  orange `#F09A65`, applied to both the `AccentColor` asset catalog entry and the
  `AccentColorStore` default so system surfaces and SwiftUI's `.tint()` agree.
- **App icon** (`53f8c41`, `348a0b8`): A Figma-designed icon run through Icon Kitchen had landed
  in the wrong place — its legacy per-size PNGs and `Contents.json` loose in `Assets.xcassets/`
  instead of inside `AppIcon.appiconset/`, which had also overwritten the catalog's own
  `Contents.json`. Fixed: catalog `Contents.json` restored, the one real 1024×1024 master moved
  into `AppIcon.appiconset/AppIcon-1024.png`, flattened from RGBA to RGB (Apple's App Store
  Connect validation rejects any alpha channel, even fully opaque), and wired into all three
  appearance slots (default/dark/tinted) — all three currently share the one image; true
  dark/tinted variants are a possible follow-up, not done.
- **FAQ expanded** (`388a9ea`): grew from 5 to 13 entries — added "what is a planning/building
  permit," the step-order of a project, other council permits that might apply, permit
  lifespans, exempt work, owner-builder rules, neighbour notification, and three
  app-specific entries ("how does GroundTruth know my zone," "how accurate is the cost
  estimate," "where do I upload documents"). New categories: Getting Started, Other Permits,
  Using GroundTruth.
- **Home screen chart** (`92ffd95`): a "Deadlines Over the Next 8 Weeks" line/area chart
  (SwiftUI `Charts`) sits between Upcoming Deadlines and Your Projects — real data, bucketed
  weekly from the same incomplete-task due dates the deadlines list already uses, not a
  fabricated series. Single series, tinted with the user's accent colour, no legend needed.
- **Status now tracks the roadmap** (`91b34a2`): `ProjectTask` gained a `phase: ProjectStatus`
  field (segmented picker when adding a step; a tappable `Menu` badge to reassign it after).
  `Project.effectiveStatus` derives the displayed status as the earliest phase with an
  incomplete step — finishing every step in a phase ticks the project over to the next one
  automatically. The old manual Status `Picker` in Edit Project only shows before any tasks
  exist; once there are tasks, it's a read-only badge with an explanatory caption, so it can't
  look like a dead control that silently does nothing.
- **Cost breakdown overhaul — the big one** (`9f40892` → `991e499`, five commits): replaced the
  single opaque "cost to build" number with four real line items — Construction (the existing
  ML model, now clearly labelled), Building Permit (a ~0.75%-of-cost-of-works formula), Planning
  Permit (looked up from Victoria's actual 2026-27 fee-class table — `PlanningPermitFeeClass`),
  and a 5-item Council Approvals checklist (`CouncilApprovalType` — real Cardinia Shire figures
  for Asset Protection, Vehicle Crossing, Legal Point of Discharge, Tree Removal; Septic Tank
  fee genuinely unpublished, shown as "cost not published" rather than a guess). Whether each
  one applies at all is decided by **one combined Gemini call**
  (`ProjectComplianceClassifierService`) grounded in the same zone/overlay +
  Planning-Scheme-excerpt + Building Practice Note data the chat already resolves, using a
  5-tier qualitative likelihood scale (`Required` → `Not required`) rather than a binary
  yes/no or a fake numeric probability. The AI only ever picks a likelihood tier and (for
  planning permit) a fee-class id — it never states a dollar figure; the app always looks that
  up from the hardcoded tables. Cached on `Project.complianceAssessment`, recomputed
  automatically when project scope is saved, or manually via an "Assess/Re-assess Permits &
  Approvals" button on the cost screen.

## Not yet verified by an actual build/run

Everything above was written on Windows without an Xcode toolchain, so none of it has been
compiled until the user builds on their Mac. One real bug has already surfaced and been fixed
this way: `Schema.object(...)` doesn't take a `requiredProperties:` parameter (verified against
the actual `firebase-ios-sdk` source on GitHub — every key in `properties` is required by
default; `optionalProperties:` is how you'd exempt one). The model name was also corrected
independently (`991e499`) from `gemini-3.1-flash` to `gemini-3.5-flash-lite` — presumably the
former wasn't available to this Firebase project.

Given that history, treat `ProjectComplianceClassifierService` as the least-proven file in the
app: confirm it actually returns a decodable response end-to-end (not just that it compiles),
and sanity-check the five council-approval rows and the two permit rows render correctly with
real data. Also worth a first look: the Home screen chart's layout at actual device width, and
the app icon across light/dark/tinted (the Mac work to replace them with distinct images, if
wanted, hasn't been done).

## Known, intentional gaps (not bugs — flagged so they're not re-discovered as surprises)

- **The AI chat still doesn't read uploaded document contents** — `GeminiService.swift` tells
  the model "names only, contents not available to you." Raised and deliberately deferred;
  doing this properly means extracting text from each upload and feeding relevant excerpts in,
  similar to the bundled Planning Scheme/Practice Note grounding. Meaningfully bigger than
  everything else in this list — scope it out explicitly before starting.
- **Fee schedules are 2026-27 figures and need annual re-verification.** Victoria's fee unit
  (and therefore every `PlanningPermitFeeClass` amount) changes every 1 July; Cardinia Shire's
  council fees in `CouncilApprovalSchedule.swift` likewise. Both files say so in comments.
- **Quick-add tasks in `NewProjectView`'s checklist all default to the Planning phase** (no
  phase picker in that quick-create flow, unlike the detail view's "Add a step" row). This is a
  deliberate scope boundary, not an oversight — it means a freshly created project with only
  quick-added steps will show status "Planning" until steps are tagged via the detail view.
- **Council approvals checklist is 5 items, not the 6 the FAQ lists** — "road/footpath
  occupation" was folded into Asset Protection Permit rather than kept separate, since in
  Cardinia's actual fee structure they appear to be the same permit.

## What's still open from the original App Store readiness audit (untouched this session)

Still not blocking the demo goal unless they get in the way:

- No in-app account deletion (Guideline 5.1.1(v)).
- No privacy policy (the About page doesn't link one either).
- No `PrivacyInfo.xcprivacy` manifest.
- `AppDelegate` still installs `AppCheckDebugProviderFactory()` unconditionally.
- Storage rules (`storage.rules`) scoping status still unconfirmed — see Open Questions below,
  carried over from before.

## Current goal: refine UI, QOL, and functionality for the demo

Still the operative goal. The two "obviously unfinished" rows from the last handoff (About,
Appearance) are done, the FAQ is fleshed out, and the costing story — the most-flagged
complaint — now has real structure and real numbers behind it instead of one fabricated
blended figure. The natural next focus, once the Mac build confirms everything above actually
works: the document-AI-awareness gap, and another pass at re-testing the core demo flows
end-to-end (create a project, map zone/overlay search, AI chat, cost + compliance breakdown)
now that several of them changed meaningfully this session.

## Open questions for next session

- Does `storage.rules` exist and match Firestore's per-owner scoping? Still not confirmed either
  way, carried over unresolved from the previous handoff.
- Should `firestore.rules`/`storage.rules` be committed into this repo rather than living only in
  the Firebase console? Still just a suggestion, not acted on.
- Does `gemini-3.5-flash-lite` hold up for the compliance-assessment call quality-wise, or does
  it need a stronger tier now that it's confirmed available? The original intent was "stronger
  than the chat model" for accuracy; worth checking the swap didn't undercut that.
- Is the 5-item council-approvals checklist missing anything a real demo address is likely to
  trigger, now that it's been exercised against actual projects rather than designed in the
  abstract?

## Collaboration note

Default workflow this project has used: give code in chat for the user to paste in, don't use
Edit/Write on app source directly unless explicitly asked. That default was explicitly
overridden for this session ("write the code unless I ask you not to") — everything above was
applied directly, not just explained. Treat that override as scoped to this session unless the
user restates it next time; default back to dictating code until they do.
