# PNGTuber-Remix WebSocket API Documentation

PNGTuber-Remix includes a built-in WebSocket server that allows external applications (like Streamer.bot, TouchPortal, or custom scripts) to interact with the application and trigger various actions dynamically. 

## Connection Details

- **Default Port**: `9321` (Can be changed in the settings)
- **Protocol**: `ws://` (or `wss://` if TLS is configured)
- **Data Format**: All messages sent and received must be **JSON** objects.

To execute a command, send a JSON object containing an `"event"` field along with any other required parameters for that specific event.

---

## Available Events

### 1. `ping`
Test the connection to the WebSocket server.
**Request:**
```json
{
  "event": "ping"
}
```
**Response:**
```json
{
  "event": "pong"
}
```

---

### 2. `state`
Switch the avatar's current active state (e.g., changing from "Idle" to "Happy").
**Request:**
```json
{
  "event": "state",
  "state_name": "Happy" // Alternatively, you can use "state_id": 1
}
```
**Response:**
```json
{
  "event": "state",
  "result": "success",
  "state_id": 1,
  "state_name": "Happy"
}
```

---

### 3. `general`
Trigger the behavior of sprites bound to a specific physical keyboard key.
**Request:**
```json
{
  "event": "general",
  "key": "A"
}
```
**Response:**
```json
{
  "event": "general",
  "result": "success",
  "key": "A",
  "actions_found": ["Hat (Toggle)", "Glasses (Hide)"]
}
```

---

### 4. Sprite Visibility (`hide_sprite`, `show_sprite`, `toggle_sprite`)
Control the visibility of an individual sprite by its name or ID.
**Request (Hide/Show):**
```json
{
  "event": "hide_sprite", // or "show_sprite"
  "sprite_name": "Hat" // Or "sprite_id": 123
}
```

**Request (Toggle):**
```json
{
  "event": "toggle_sprite",
  "sprite_name": "Hat",
  "reverse": false, // Optional: if true and match_sprite is set, does the opposite
  "match_sprite": "Glasses" // Optional: syncs visibility with another sprite
}
```

---

### 5. Group Visibility (`hide_group`, `show_group`, `toggle_group`)
Control the visibility of a sprite group and all of its children recursively.
**Request:**
```json
{
  "event": "hide_group", // or "show_group", "toggle_group"
  "group_name": "Accessories" // Or "group_id": 456
}
```

---

### 6. Query Commands (`list_sprites`, `list_states`, `list_groups`)
Retrieve a list of available items and their current properties.
**Request:**
```json
{
  "event": "list_sprites" // or "list_states", "list_groups"
}
```
**Response Example (`list_states`):**
```json
{
  "event": "list_states",
  "result": "success",
  "states": [
    { "name": "Idle", "id": 1, "is_current": true },
    { "name": "Happy", "id": 2, "is_current": false }
  ]
}
```

---

### 7. Animations & Movement
Trigger animations and coordinate movements on a specific sprite.

**Move Sprite:**
Moves a sprite to exact X/Y coordinates.
```json
{
  "event": "move_sprite",
  "sprite_name": "Pet",
  "x": 100.0,
  "y": -50.0,
  "duration": 1.0,
  "reset": true,
  "reset_delay": 2.0
}
```

**Animate Sprite:**
Change the scale and rotation of a sprite over time.
```json
{
  "event": "animate_sprite",
  "sprite_name": "Arm",
  "scale_x": 1.5,
  "scale_y": 1.5, // Or just use "scale" to set both
  "rotation": 45.0,
  "duration": 1.0,
  "reset": false
}
```

**Shake Sprite:**
Applies a random shaking effect for a specified duration.
```json
{
  "event": "shake_sprite",
  "sprite_name": "Body",
  "intensity": 10.0,
  "duration": 1.0
}
```

**Bounce Sprite:**
Makes a sprite bounce upwards and then back down.
```json
{
  "event": "bounce_sprite",
  "sprite_name": "Hat",
  "height": 20.0,
  "duration": 0.5
}
```

---

### 8. Throwable Items
Trigger the throwable item spawner to launch items at the avatar.

**Throw Specific Item:**
```json
{
  "event": "throw_item",
  "item_name": "Tomato",
  "amount": 1,
  "variance": 0.5, // Optional: location spawn variance
  "both_sides": true // Optional: whether to spawn on both sides simultaneously
}
```

**Throw Random Items:**
```json
{
  "event": "throw_random",
  "amount": 5, // Optional: If omitted, uses default amount
  "variance": 0.5,
  "both_sides": true
}
```

**Toggle Throwables Pause:**
Instantly stops any currently throwing items and prevents new items from being thrown until toggled again.
```json
{
  "event": "toggle_throwables_pause",
  "pause": true // Optional: boolean to explicitly set pause state. If omitted, toggles current state.
}
```

---

### 9. Load Model
Load a `.pngRemix` or `.save` avatar model file from your computer.
**Request:**
```json
{
  "event": "load_model",
  "file_path": "C:/Path/To/Your/Model.pngRemix"
}
```
**Response:**
```json
{
  "event": "load_model",
  "result": "success",
  "file_path": "C:/Path/To/Your/Model.pngRemix"
}
```

## Error Handling
If you send an invalid JSON structure, an unsupported event name, or parameters for items that don't exist, the server will return an error object.

**Example Error Response:**
```json
{
  "event": "error",
  "message": "Unknown event: something_else"
}
```
