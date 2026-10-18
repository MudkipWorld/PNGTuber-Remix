# PNGTuber Remix 1.4.5 Motion Compatibility Report

Date: 2026-10-18  
Scope: The user-supplied Chinese-localized Windows runtime compared with the GitHub V1.4.5 source tag.

## Conclusion

The two builds both identify as version 1.4.5, but differ in Drag Snap state-transition handling and drag smoothing. The initial protected build used the GitHub tag, so the same project and parameter values could behave differently from the user's existing runtime. This was not merely a parameter display or transfer issue.

The five relevant motion scripts in the protected creator and player have been aligned with the supplied runtime. These findings apply only to the identified sample. The evidence does not establish who introduced the differences or when, and should not be generalized to every localized build.

## Compared samples

- GitHub repository: <https://github.com/MudkipWorld/PNGTuber-Remix/tree/V1.4.5>
- Tag: `V1.4.5`; commit: `6b093894e33d804368367a0e98e1dc3722e4909b`.
- Local sample: the user's Chinese-localized Windows `PNGTube Remix.pck`.
- Package SHA256: `350E2FB208D2D297E1A52C632F1853EE264EB3C4F6691E5176ED151E96594781`.
- Method: recover GDScript from the local runtime, compare the code, and compare compiled-script MD5 values after the fix. The original installation and user project were not modified.

## Difference 1 Resetting the drag follower after a snap

When a state transition moves an object farther than `drag_snap`, and the threshold is not `999999.0`, the GitHub tag resets only the global position of `Modifier`. The supplied runtime also resets `Dragger`:

```gdscript
%Modifier.global_position = %Modifier1.global_position
%Dragger.global_position = %Modifier.global_position
```

The second line is the relevant difference. Without it, the displayed object can snap while its drag follower retains the previous position, allowing subsequent movement calculations to retain residual drag. The threshold comparison is strictly greater than; `999999.0` is a special value that disables this snap branch.

Affected scripts:

- `Scripts/Objects/sprite_object.gd`
- `Scripts/Objects/append_object.gd`
- `Scripts/Objects/comment_object.gd`
- `Scripts/Misc/mesh_object.gd`

## Difference 2 Drag smoothing

The second difference is in `drag()` in `Scripts/Objects/ObjectComponents/movements.gd`. Both implementations advance the follower using `1.0 / dragSpeed`, but calculate the resulting position differently.

The GitHub tag keeps a persistent `shadow_drag` value:

```gdscript
shadow_drag = shadow_drag.lerp(dragger.global_position - target, 0.85)
applied_pos += shadow_drag
```

The supplied runtime converts the follower position into the actor's local coordinates and interpolates:

```gdscript
applied_pos = applied_pos.lerp(actor.to_local(dragger.global_position), 0.5)
```

This is an algorithm difference, not a direct conversion between two coefficients. Identical Drag Snap and Drag values do not guarantee identical trajectories. The fix adopts the supplied runtime's local-coordinate calculation and removes the unused `shadow_drag` state.

## Verification

- Both installations had physics update rate 60, maximum physics steps 10, and jitter compensation 0.5. These settings did not explain the discrepancy.
- Regression tests for follower reset and reference drag output failed before the fix and passed afterwards. Boundary thresholds and the `999999.0` no-snap behavior also passed.
- The user's current two-state project was exercised for 240 frames at fixed 60 Hz input, switching states every 40 frames. The 15,840 records contain Modifier coordinates, Dragger coordinates, and drag_snap. The maximum numerical difference between the fixed build and the recovered local runtime motion scripts was 0.
- The compiled GDC MD5 values for all five corrected motion scripts match the supplied runtime individually. This does not imply that the complete applications are identical.
- Protected-format regression tests passed. The sample motion comparison before and after protected export also passed with 11,700 samples and maximum difference 0.

## Usage and limits

Use creator and player builds that include the Drag Snap fix. The protected format and keys are unchanged; existing protected files do not need to be exported again because of this motion fix.

The evidence covers source inspection, compiled content, and fixed-input numerical tests. It does not certify every model, live microphone setup, OBS capture method, frame rate, or device environment. The separate mouse-shortcut preference override issue concerns input handling and is not part of the motion-algorithm differences described here.
