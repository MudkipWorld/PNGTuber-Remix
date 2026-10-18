# Protected creator and player

This experimental contribution targets **PNGTuber-Remix V1.4.5**, commit `6b093894e33d804368367a0e98e1dc3722e4909b`. A creator exports an authenticated encrypted `.pngRemixProtected` model; a matching player runs its motion without exposing normal editing, model saving, or asset export through supported UI and service entry points.

This is an offline playback format, not a promise that runtime data or keys cannot be recovered. The running player must hold decrypted model data. The existing upstream LICENSE is unchanged.

## Contents

- [English user guide](user-guide.en.md) / [中文使用说明](user-guide.zh-CN.md)
- [Build and test guide](build-and-test.md)
- [Container format](format.md) and [protected entry points](entrypoints.md)
- [Motion comparison in English](motion-compatibility.en.md) / [运动逻辑差异](motion-compatibility.zh-CN.md)
- [Validation and limitations](validation.md)
- [Upstream integration status](../pr/UPSTREAM-INTEGRATION.md)
- [English PR body](../pr/PR-BODY.en.md) / [中文 PR 说明](../pr/PR-BODY.zh-CN.md)

## Feature summary

Creator: retain ordinary `.pngRemix` editing and save behavior, with a separate protected export button. Export snapshots the current in-memory model without changing its source save path.

Player: open or drop a protected model, select microphone and speech threshold, change transparency, pan/zoom, select states, and remap state, asset, and cycle inputs. Keyboard and mouse preferences are stored per protected-file identity, separately from the model. Invalid legacy `Unknown` key overrides are ignored. Restore buttons recover author bindings.

Assets retain their author's toggle/hold/show behavior. The main asset trigger can be remapped; separately authored hide actions remain unchanged. Cycles expose toggle/forward/backward bindings and keep existing ordering and random reactivation behavior. Shared asset/cycle keys can trigger multiple actions. State overrides remove conflicting state keys.

Only already-authored assets and cycles are listed. The player does not create model parts or edit motion parameters. The panel scrolls and Tab hides/shows it.

## Keys and clean checkout

No production keys are included. Run `tools/new-protected-keys.ps1` once before protected tests or exports; keep that generated file private and use it for both roles. A clean project can open without keys, but protected export/load requires a valid generated key file. A newly generated pair of builds cannot read models encrypted by another key set.

## Review status

This is a draft contribution against the V1.4.5 baseline, not a completed forward port to the current `1.4.x` branch. Review the motion compatibility change separately: it deliberately follows one identified localized runtime and changes the GitHub tag's motion behavior.
