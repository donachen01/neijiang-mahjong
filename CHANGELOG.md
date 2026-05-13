# Changelog

## 1.0.26 - 2026-05-13

- Restyled the main action buttons into large circular mahjong controls with primary yellow-orange and secondary green variants.
- Restored selected-hand AI explanation details so the discard helper shows C# candidate comparisons, posterior reasons, risk reasons, and expected-score deltas.
- Enlarged the AI discard helper into a wider phone-readable prompt with larger outlined text.
- Added UI regression coverage for circular action buttons and C# candidate detail display in the helper panel.

## 1.0.25 - 2026-05-13

- Set this snapshot as the new stable development base after the `1.0.24` baseline.
- Refined the main table presentation, including a larger center wall-count disc, no desktop frame line, and a simplified right-side control stack with a top-right exit button.
- Fixed Neijiang Mahjong flow priorities so opening bao-jiao decisions block automatic dealer discard until resolved.
- Fixed self-hu and settlement UI details so self-hu no longer shows discard guidance and Neijiang settlement no longer displays stale missing-suit text.
- Updated Android package metadata and export scripts so generated APK filenames include the version number.

## 1.0.4 - 2026-05-10

- Replaced the self-hu source text label with the same arrow-style claim marker used elsewhere.
- Reduced the left and right opponent meld tiles a little more so the side meld areas feel less oversized.
- Updated the contract and preview capture to lock the new claim badge and smaller side meld size.

## 1.0.3 - 2026-05-10

- Centered the AI discard helper on the main board and made the prompt reason line readable on mobile.
- Updated the discard hint preview to show a short reason directly under the recommended tile text.
- Bumped the tracked source and Android package versions to keep the release metadata in sync.

## 1.0.2 - 2026-05-10

- Enlarged the floating AI discard helper and reduced it to centered direct content so the hint stays readable on mobile.
- Replaced the recommended-tile outline marker with a continuously rotating cone centered on the suggested tile.
- Updated the V17 layout contract to lock the helper panel readability rules and cone marker behavior.

## 1.0.1 - 2026-05-10

- Tuned the opposite player's hand, meld, and winning-tile lane to sit closer to the player info area without overlapping it.
- Reduced left/right opponent meld tile scale and recalculated side winning-tile slots so the tile stays inside the frame.
- Updated the V17 layout contract to lock the new opponent lane spacing and side winning-tile behavior.

## 1.0.0 - 2026-05-10

- Created the first GitHub-ready source snapshot for the Neijiang Mahjong Godot project.
- Added repository hygiene for Godot, .NET, Android build outputs, export artifacts, and signing files.
- Recorded the baseline app version and version-management workflow.
