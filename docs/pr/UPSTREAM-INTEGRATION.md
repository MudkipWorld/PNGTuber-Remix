# Upstream integration status

Checked on 2026-10-18. The public default branch is `1.4.x`, observed at `12c662b69288b33a7ed49a4e0834473c37fdbbf1`. The contribution is based on `V1.4.5` (`6b093894e33d804368367a0e98e1dc3722e4909b`). Do not use GitHub's current default branch as though it were identical to the tag.

The newer branch changes roughly 200 files, including throwable serialization, audio capture/native modules, model loading, input libraries, and motion components. This package supplies the latest completed protected V1.4.5 implementation and its evidence; it does not silently discard those upstream changes or claim a finished forward port.

## Suggested PR handling

Open a **draft PR** targeting `1.4.x` for maintainer discussion, with the documented V1.4.5 baseline and current integration gap visible in the opening paragraph. If maintainers want a maintained V1.4.5 branch, target that branch instead; a tag itself cannot be a PR base branch. The patch series applies to the exact V1.4.5 commit. Do not apply it blindly to a later branch or overwrite the newer tree with this source ZIP.

Motion compatibility is isolated in a separate commit. It intentionally replaces the GitHub tag's drag behavior with the identified localized runtime behavior. Maintainers can review or split that decision independently of the protected container feature. The report does not establish which implementation should be the universal default.

## Work required before merging into current development

1. Reconcile loader, save-path, guard and UI changes while retaining new upstream functionality. Cover newly introduced write/export/network entry points too.
2. Decide the intended protected target-version policy. Container and schema currently require exactly `1.4.5`; changing the version string alone is not a migration.
3. Extend schema and tests for newly serialized features such as throwable configuration and current native/audio resources, or explicitly reject unsupported models before scene replacement.
4. Reassess the localized drag compatibility commit against the current motion engine and native input libraries. Re-run state, asset, cycle and movement tests on the chosen base.
5. Rebuild with the current branch's required engine/templates, and perform physical input, microphone, rendering and OBS acceptance tests.

No code or binaries have been pushed by the preparation workflow. The submission materials are intended to be reviewed before any public upload. They contain no production build keys or private customer models.

## Mechanical merge audit

A three-way `git merge-tree` check against the observed default branch found content conflicts in `Scripts/Objects/ObjectComponents/movements.gd` and `Scripts/Objects/sprite_object.gd`. The check does not modify the working tree. Other files auto-merging is not evidence of runtime compatibility; the schema/native/audio forward-port work above still applies.
