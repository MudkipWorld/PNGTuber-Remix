# Missing auto-load model regression

From the repository root, with Godot 4.7.2 available as `godot` (Bash / Git Bash):

```sh
test_dir="$(mktemp -d)"
mkdir -p "$test_dir/Scripts/UI/Menu" "$test_dir/Localization" "$test_dir/tests/fixtures"
cp -R tests/fixtures/autoload "$test_dir/tests/fixtures/"
cp tests/test_missing_autoload_model.gd "$test_dir/tests/"
cp Scripts/UI/Menu/menu.gd "$test_dir/Scripts/UI/Menu/"
cp Localization/translations.csv "$test_dir/Localization/"
cp tests/fixtures/autoload/project.cfg "$test_dir/project.godot"
godot --headless --path "$test_dir" --editor --import
godot --headless --path "$test_dir"
```

The fixture calls the production startup `auto_load_model` method. It checks
real file presence and the actual `AcceptDialog` with English strings read from
the production translation CSV. A minimal loader records load requests instead
of decoding a full model. Other startup services are disabled in the fixture.
The test writes and removes only its own file in the fixture's user-data folder.

All assertions must pass, the process must exit with code 0, and the log must
contain no `ERROR`, `SCRIPT ERROR` or `FAIL` diagnostics. Omit `--headless` in the
last command to exercise the same assertions with a desktop window.
