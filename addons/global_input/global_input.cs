#if TOOLS
using Godot;
using System;

[Tool]
public partial class global_input : EditorPlugin
{
	private const string GlobalInputGDAutoloadName = "GlobalInput";

	public override void _EnterTree()
	{
		// Initialization of the plugin goes here.
		AddAutoloadSingleton(GlobalInputGDAutoloadName, "res://addons/global_input/autoload/global_input_gdscript/GlobalInputGDScript.tscn");
	}

	public override void _ExitTree()
	{
		// Clean-up of the plugin goes here.
		RemoveAutoloadSingleton(GlobalInputGDAutoloadName);
	}
}
#endif
