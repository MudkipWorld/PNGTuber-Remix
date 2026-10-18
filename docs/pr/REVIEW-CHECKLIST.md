# Reviewer checklist

Preparation status, 2026-10-18:

- [x] Exact V1.4.5 baseline and observed upstream default revision documented.
- [x] Localized motion compatibility isolated in its own commit with bilingual evidence.
- [x] Creator/player feature guards and separate personal settings included.
- [x] State, asset and cycle bindings included with keyboard/mouse handling and restoration.
- [x] Portable key generation, import, test, build and release smoke scripts included.
- [x] Private key directory, private test output, preferences and build output excluded from Git.
- [x] Ordinary clean import works without a private generated key file.
- [x] Independent static findings on nested binding validation and widget synchronization addressed.
- [x] Existing LICENSE preserved without additional grants.
- [ ] Maintainer decision on target branch and motion default.
- [ ] Forward port to current 1.4.x including new serializers and entry points.
- [ ] Resolve current mechanical conflicts in movements.gd and sprite_object.gd.
- [ ] Full device/OBS/native-dialog/mesh/animation and clean-machine acceptance.
- [ ] Independent security/cryptographic review if protection is marketed beyond ordinary UI restrictions.

See the package's PREPARATION-VALIDATION.txt for the final clean-clone command results. Unchecked items are not silently claimed complete by a local test pass.
