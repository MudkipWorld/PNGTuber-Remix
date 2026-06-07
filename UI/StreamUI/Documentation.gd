extends Node
class_name WebsocketDoc


static var doc : String = '# PNGTuber Remix WebSocket API Documentation

This document provides comprehensive documentation for all available WebSocket commands in PNGTuber Remix.

## Connection Information
- **Default Port**: 9321
- **Protocol**: WebSocket
- **Message Format**: JSON

## Available Commands

### 1. Ping/Pong
Test connection to the server.

**Request:**
```json
{"event": "ping"}
```

**Response:**
```json
{"event": "pong"}
```

---

### 2. State Management
Switch between different character states (expressions, poses, etc.) by name or ID.

**Request by Name:**
```json
{"event": "state", "state_name": "Pickles Idle"}
```

**Request by ID:**
```json
{"event": "state", "state_id": 1}
```

**Parameters:**
- `state_name` (string): The name of the state to switch to
- `state_id` (integer): The state number to switch to (1-based indexing)

**Success Response:**
```json
{"event": "state", "result": "success", "state_id": 1, "state_name": "Pickles Idle"}
```

**Error Response:**
```json
{"event": "state", "result": "failed", "error": "state not found", "identifier": "Invalid State", "available_states": 3}
```

**Example Usage:**
```javascript
// Switch by name (recommended - more user-friendly)
websocket.send("{"event": "state", "state_name": "Pickles Idle"}");
websocket.send("{"event": "state", "state_name": "Pickles Smug"}");
websocket.send("{"event": "state", "state_name": "Pickles Distracted"}");

// Switch by ID (still supported)
websocket.send("{"event": "state", "state_id": 1}");
websocket.send("{"event": "state", "state_id": 2}");
websocket.send("{"event": "state", "state_id": 3}");
```

---

### 3. General Key Press
Trigger hotkey events in the application.

**Request:**
```json
{"event": "general", "key": "space"}
```

**Parameters:**
- `key` (string): The key name to trigger

**Response:**
```json
{"event": "state", "result": "success"}
```

---

### 4. Hide Sprite
Hide a specific sprite by name or ID. If the sprite is a group (has children), all children will be hidden too.

**Request:**
```json
{"event": "hide_sprite", "sprite_name": "Hat"}
```
OR
```json
{"event": "hide_sprite", "sprite_id": "12345"}
```
OR
```json
{"event": "hide_sprite", "id": "12345"}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to hide
- `sprite_id` (string): ID of the sprite to hide
- `id` (string/number): Generic ID of the sprite to hide

**Success Response:**
```json
{"event": "hide_sprite", "result": "success", "identifier": "Hat"}
```

**Error Response:**
```json
{"event": "hide_sprite", "result": "failed", "identifier": "Hat", "error": "sprite not found"}
```

**Note:** If the sprite is a group parent (like "WholeHead2"), all its children will be hidden as well.

---

### 5. Show Sprite
Show a specific sprite by name or ID. If the sprite is a group (has children), all children will be shown too.

**Request:**
```json
{"event": "show_sprite", "sprite_name": "Glasses"}
```
OR
```json
{"event": "show_sprite", "sprite_id": "67890"}
```
OR
```json
{"event": "show_sprite", "id": 67890.0}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to show
- `sprite_id` (string): ID of the sprite to show
- `id` (string/number): Generic ID of the sprite to show

**Success Response:**
```json
{"event": "show_sprite", "result": "success", "identifier": "Glasses"}
```

**Error Response:**
```json
{"event": "show_sprite", "result": "failed", "identifier": "Glasses", "error": "sprite not found"}
```

**Note:** If the sprite is a group parent (like "WholeHead2"), all its children will be shown as well.

---

### 6. Toggle Sprite Visibility
Toggle the visibility of a specific sprite by name or ID. If the sprite is a group (has children), all children will be toggled too.

**Request:**
```json
{"event": "toggle_sprite", "sprite_name": "Background"}
```
OR
```json
{"event": "toggle_sprite", "id": 537693010870.0}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to toggle
- `sprite_id` (string): ID of the sprite to toggle
- `id` (string/number): Generic ID of the sprite to toggle

**Success Response:**
```json
{"event": "toggle_sprite", "result": "success", "identifier": "Background", "visibility": "visible"}
```
OR
```json
{"event": "toggle_sprite", "result": "success", "identifier": "Background", "visibility": "hidden"}
```

**Error Response:**
```json
{"event": "toggle_sprite", "result": "failed", "identifier": "Background", "error": "sprite not found"}
```

**Note:** If the sprite is a group parent (like "WholeHead2"), all its children will be toggled as well.

---

### 7. List All Sprites
Get a list of all sprites with their current visibility status, IDs, and group information.

**Request:**
```json
{"event": "list_sprites"}
```

**Response:**
```json
{
  "event": "list_sprites",
  "result": "success",
  "sprites": [
	{
	  "name": "WholeHead2", 
	  "visible": true, 
	  "id": 12345, 
	  "is_group": true, 
	  "children": ["EarL2", "EarR2", "Head2", "Face2"], 
	  "parent_id": 0
	},
	{
	  "name": "EarL2", 
	  "visible": true, 
	  "id": 67890, 
	  "is_group": false, 
	  "children": [], 
	  "parent_id": 12345
	}
  ]
}
```

---

### 7.1. List Groups
Get a list of all sprites that have children (groups only).

**Request:**
```json
{"event": "list_groups"}
```

**Response:**
```json
{
  "event": "list_groups", 
  "result": "success", 
  "groups": [
	{
	  "name": "WholeHead2", 
	  "visible": true, 
	  "id": 12345, 
	  "children": ["EarL2", "EarR2", "Head2", "Face2"], 
	  "child_count": 4
	}
  ]
}
```

---

### 7.2. Hide Group
Hide a group and all its children by name or ID. This works the same as hide_sprite but is more explicit for group operations.

**Request:**
```json
{"event": "hide_group", "group_name": "WholeHead2"}
```
OR
```json
{"event": "hide_group", "group_id": "12345"}
```
OR
```json
{"event": "hide_group", "id": "WholeHead2"}
```

**Parameters:**
- `group_name` (string): Name of the group to hide
- `group_id` (string): ID of the group to hide
- `id` (string/number): Generic ID of the group to hide

**Success Response:**
```json
{"event": "hide_group", "result": "success", "identifier": "WholeHead2"}
```

**Error Response:**
```json
{"event": "hide_group", "result": "failed", "identifier": "WholeHead2", "error": "group not found"}
```

---

### 7.3. Show Group
Show a group and all its children by name or ID.

**Request:**
```json
{"event": "show_group", "group_name": "WholeHead2"}
```
OR
```json
{"event": "show_group", "group_id": "12345"}
```
OR
```json
{"event": "show_group", "id": "WholeHead2"}
```

**Parameters:**
- `group_name` (string): Name of the group to show
- `group_id` (string): ID of the group to show
- `id` (string/number): Generic ID of the group to show

**Success Response:**
```json
{"event": "show_group", "result": "success", "identifier": "WholeHead2"}
```

**Error Response:**
```json
{"event": "show_group", "result": "failed", "identifier": "WholeHead2", "error": "group not found"}
```

---

### 7.4. Toggle Group
Toggle a group"s visibility and all its children.

**Request:**
```json
{"event": "toggle_group", "group_name": "WholeHead2"}
```
OR
```json
{"event": "toggle_group", "group_id": "12345"}
```
OR
```json
{"event": "toggle_group", "id": "WholeHead2"}
```

**Parameters:**
- `group_name` (string): Name of the group to toggle
- `group_id` (string): ID of the group to toggle
- `id` (string/number): Generic ID of the group to toggle

**Success Response:**
```json
{"event": "toggle_group", "result": "success", "identifier": "WholeHead2", "visibility": "hidden"}
```

**Error Response:**
```json
{"event": "toggle_group", "result": "failed", "identifier": "WholeHead2", "error": "group not found"}
```

---

## Phase 1: Movement & Animation Commands

### 7.5. Move Sprite
Move a sprite to a specific position with smooth animation. Optionally auto-reset to original position.

**Request:**
```json
{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 1.0}
```
**With Auto-Reset:**
```json
{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 1.0, "reset": true, "reset_delay": 2.0}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to move
- `sprite_id` (string): ID of the sprite to move  
- `id` (string/number): Generic ID of the sprite to move
- `x` (number): Target X position
- `y` (number): Target Y position
- `duration` (number): Animation duration in seconds (default: 1.0)
- `reset` (boolean): Auto-reset to original position (default: false)
- `reset_delay` (number): Delay before resetting in seconds (default: 0.0)

**Success Response:**
```json
{"event": "move_sprite", "result": "success", "identifier": "EyeL", "x": 100, "y": 50, "duration": 1.0, "reset": true}
```

**Error Response:**
```json
{"event": "move_sprite", "result": "failed", "identifier": "EyeL", "error": "sprite not found"}
```

**Note:** With `reset: true`, the sprite will move to the target position, wait for `reset_delay` seconds, then smoothly return to its original position.

---

### 7.6. Animate Sprite
Animate sprite scale and rotation with smooth transitions. Optionally auto-reset to original state.

**Request:**
```json
{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.2, "rotation": 15, "duration": 0.5}
```
**With Auto-Reset:**
```json
{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.2, "rotation": 15, "duration": 0.5, "reset": true, "reset_delay": 1.0}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to animate
- `sprite_id` (string): ID of the sprite to animate
- `id` (string/number): Generic ID of the sprite to animate
- `scale` (number): Uniform scale factor (applies to both X and Y)
- `scale_x` (number): X-axis scale factor (default: 1.0)
- `scale_y` (number): Y-axis scale factor (default: same as scale_x)
- `rotation` (number): Target rotation in degrees (default: 0.0)
- `duration` (number): Animation duration in seconds (default: 1.0)
- `reset` (boolean): Auto-reset to original state (default: false)
- `reset_delay` (number): Delay before resetting in seconds (default: 0.0)

**Success Response:**
```json
{"event": "animate_sprite", "result": "success", "identifier": "Head", "scale_x": 1.2, "scale_y": 1.2, "rotation": 15, "duration": 0.5, "reset": true}
```

**Error Response:**
```json
{"event": "animate_sprite", "result": "failed", "identifier": "Head", "error": "sprite not found"}
```

**Note:** With `reset: true`, the sprite will animate to the target scale/rotation, wait for `reset_delay` seconds, then smoothly return to its original state.

---

### 7.7. Shake Sprite
Add a shake/vibration effect to a sprite with random movement.

**Request:**
```json
{"event": "shake_sprite", "sprite_name": "WholeHead2", "intensity": 10, "duration": 2.0}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to shake
- `sprite_id` (string): ID of the sprite to shake
- `id` (string/number): Generic ID of the sprite to shake
- `intensity` (number): Shake intensity in pixels (default: 10.0)
- `duration` (number): Shake duration in seconds (default: 1.0)

**Success Response:**
```json
{"event": "shake_sprite", "result": "success", "identifier": "WholeHead2", "intensity": 10, "duration": 2.0}
```

**Error Response:**
```json
{"event": "shake_sprite", "result": "failed", "identifier": "WholeHead2", "error": "sprite not found"}
```

---

### 7.8. Bounce Sprite
Create a bouncing animation effect on a sprite.

**Request:**
```json
{"event": "bounce_sprite", "sprite_name": "Hat", "height": 20, "duration": 0.5}
```

**Parameters:**
- `sprite_name` (string): Name of the sprite to bounce
- `sprite_id` (string): ID of the sprite to bounce
- `id` (string/number): Generic ID of the sprite to bounce
- `height` (number): Bounce height in pixels (default: 20.0)
- `duration` (number): Bounce duration in seconds (default: 0.5)

**Success Response:**
```json
{"event": "bounce_sprite", "result": "success", "identifier": "Hat", "height": 20, "duration": 0.5}
```

**Error Response:**
```json
{"event": "bounce_sprite", "result": "failed", "identifier": "Hat", "error": "sprite not found"}
```

---

### 8. List All States
Get a list of all available states with their names, IDs, and current status.

**Request:**
```json
{"event": "list_states"}
```

**Response:**
```json
{
  "event": "list_states",
  "result": "success",
  "states": [
	{"name": "Pickles Idle", "id": 1, "is_current": true},
	{"name": "Pickles Smug", "id": 2, "is_current": false},
	{"name": "Pickles Distracted", "id": 3, "is_current": false}
  ]
}
```

---

### 9. Load Model
Load a different PNGTuber model file for performance optimization or model switching.

**Request:**
```json
{"event": "load_model", "file_path": "C:/Models/SimpleModel.pngRemix"}
```

**Parameters:**
- `file_path` (string): Full path to the model file (.pngRemix or .save)

**Success Response:**
```json
{"event": "load_model", "result": "success", "file_path": "C:/Models/SimpleModel.pngRemix"}
```

**Error Responses:**
```json
{"event": "load_model", "result": "failed", "file_path": "", "error": "file_path is required"}
```
```json
{"event": "load_model", "result": "failed", "file_path": "missing.pngRemix", "error": "file not found"}
```
```json
{"event": "load_model", "result": "failed", "file_path": "model.txt", "error": "invalid file extension, must be .pngRemix or .save"}
```

**Supported File Types:**
- `.pngRemix` - PNGTuber Remix model files
- `.save` - Legacy format files

---

## Usage Examples

### JavaScript WebSocket Client
```javascript
// Connect to the WebSocket server
const websocket = new WebSocket("ws://localhost:9321");

websocket.onopen = function() {
	console.log("Connected to PNGTuber Remix");
	
	// Test connection
	websocket.send("{"event": "ping"}");
};

websocket.onmessage = function(event) {
	const response = JSON.parse(event.data);
	console.log("Received:", response);
};

// Switch to happy state by name (recommended)
websocket.send("{"event": "state", "state_name": "Pickles Smug"}");

// Switch to state by ID (still works)
websocket.send("{"event": "state", "state_id": 2}");

// Hide hat
websocket.send("{"event": "hide_sprite", "sprite_name": "Hat"}");

// Show glasses
websocket.send("{"event": "show_sprite", "sprite_name": "Glasses"}");

// Toggle background visibility
websocket.send("{"event": "toggle_sprite", "sprite_name": "Background"}");

// Hide entire head group (including all children like ears, eyes, mouth)
websocket.send("{"event": "hide_group", "group_name": "WholeHead2"}");

// Show entire head group 
websocket.send("{"event": "show_group", "group_name": "WholeHead2"}");

// Toggle entire head group
websocket.send("{"event": "toggle_group", "group_name": "WholeHead2"}");

// Get list of all sprites (including group information)
websocket.send("{"event": "list_sprites"}");

// Get list of groups only
websocket.send("{"event": "list_groups"}");

// Animation commands (Phase 1)
websocket.send("{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 1.0}");
websocket.send("{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.2, "rotation": 15, "duration": 0.5}");
websocket.send("{"event": "shake_sprite", "sprite_name": "WholeHead2", "intensity": 10, "duration": 2.0}");
websocket.send("{"event": "bounce_sprite", "sprite_name": "Hat", "height": 20, "duration": 0.5}");

// Animation with auto-reset (perfect for temporary reactions)
websocket.send("{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 0.5, "reset": true, "reset_delay": 2.0}");
websocket.send("{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.3, "rotation": 10, "duration": 0.3, "reset": true, "reset_delay": 1.0}");

// Get list of all states
websocket.send("{"event": "list_states"}");

// Load a different model
websocket.send("{"event": "load_model", "file_path": "C:/Models/PerformanceModel.pngRemix"}");
```

### Python WebSocket Client
```python
import websocket
import json

def on_message(ws, message):
	response = json.loads(message)
	print(f"Received: {response}")

def on_open(ws):
	print("Connected to PNGTuber Remix")
	# Test connection
	ws.send("{"event": "ping"}")

# Connect to WebSocket
ws = websocket.WebSocketApp("ws://localhost:9321",
						   on_open=on_open,
						   on_message=on_message)

# Switch states by name (recommended)
ws.send("{"event": "state", "state_name": "Pickles Idle"}")

# Switch states by ID (still works)
ws.send("{"event": "state", "state_id": 1}")

# Get available states
ws.send("{"event": "list_states"}")

# Control sprite visibility
ws.send("{"event": "hide_sprite", "sprite_name": "Hat"}")
ws.send("{"event": "toggle_sprite", "id": 12345}")

# Control group visibility (affects all children too)
ws.send("{"event": "hide_group", "group_name": "WholeHead2"}")
ws.send("{"event": "show_group", "group_name": "WholeHead2"}")
ws.send("{"event": "toggle_group", "group_name": "WholeHead2"}")

# Get group information
ws.send("{"event": "list_groups"}")

# Animation commands (Phase 1)
ws.send("{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 1.0}")
ws.send("{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.2, "rotation": 15, "duration": 0.5}")
ws.send("{"event": "shake_sprite", "sprite_name": "WholeHead2", "intensity": 10, "duration": 2.0}")
ws.send("{"event": "bounce_sprite", "sprite_name": "Hat", "height": 20, "duration": 0.5}")

# Animation with auto-reset (perfect for temporary reactions)
ws.send("{"event": "move_sprite", "sprite_name": "EyeL", "x": 100, "y": 50, "duration": 0.5, "reset": true, "reset_delay": 2.0}")
ws.send("{"event": "animate_sprite", "sprite_name": "Head", "scale": 1.3, "rotation": 10, "duration": 0.3, "reset": true, "reset_delay": 1.0}")
```

## Error Handling

All commands follow a consistent error response format:
- `result`: Always "failed" for errors
- `error`: Description of what went wrong
- Additional context-specific fields when applicable

Common error types:
- **"sprite not found"**: The specified sprite name or ID doesn"t exist
- **"invalid state_id"**: The state number is out of range
- **"file_path is required"**: Missing required parameter
- **"file not found"**: The specified file doesn"t exist
- **"invalid file extension"**: Unsupported file format

## Tips for Performance

1. **Model Switching**: Use `load_model` to switch between complex and simple models based on performance needs
2. **Sprite Management**: Use `list_sprites` to discover available sprites before controlling them
3. **Group Operations**: 
   - Use `list_groups` to discover which sprites are group parents
   - Group operations (hide/show/toggle group) automatically affect all children
   - Individual sprite commands also work with groups - hiding a group parent hides all children
   - Use group commands for cleaner, more intentional group operations
4. **Animation Commands (Phase 1)**:
   - `move_sprite`: Smooth position transitions perfect for repositioning elements
   - `animate_sprite`: Scale and rotate sprites for emphasis or expression changes
   - `shake_sprite`: Add impact effects or attention-grabbing vibrations
   - `bounce_sprite`: Create playful bouncing effects for reactions
   - All animations save state automatically when complete
4. **State Management**: 
   - Use `list_states` to discover available states and their names
   - Prefer state names over IDs for better readability: `"Pickles Smug"` vs `2`
   - States are 1-indexed when using IDs (state 1, state 2, etc.)
5. **ID vs Name**: Both sprite names and IDs work - use whichever is more convenient
6. **File Paths**: Use absolute paths for `load_model` to avoid path resolution issues

## Troubleshooting

1. **No Response**: Check that the WebSocket server is running on port 9321
2. **State Not Changing**: 
   - Use `list_states` to see all available states and their exact names
   - Verify state names match exactly (case-sensitive)
   - If using state_id, verify it"s within the available range
3. **Sprite Not Found**: Use `list_sprites` to see all available sprites and their current names/IDs
4. **Model Won"t Load**: Check file path exists and has correct extension (.pngRemix or .save)

'
