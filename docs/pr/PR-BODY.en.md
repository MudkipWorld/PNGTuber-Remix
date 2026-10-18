# PR title

Add experimental protected model export and playback for V1.4.5

# PR body

This draft introduces a creator export and a paired playback-only application for sharing a working PNGTuber model without exposing the ordinary editing, model-save, or asset-export workflow. **The implementation is based on V1.4.5 (`6b09389`), not current `1.4.x`. It requires forward-port review before merging into the current default branch.** See [integration status](docs/pr/UPSTREAM-INTEGRATION.md).

## Behavior

A creator opens an ordinary `.pngRemix` project and exports `.pngRemixProtected` without changing the source save path. The matching player loads the encrypted model and uses the same animation/motion components. It exposes microphone/threshold/transparency, pan/zoom, state selection, and per-model keyboard/mouse remapping for states, switchable assets, and cycle toggle/next/previous. Restore controls recover author bindings. Invalid legacy Unknown overrides are ignored.

The player identity is a build feature. Editing and plaintext-save/export/backup routes are guarded in their implementations; hiding the editor is not the sole guard. Personal settings have a separate whitelist and storage. Source keys, settings, models and build artifacts are not part of the contribution.

## Format and keys

The v1 container authenticates its header and AES-256-CBC ciphertext using independent HMAC-SHA256 key material before decryption. The payload uses non-object Variant serialization and an explicit InputEvent whitelist, with structure and resource checks before scene replacement. See [format](docs/protected/format.md) and [entry points](docs/protected/entrypoints.md).

Build keys are generated locally, ignored by Git, and shared between creator/player builds. No production key is supplied. This is not DRM against reverse engineering or memory extraction: an offline player necessarily holds keys and decrypted motion data. The upstream LICENSE remains unchanged.

## Separately reviewable motion change

The user's supplied localized Windows 1.4.5 runtime differs from the GitHub tag in five motion scripts: four object state loaders additionally reset Dragger after a snap, and `movements.gd` uses local-coordinate interpolation instead of persistent shadow_drag smoothing. The contribution aligns with that identified runtime; it does not assert that every localized build differs or that the change originated in localization.

This change is a separate commit with [English evidence](docs/protected/motion-compatibility.en.md) and [Chinese evidence](docs/protected/motion-compatibility.zh-CN.md). Maintainer feedback is requested on whether to adopt, split, or make this behavior optional when forward-porting.

## Validation

- Automated suite: codec/tamper checks, model validation, guarded writes/network, state/asset/cycle preferences, mouse bindings, restoration and motion regressions.
- Demo export/load motion comparison: 11,700 samples, maximum difference 0.
- Identified local two-state project versus recovered runtime motion scripts: 15,840 fixed-input records, maximum difference 0. Private inputs are not uploaded; public tests use demo/synthetic fixtures.
- Windows release player model loading and normal window close tested; rendered UI inspected. Creator build/startup checked.
- Independent static-review findings on nested binding validation and preference-widget synchronization addressed.

See [build/test commands](docs/protected/build-and-test.md) and [validation limits](docs/protected/validation.md). No current-branch CI, exhaustive security audit, all-model compatibility, or physical-input/OBS acceptance is claimed. Loading uses in-memory snapshot recovery rather than an atomic staged scene swap. Known upstream headless shader/teardown diagnostics are recorded.

## Reviewer guide

Start with `Protected/ProtectedCodec.gd`, `ProtectedSchema.gd`, `ProtectedSession.gd`, and `ProtectionPolicy.gd`; then the loader/entry-point guards. Review `PlayerSettings.gd`, `ProtectedUI.gd`, `AssetBindings.gd`, `CycleBindings.gd`, and the cycle input dispatcher for personal bindings. Review the motion commit independently. Reproduce using fresh private keys per the build guide.
