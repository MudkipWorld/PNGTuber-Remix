# WebSocket state-selection regression

From the repository root, with Godot 4.7.2 available as `godot` (Bash / Git Bash):

```sh
test_dir="$(mktemp -d)"
mkdir -p "$test_dir/Main/Scripts" "$test_dir/Scripts/UI/States" "$test_dir/tests/fixtures"
cp -R tests/fixtures/websocket "$test_dir/tests/fixtures/"
cp tests/test_websocket_state_selection.gd "$test_dir/tests/"
cp Main/Scripts/websocket_handler.gd "$test_dir/Main/Scripts/"
cp Scripts/UI/States/StateButton.gd "$test_dir/Scripts/UI/States/"
cp tests/fixtures/websocket/project.cfg "$test_dir/project.godot"
cp tests/fixtures/websocket/sprite_object.gd.stub "$test_dir/tests/fixtures/websocket/sprite_object.gd"
godot --headless --path "$test_dir" --editor --import
godot --headless --path "$test_dir"
```

The fixture executes the production JSON dispatcher and `StateButton`, including
real selection-marker controls. Only network sending and application services
outside the selection change are replaced. It does not open a socket or decode
a full model. The unused `SpriteObject` parameter type is supplied only in the
temporary project; its `.stub` extension prevents registering a duplicate class
in the actual application.

All assertions must pass, the process must exit with code 0, and the log must
contain no `ERROR`, `SCRIPT ERROR` or `FAIL` diagnostics.
