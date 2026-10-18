# Validation record

Baseline: official `V1.4.5`, commit `6b093894e33d804368367a0e98e1dc3722e4909b`. Engine: Godot 4.6 stable on Windows x64. This record distinguishes automated checks from broader acceptance testing.

## Automated coverage

- AES-256-CBC reference vector; authenticated container round trip; corrupted, truncated, trailing and wrong-key input rejection; header checks before payload allocation.
- Non-object Variant payload, InputEvent whitelist, model settings types, parent cycles, PNG decoding and dimensions, malformed state bindings and cycle structures.
- Upstream demo protected export/load, unchanged source path, overwrite refusal, state counts, and failed-file preservation of the current scene.
- Player editing-mode, ordinary saving, backup, image-export, autosave and WebSocket entry-point guards.
- Keyboard/mouse preferences: invalid Unknown rejection, state collisions and default restoration, asset/cycle action installation, persistence/reload, per-action restoration, author-data preservation, and stale-action cleanup on model changes.
- Restored threshold and transparency controls reflect active settings.
- Localized motion compatibility regression: follower resets at the snap threshold and reference drag output, including threshold boundaries and disabled sentinel.
- Demo 300-frame round trip: 11,700 motion samples with maximum difference 0.

## Additional local evidence

The supplied user's two-state model was compared against motion scripts recovered from their identified localized runtime: 240 fixed-input frames, 15,840 records, maximum difference 0. The private model and generated traces are not included. Public regression tests use upstream demo data and small synthetic fixtures. See the bilingual motion report for the sample identifier and exact scope.

The Windows release player loaded a protected model through a path containing Chinese text and spaces, then closed through the normal window-close route with exit code 0. A rendered UI screenshot was inspected. Creator release startup was checked. Re-run the documented scripts for the exact checkout under review; past evidence is not a promise of compatibility with later upstream branches.

## Known limitations

- Loading uses validation followed by in-memory snapshot recovery, not a fully staged atomic scene swap. A runtime restoration may restart animation phases. Exhaustive runtime fault injection has not been performed.
- Schema checks are not a complete security audit of every upstream mesh/animation resource shape. The authenticated format and resource limits do not eliminate all memory exhaustion or engine-parser risk.
- Not all models, meshes, appendages, animated images, native file dialogs, live microphone/physical input combinations, clean machines, or OBS setups have been tested.
- The unmodified V1.4.5 baseline also emits dummy-renderer shader diagnostics and ObjectDB exit-leak warnings during headless runs. Script/parse/load failures remain test failures.
- A timed `--quit-after` shutdown with real audio previously reproduced an access violation in the baseline too. The normal menu/window-close path passed; microphone input was not disabled in that release smoke check.
- Source changes have not been forward-ported or validated against current upstream `1.4.x`. No hosted CI success is claimed.

## Review follow-up

An independent static review found insufficient validation of nested state/cycle bindings and stale preference widgets. Both were addressed with regression coverage before preparing this source package. This review does not constitute an independent cryptographic/security audit.
