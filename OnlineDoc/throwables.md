# Throwables Feature Guide

The **Throwables** feature (found under the **Fun Stuff** tab in the right panel) allows you to throw interactive items at your PNGTuber avatar. The avatar will react physically when hit (if physics are enabled on your sprite layers).

---

## Getting Started

1. **Import Images**: First, ensure you have imported images into your project (using Files > Import, or via the File Manager).
2. **Add to Throw List**: Click the **+** (Add) button under the **Item List** in the Throwables panel to open the **Select Images** popup.
3. **Select and Confirm**: Choose the images you want to use for the throwable objects, then click **Confirm**. The popup will automatically close, and your selected items will appear in the active item list.
4. **Trigger Key**: Bind a key to **Throw Key** and press it in Preview mode to test.

---

## Configuration Settings

- **Distance**: The radius of the spawning circle around the target (selected object).
- **Degree**: The position on the circle where the spawner is located, from `-359` to `359` degrees.
  - `0` is directly on top of the target.
  - `90` is directly on the right.
  - `180` is directly on the bottom.
  - `-90` (or `270`) is directly on the left.
  - *Tip*: The slider spans the full width of the editor panel and automatically snaps to key directions (`0`, `90`, `180`, etc.) when dragged close to them. You can also type a precise angle directly into the linked numerical input box.
- **Throw Force**: The speed/impulse applied to throwables directed towards the target.
- **Per Trigger**: The number of throwables spawned per trigger.
- **Variance**: The angular randomization range (in degrees). The items will spawn on the circle at a randomized angle, while the distance from the target remains constant.
- **Base Mass**: Multiplier for the mass of the throwables.
- **Time Variance**: Random delay range between consecutive item throws in a single trigger.
- **Both Sides**: If enabled, the throwable spawns on either the configured side or its horizontally mirrored position at random.
- **Throw Key**: Key shortcut bound to trigger throwables.
- **Pause Throw Key**: Key shortcut bound to pause/stop currently active throws.

---

## Target Tracking

The spawner automatically tracks the **currently selected object or group** in the editor.
- When an object is selected, the spawner is positioned relative to the center of that object's texture.
- When no object is selected, the spawner centers itself on the avatar's default root origin `(0, 0)`.

---

## Troubleshooting

### Why are my throwables not reaching/hitting the target?
If your throwables fall short, curve downwards too early, or fail to reach the avatar, check your **Throw Force** and **Distance** settings:
- **Important Hint**: When objects are not hitting the target, the **Throw Force** value needs to be **larger than the Distance** value.
- Because throwables are subject to gravity and air resistance (inertia/friction), a spawner positioned far away (high Distance) requires a significantly higher Throw Force to propel items to the target center.
- Alternatively, decrease the **Distance** setting to spawn items closer to the avatar.
