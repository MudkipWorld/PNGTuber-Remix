# Protected player user guide

## Creator

1. Run the matching creator build and open your ordinary `.pngRemix` project.
2. Check the model, then select **Export protected** and save `.pngRemixProtected`.
3. Give the recipient the protected model and the matching player folder, including its DLLs.
4. Keep the ordinary project and private build keys yourself. Do not send the creator or developer directory as a playback deliverable.

Ordinary save and protected export are separate operations. Export includes current edits and preserves the ordinary project path. The official unmodified application cannot open this new container.

## Player

Open a protected model or drop it onto the window. Choose the microphone (`Default` uses the system input), adjust the speech threshold, and enable transparency if desired. Lower threshold makes speech easier to trigger. Use the state dropdown to select an expression/state. Scroll the wheel to zoom and use middle/right drag to pan the canvas. Tab hides or shows the control panel; the panel itself can scroll.

To assign a state shortcut, select the state, click its input field, and press a key/combination or right-click inside the field. The current binding is displayed. **Restore binding** removes the selected state's personal override. Invalid old `Unknown` entries are ignored so the author's original mouse input can work again.

In **Asset bindings**, select an authored switchable asset by name and ID, then bind its main trigger. Its original toggle, hold-to-show, or show-on-press behavior is preserved, including separate authored hide inputs. Use the asset restore button to recover its original trigger.

In **Cycle bindings**, select a cycle group and its toggle, next, or previous action. Each binding can be edited/restored independently. Toggle retains the upstream random reactivation behavior; next/previous follow the authored order. Empty models show disabled asset/cycle controls.

Binding and device changes save automatically when a model is loaded. **Save preferences** also saves zoom and pan. Preferences are separate from encrypted motion data and keyed by the protected file's hash. Re-exporting generates a different file identity, so preferences do not automatically migrate to a new export. Valid existing state preferences are retained.

Shared keys can intentionally operate multiple assets or cycles. Use different keys when independent control is desired. The application does not promise arbitrary hotkey conflict resolution across states, assets and cycles. Physical/global input behavior and OBS transparency must be checked in the recipient's environment.

## Limits

The player prevents ordinary supported editing/export/save routes; it is not an anti-reverse-engineering system. Runtime motion data and embedded keys can be extracted by a sufficiently capable recipient. Opening requires a player built with the same keys. Source code does not contain a universal key or production key.

The upstream LICENSE is retained without changes. Review it before distributing modified software; this contribution does not grant additional permission.
