# Handoff: UI, QOL, and Functionality Refinement for Demo (refinement/qol)

## Where things stand

The previous handoff on this file (`refinement/AI-context`) covered grounding the AI advisor in real
regulatory text. That work is done and shipped: `GeminiService.swift` builds its system instruction from
project data plus the on-device cost estimate plus a `RegulatoryExerptService`-selected excerpt of the
Cardinia Planning Scheme and the Building Practice Note, resolved live per-project via
`VicmapPlanningService`. No further work is planned there unless a bug turns up.

Since then, this branch (`refinement/qol`) has been going through an App Store readiness pass, fixing
issues as they're found rather than just documenting them. Fixed so far:

- **Location permission crash** (`c679d01`): `MapUserLocationButton()` in `MapView` had no
  `NSLocationWhenInUseUsageDescription`, so tapping it hung/crashed instead of prompting. Added
  `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` to both Debug and Release build configs in
  `project.pbxproj`.
- **Stuck map bottom sheet** (`f142840`): `MapView`'s `sheetDetent` initial state (`.height(100)`) wasn't
  a member of its own `presentationDetents` array (`[.height(140), .medium, .large]`), which SwiftUI
  silently rejected and which got exposed whenever the locate-me button forced a layout pass. Fixed by
  initializing `sheetDetent` to `.height(140)` instead.
- **Grey/stale user-location dot** (`4348d2d`): `MapView`'s `Map` content never included `UserAnnotation()`,
  so MapKit had nothing to render the live, updating blue dot with. Added.
- **Firestore security rules**: the console had `allow read, write: if request.auth.uid != null` on
  `/{document=**}`, i.e. any signed-in user could read/write any other user's data. Replaced (in the
  Firebase console, not committed to this repo — see Open Questions) with rules scoped to
  `request.auth.uid == resource.data.ownerId` / `== userId`, matching `Project.ownerId` and the
  `users/{userId}` profile doc shape.
- **Three accessibility fixes** (`130d1f5`): chat message bubbles now read as one grouped VoiceOver element
  (`ProjectChatView.messageBubble`) instead of three separate swipes; the map's zone/overlay filter rows
  now expose an explicit name + on/off state instead of VoiceOver reading the raw SF Symbol name off the
  checkbox icon (`MapView.categoryRow`); the cost estimate range now has an explicit "X to Y" accessibility
  label instead of leaving VoiceOver to interpret an en dash (`ProjectsView.costEstimateSection`).

## What's still open from the App Store readiness audit (not yet fixed)

These were identified but are **not** blocking the current goal (see below) unless they start getting in
the way of demoing the app:

- No in-app account deletion (Guideline 5.1.1(v)) — `ProfileView` only has Sign Out.
- No app icon images — `AppIcon.appiconset/Contents.json` still has empty slots for all three
  (light/dark/tinted) 1024x1024 variants. This blocks archiving for submission, not just review, but
  doesn't affect running the app in Simulator/on a device for a demo.
- No privacy policy, and no link to one from `ProfileView`'s inert "About GroundTruth" row.
- No `PrivacyInfo.xcprivacy` manifest on the app target.
- `GroundTruthApp.swift`'s `AppDelegate` still installs `AppCheckDebugProviderFactory()` unconditionally;
  fine for a demo, needs swapping to a real App Attest/DeviceCheck provider before any real release build.
- Storage rules (`storage.rules`, separate from Firestore's rules, covers uploaded project documents) —
  status unconfirmed, see Open Questions.
- `ProfileView`'s "Appearance" row is a literal `Text("Appearance settings coming soon.")` placeholder.

None of these are Swift logic bugs; they're either Xcode project configuration, Firebase console
configuration, or missing assets/copy.

## Current goal: refine UI, QOL, and functionality for the demo

Direction has shifted from "prepare for App Store submission" to "make the app demo well." This is a
looser, less checklist-shaped goal than the readiness audit was, so the next session should work from
actual observed friction (either from running the app, or from whatever the next message raises) rather
than assuming a fixed list. Worth deliberately re-testing the flows most likely to get exercised live in a
demo: creating a project end to end, the map's zone/overlay search and filtering, the AI chat (including a
case where regulatory grounding fails to resolve, to see how gracefully it degrades), and the cost
estimator's fallback states.

Two things already known to be rough and worth prioritizing if nothing more pressing turns up:
1. `ProfileView`'s "Appearance" and "About GroundTruth" rows are dead/placeholder UI — a demo-visible
   screen with "coming soon" text looks unfinished even if it's not a functional bug.
2. No accessibility work has been done beyond the three specific fixes above; they were chosen because
   they were the clearest, most isolated wins, not because they're the only gaps.

## Open questions for next session

- Does a `storage.rules` file (or equivalent console configuration) exist and is it scoped per-owner the
  same way Firestore's rules now are? Not yet confirmed either way.
- Should `firestore.rules` (and `storage.rules` once checked) be committed into this repo as actual files
  rather than living only in the Firebase console? Would make them reviewable/versioned; flagged as a
  suggestion previously, not yet acted on.
- What's actually most valuable to polish for the demo — is there a specific flow the demo will walk
  through, or should refinement be broad across the app?

## Collaboration note

Default workflow this project has used: give code in chat for the user to paste in, don't use Edit/Write
on app source directly unless explicitly asked to. That's been relaxed somewhat during this bug-fixing
pass — once a fix is explained, a plain "do it"/"sure" is being treated as permission to make that specific
edit directly, but it's still asked for per-change rather than assumed as a standing default.
