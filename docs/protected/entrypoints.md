# Protected player entry points

Player identity: exported `protected_player` feature; project setting also permits local development tests. No UI or user command-line switch disables the exported feature.

- SaveAndLoad: save_model, save_backup, export_images, ordinary load_model, legacy import, PSD import and object import denied at their implementations.
- load_file: player routes to ProtectedSession, creator refuses protected extension.
- Global.set_mode forces preview; Global._input cannot rotate/edit selected objects.
- Main: original editing UI hidden before first frame; drag/drop assets, new, save-as, replace and import routes denied.
- Menu: save shortcut, automatic ordinary-model load and session switching denied.
- Settings: auto_save and save-on-exit model writes denied; ordinary theme serialization disabled for player. Only separate PlayerSettings whitelist persists customer configuration.
- WebsocketHandler.listen returns unauthorized. No local websocket server is opened.
- CommandLine: original preferences/autosave path override disabled for player.
- MeshEditor: editing input denied.
- ProtectedUI: protected open, microphone, threshold, transparency, state selection, key remapping and personal preferences only.

Tests call save/backup/export/autosave/listen directly and check observable filesystem/network outcomes. No hidden editor UI is treated as the sole protection of model serialization.

AssetBindings and CycleBindings add only per-model personal input overrides. Asset author flags and cycle order are preserved. Cycle input dispatch consults player overrides and otherwise retains the original event polling path. These preferences cannot set model motion values.
