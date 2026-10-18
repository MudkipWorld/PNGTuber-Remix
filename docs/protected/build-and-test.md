# Build and test

Prerequisites: Windows x64, PowerShell, Git, **Godot 4.6 stable**, and matching official Windows export templates. Linux/macOS exports are not validated by this contribution. Existing native extension libraries remain upstream files.

## First checkout

```powershell
# From the repository root. Set paths appropriate to your machine.
$env:GODOT_PATH = 'C:/Tools/Godot/Godot_v4.6-stable_win64_console.exe'
./tools/new-protected-keys.ps1
./tools/test-protected.ps1
```

The generator creates 32-byte AES and HMAC keys and a 16-byte identifier using the system cryptographic RNG. It refuses to overwrite existing keys. `Protected/generated/` is ignored by Git. Back up the generated file privately; do not attach it to a PR, issue, source archive, or customer delivery. No key values are printed by these tools. The fixed bytes in codec unit tests are public test fixtures, not build keys.

Godot imports are performed before testing/exporting. A bootstrap pass creates upstream font/translation caches; a second pass must load them without resource or script errors. Test output is in `build/tests/`. A missing key file produces an actionable script error; it does not silently generate a different key set. The normal source project can start without the generated file; protected operations then fail closed.

## Export both roles

Place `windows_release_x86_64.exe` and `windows_debug_x86_64.exe` from the Godot 4.6 export templates in a directory, then run:

```powershell
./tools/build-protected.ps1 -Role creator -TemplateDir 'C:/Tools/Godot/Templates'
./tools/build-protected.ps1 -Role player  -TemplateDir 'C:/Tools/Godot/Templates'
```

If omitted, `TemplateDir` defaults to the directory containing the Godot executable. `GodotPath` can also be passed explicitly; without either it or `GODOT_PATH`, the scripts look for `godot` on PATH.

The scripts temporarily add `protected_creator` or `protected_player` export features, choose the templates, embed the PCK, and restore `project.godot` and `export_presets.cfg` in `finally`. **Do not run two exports concurrently in one checkout**, because both temporarily update those files.

Outputs are `build/creator/` and `build/player/`. Deliver the EXE together with all emitted DLLs, LICENSE, and relevant documentation. Exclude build logs from customer archives. Tests, tools, docs and unprotected demo model files are excluded from the embedded PCK; documentation is copied alongside the executable. Never distribute the working tree's generated key source file.

## Verification commands

```powershell
./tools/test-protected.ps1
./tools/build-protected.ps1 -Role player -TemplateDir 'C:/Tools/Godot/Templates'
./tools/smoke-player.ps1
```

The smoke test needs a Windows desktop session and the protected demo created by the test suite. It starts the release player, waits for successful model loading, sends a normal window-close message, and checks logs. It is not a physical keyboard/mouse, microphone, or OBS end-to-end test.

Optional rendered source probe (after tests):

```powershell
& $env:GODOT_PATH --path . --rendering-driver opengl3 res://tests/protected/player_probe.tscn
```

The probe writes `tests/protected/out/player-preview.png`. For deterministic motion diagnostics use `state_switch_probe.tscn` with user arguments `model=<path>` and `output=<path>`; neither model data nor traces belong in a public PR. The default model is an upstream demo and default output is `user://state-switch-trace.json`.

## Reproducibility and compatibility

Generate fresh local keys to reproduce builds from public source. The original private key set is intentionally absent, so these newly built binaries will not open previously distributed models from another key set. Preserve keys across later creator/player rebuilds if compatibility is required.

Known Godot/upstream dummy-shader and teardown diagnostics are recorded in [validation.md](validation.md). A passing script also requires the suite completion marker and no script/parse/resource-load failures; exit code alone is insufficient.
