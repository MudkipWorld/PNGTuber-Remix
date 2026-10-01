# RawMouseInput - Windows only

This GDExtension reads raw mouse deltas through the Win32 `RAWINPUT` API, so the model keeps
following the real pointer movement while another application (typically a game that locks
the cursor to the centre of the screen) has the foreground focus.

## What is shipped

Only the Windows libraries:

```
RawMouseInput/windows/rawmouseinput.windows.template_debug.x86_64.dll
RawMouseInput/windows/rawmouseinput.windows.template_release.x86_64.dll
RawMouseInput/windows/librawmouseinput.windows.template_*.x86_64.a
```

There is no Linux or macOS build, and there is no plan to add one: the implementation is
Win32 specific (a hidden message-only window, a dedicated background thread, and
event-driven re-registration instead of polling).

## Consequences for other platforms

`rawmouseinput.gdextension` lists no library for other platforms, so Godot reports
`No GDExtension library found for current OS and architecture ... (linux.x86_64)` there.
That alone is harmless, but **the class does not exist on those platforms either**, so any
script that names the type at parse time fails to load. `Scripts/Global/StandGlobalInput.gd`
therefore resolves it at runtime (`ClassDB.class_exists("RawMouseInput")` +
`ClassDB.instantiate(...)`) and only does so on Windows; the mouse-follow code falls back to
the mouse-position delta when it is absent.
Before that change, an exported Linux build could not start at all: the autoload failed with
`Parse Error: Could not find type "RawMouseInput"`.

## Export note

The extension stays in the package on every platform; nothing is excluded. On a platform
without a library Godot prints three lines at start-up:

```
ERROR: No GDExtension library found for current OS and architecture (linux.x86_64) in configuration file: res://RawMouseInput/rawmouseinput.gdextension
ERROR: GDExtension dynamic library not found: 'res://RawMouseInput/rawmouseinput.gdextension'.
ERROR: Error loading extension: 'res://RawMouseInput/rawmouseinput.gdextension'.
```

They are expected and harmless: no script names the class at parse time, so nothing else
fails (see the runtime lookup above). Leaving the package untouched also means a future
Linux build needs no export-preset change at all - add a `linux.release.x86_64` entry here
next to the Windows ones and it is picked up automatically.
