using Godot;
using Godot.Collections;
using System;
using SharpHook;
using System.Linq;

public partial class GlobalInputCSharp : Node
{
    #region Setup
    TaskPoolGlobalHook Hook = new();

	Dictionary<string, string[]> GodotKeyToSharpKey = new()
    {
        {Key.None.ToString(), new string[] {SharpHook.Native.KeyCode.VcUndefined.ToString()}},

        {Key.Escape.ToString(), new string[] {SharpHook.Native.KeyCode.VcEscape.ToString()}},
        {Key.F1.ToString(), new string[] {SharpHook.Native.KeyCode.VcF1.ToString()}},
        {Key.F2.ToString(), new string[] {SharpHook.Native.KeyCode.VcF2.ToString()}},
        {Key.F3.ToString(), new string[] {SharpHook.Native.KeyCode.VcF3.ToString()}},
        {Key.F4.ToString(), new string[] {SharpHook.Native.KeyCode.VcF4.ToString()}},
        {Key.F5.ToString(), new string[] {SharpHook.Native.KeyCode.VcF5.ToString()}},
        {Key.F6.ToString(), new string[] {SharpHook.Native.KeyCode.VcF6.ToString()}},
        {Key.F7.ToString(), new string[] {SharpHook.Native.KeyCode.VcF7.ToString()}},
        {Key.F8.ToString(), new string[] {SharpHook.Native.KeyCode.VcF8.ToString()}},
        {Key.F9.ToString(), new string[] {SharpHook.Native.KeyCode.VcF9.ToString()}},
        {Key.F10.ToString(), new string[] {SharpHook.Native.KeyCode.VcF10.ToString()}},
        {Key.F11.ToString(), new string[] {SharpHook.Native.KeyCode.VcF11.ToString()}},
        {Key.F12.ToString(), new string[] {SharpHook.Native.KeyCode.VcF12.ToString()}},
        {Key.F13.ToString(), new string[] {SharpHook.Native.KeyCode.VcF13.ToString()}},
        {Key.F14.ToString(), new string[] {SharpHook.Native.KeyCode.VcF14.ToString()}},
        {Key.F15.ToString(), new string[] {SharpHook.Native.KeyCode.VcF15.ToString()}},
        {Key.F16.ToString(), new string[] {SharpHook.Native.KeyCode.VcF16.ToString()}},
        {Key.F17.ToString(), new string[] {SharpHook.Native.KeyCode.VcF17.ToString()}},
        {Key.F18.ToString(), new string[] {SharpHook.Native.KeyCode.VcF18.ToString()}},
        {Key.F19.ToString(), new string[] {SharpHook.Native.KeyCode.VcF19.ToString()}},
        {Key.F20.ToString(), new string[] {SharpHook.Native.KeyCode.VcF20.ToString()}},
        {Key.F21.ToString(), new string[] {SharpHook.Native.KeyCode.VcF21.ToString()}},
        {Key.F22.ToString(), new string[] {SharpHook.Native.KeyCode.VcF22.ToString()}},
        {Key.F23.ToString(), new string[] {SharpHook.Native.KeyCode.VcF23.ToString()}},
        {Key.F24.ToString(), new string[] {SharpHook.Native.KeyCode.VcF24.ToString()}},

        {Key.Quoteleft.ToString(), new string[] {SharpHook.Native.KeyCode.VcBackQuote.ToString()}},
        {Key.Key0.ToString(), new string[] {SharpHook.Native.KeyCode.Vc0.ToString()}},
        {Key.Key1.ToString(), new string[] {SharpHook.Native.KeyCode.Vc1.ToString()}},
        {Key.Key2.ToString(), new string[] {SharpHook.Native.KeyCode.Vc2.ToString()}},
        {Key.Key3.ToString(), new string[] {SharpHook.Native.KeyCode.Vc3.ToString()}},
        {Key.Key4.ToString(), new string[] {SharpHook.Native.KeyCode.Vc4.ToString()}},
        {Key.Key5.ToString(), new string[] {SharpHook.Native.KeyCode.Vc5.ToString()}},
        {Key.Key6.ToString(), new string[] {SharpHook.Native.KeyCode.Vc6.ToString()}},
        {Key.Key7.ToString(), new string[] {SharpHook.Native.KeyCode.Vc7.ToString()}},
        {Key.Key8.ToString(), new string[] {SharpHook.Native.KeyCode.Vc8.ToString()}},
        {Key.Key9.ToString(), new string[] {SharpHook.Native.KeyCode.Vc9.ToString()}},
        {Key.Minus.ToString(), new string[] {SharpHook.Native.KeyCode.VcMinus.ToString()}},
        {Key.Equal.ToString(), new string[] {SharpHook.Native.KeyCode.VcEquals.ToString()}},
        {Key.Backspace.ToString(), new string[] {SharpHook.Native.KeyCode.VcBackspace.ToString()}},

        {Key.Tab.ToString(), new string[] {SharpHook.Native.KeyCode.VcTab.ToString()}},
        {Key.Capslock.ToString(), new string[] {SharpHook.Native.KeyCode.VcCapsLock.ToString()}},

        {Key.A.ToString(), new string[] {SharpHook.Native.KeyCode.VcA.ToString()}},
        {Key.B.ToString(), new string[] {SharpHook.Native.KeyCode.VcB.ToString()}},
        {Key.C.ToString(), new string[] {SharpHook.Native.KeyCode.VcC.ToString()}},
        {Key.D.ToString(), new string[] {SharpHook.Native.KeyCode.VcD.ToString()}},
        {Key.E.ToString(), new string[] {SharpHook.Native.KeyCode.VcE.ToString()}},
        {Key.F.ToString(), new string[] {SharpHook.Native.KeyCode.VcF.ToString()}},
        {Key.G.ToString(), new string[] {SharpHook.Native.KeyCode.VcG.ToString()}},
        {Key.H.ToString(), new string[] {SharpHook.Native.KeyCode.VcH.ToString()}},
        {Key.I.ToString(), new string[] {SharpHook.Native.KeyCode.VcI.ToString()}},
        {Key.J.ToString(), new string[] {SharpHook.Native.KeyCode.VcJ.ToString()}},
        {Key.K.ToString(), new string[] {SharpHook.Native.KeyCode.VcK.ToString()}},
        {Key.L.ToString(), new string[] {SharpHook.Native.KeyCode.VcL.ToString()}},
        {Key.M.ToString(), new string[] {SharpHook.Native.KeyCode.VcM.ToString()}},
        {Key.N.ToString(), new string[] {SharpHook.Native.KeyCode.VcN.ToString()}},
        {Key.O.ToString(), new string[] {SharpHook.Native.KeyCode.VcO.ToString()}},
        {Key.P.ToString(), new string[] {SharpHook.Native.KeyCode.VcP.ToString()}},
        {Key.Q.ToString(), new string[] {SharpHook.Native.KeyCode.VcQ.ToString()}},
        {Key.R.ToString(), new string[] {SharpHook.Native.KeyCode.VcR.ToString()}},
        {Key.S.ToString(), new string[] {SharpHook.Native.KeyCode.VcS.ToString()}},
        {Key.T.ToString(), new string[] {SharpHook.Native.KeyCode.VcT.ToString()}},
        {Key.U.ToString(), new string[] {SharpHook.Native.KeyCode.VcU.ToString()}},
        {Key.V.ToString(), new string[] {SharpHook.Native.KeyCode.VcV.ToString()}},
        {Key.W.ToString(), new string[] {SharpHook.Native.KeyCode.VcW.ToString()}},
        {Key.X.ToString(), new string[] {SharpHook.Native.KeyCode.VcX.ToString()}},
        {Key.Y.ToString(), new string[] {SharpHook.Native.KeyCode.VcY.ToString()}},
        {Key.Z.ToString(), new string[] {SharpHook.Native.KeyCode.VcZ.ToString()}},

        {Key.Bracketleft.ToString(), new string[] {SharpHook.Native.KeyCode.VcOpenBracket.ToString()}},
        {Key.Bracketright.ToString(), new string[] {SharpHook.Native.KeyCode.VcCloseBracket.ToString()}},
        {Key.Backslash.ToString(), new string[] {SharpHook.Native.KeyCode.VcBackslash.ToString()}},
        {Key.Semicolon.ToString(), new string[] {SharpHook.Native.KeyCode.VcSemicolon.ToString()}},
        {Key.Quotedbl.ToString(), new string[] {SharpHook.Native.KeyCode.VcQuote.ToString()}},
        {Key.Enter.ToString(), new string[] {SharpHook.Native.KeyCode.VcEnter.ToString()}},
        {Key.Comma.ToString(), new string[] {SharpHook.Native.KeyCode.VcComma.ToString()}},
        {Key.Period.ToString(), new string[] {SharpHook.Native.KeyCode.VcPeriod.ToString()}},
        {Key.Slash.ToString(), new string[] {SharpHook.Native.KeyCode.VcSlash.ToString()}},
        {Key.Space.ToString(), new string[] {SharpHook.Native.KeyCode.VcSpace.ToString()}},

        {Key.Print.ToString(), new string[] {SharpHook.Native.KeyCode.VcPrintScreen.ToString()}},
        {Key.Insert.ToString(), new string[] {SharpHook.Native.KeyCode.VcInsert.ToString()}},
        {Key.Home.ToString(), new string[] {SharpHook.Native.KeyCode.VcHome.ToString()}},
        {Key.Pageup.ToString(), new string[] {SharpHook.Native.KeyCode.VcPageUp.ToString()}},
        {Key.Delete.ToString(), new string[] {SharpHook.Native.KeyCode.VcDelete.ToString()}},
        {Key.End.ToString(), new string[] {SharpHook.Native.KeyCode.VcEnd.ToString()}},
        {Key.Pagedown.ToString(), new string[] {SharpHook.Native.KeyCode.VcPageDown.ToString()}},

        {Key.Down.ToString(), new string[] {SharpHook.Native.KeyCode.VcDown.ToString()}},
        {Key.Up.ToString(), new string[] {SharpHook.Native.KeyCode.VcUp.ToString()}},
        {Key.Right.ToString(), new string[] {SharpHook.Native.KeyCode.VcRight.ToString()}},
        {Key.Left.ToString(), new string[] {SharpHook.Native.KeyCode.VcLeft.ToString()}},

        {Key.Numlock.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumLock.ToString()}},
        {Key.Kp0.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad0.ToString()}},
        {Key.Kp1.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad1.ToString()}},
        {Key.Kp2.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad2.ToString()}},
        {Key.Kp3.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad3.ToString()}},
        {Key.Kp4.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad4.ToString()}},
        {Key.Kp5.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad5.ToString()}},
        {Key.Kp6.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad6.ToString()}},
        {Key.Kp7.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad7.ToString()}},
        {Key.Kp8.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad8.ToString()}},
        {Key.Kp9.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPad9.ToString()}},
        {Key.KpDivide.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadDivide.ToString()}},
        {Key.KpMultiply.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadMultiply.ToString()}},
        {Key.KpSubtract.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadSubtract.ToString()}},
        {Key.KpAdd.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadAdd.ToString()}},
        {Key.KpPeriod.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadDecimal.ToString()}},
        {Key.KpEnter.ToString(), new string[] {SharpHook.Native.KeyCode.VcNumPadEnter.ToString()}},

        {Key.Shift.ToString(), new string[] {SharpHook.Native.KeyCode.VcLeftShift.ToString(), SharpHook.Native.KeyCode.VcRightShift.ToString()}},
        {Key.Ctrl.ToString(), new string[] {SharpHook.Native.KeyCode.VcLeftControl.ToString(), SharpHook.Native.KeyCode.VcRightControl.ToString()}},
        {Key.Alt.ToString(), new string[] {SharpHook.Native.KeyCode.VcLeftAlt.ToString(), SharpHook.Native.KeyCode.VcRightAlt.ToString()}},
        {Key.Meta.ToString(), new string[] {SharpHook.Native.KeyCode.VcLeftMeta.ToString(), SharpHook.Native.KeyCode.VcRightMeta.ToString()}},

        {"Mouse" + MouseButton.Left.ToString(), new string[] {SharpHook.Native.MouseButton.Button1.ToString()}},
        {"Mouse" + MouseButton.Right.ToString(), new string[] {SharpHook.Native.MouseButton.Button2.ToString()}},
        {"Mouse" + MouseButton.Middle.ToString(), new string[] {SharpHook.Native.MouseButton.Button3.ToString()}},
        {"Mouse" + MouseButton.Xbutton1.ToString(), new string[] {SharpHook.Native.MouseButton.Button4.ToString()}},
        {"Mouse" + MouseButton.Xbutton2.ToString(), new string[] {SharpHook.Native.MouseButton.Button5.ToString()}},

        {"Mouse" + MouseButton.WheelUp.ToString(), new string[] {"WheelUp"}},
        {"Mouse" + MouseButton.WheelDown.ToString(), new string[] {"WheelDown"}},
        {"Mouse" + MouseButton.WheelLeft.ToString(), new string[] {"WheelLeft"}},
        {"Mouse" + MouseButton.WheelRight.ToString(), new string[] {"WheelRight"}},
    };
    
    Dictionary<string, bool> SharpKeyState = new();
    Dictionary<string, Dictionary<string, Dictionary<string, bool>>> ActionDictionary = new();

    static string OverallInputEventName = "Overall";
    #endregion

    #region Setup Methods
    private void InitializeSharpKeyState()
    {
        string[] sharpKeyNames = Enum.GetNames(typeof(SharpHook.Native.KeyCode));
        foreach (string sharpKeyName in sharpKeyNames) SharpKeyState.Add(sharpKeyName, false);

        string[] sharpMouseButtonNames = Enum.GetNames(typeof(SharpHook.Native.MouseButton));
        foreach (string sharpMouseButtonName in sharpMouseButtonNames) SharpKeyState.Add(sharpMouseButtonName, false);

        SharpKeyState.Add("WheelUp", false);
        SharpKeyState.Add("WheelDown", false);
        SharpKeyState.Add("WheelLeft", false);
        SharpKeyState.Add("WheelRight", false);
    }

    private void InitializeActionDictionary()
    {
        foreach (string actionName in InputMap.GetActions())
        {
            ActionDictionary.Add(actionName, new Dictionary<string, Dictionary<string, bool>>());

            foreach (InputEvent inputEvent in InputMap.ActionGetEvents(actionName))
            {
                string inputEventName = GetEventName(inputEvent);
                if (!ActionDictionary[actionName].ContainsKey(inputEventName)) ActionDictionary[actionName].Add(inputEventName, new Dictionary<string, bool>()
                {
                    {"justPressedPrevState",    false},
                    {"justPressedState",        false},
                    {"pressedPrevState",        false},
                    {"pressedState",            false},
                    {"justReleasedPrevState",   false},
                    {"justReleasedState",       false}
                });
            }

            if (ActionDictionary[actionName].ContainsKey(OverallInputEventName)) continue;

            ActionDictionary[actionName].Add(OverallInputEventName, new Dictionary<string, bool>()
            {
                {"justPressedPrevState",    false},
                {"justPressedState",        false},
                {"pressedPrevState",        false},
                {"pressedState",            false},
                {"justReleasedPrevState",   false},
                {"justReleasedState",       false}
            });
        }
    }
    
    private void InitializeSignals()
    {
        Hook.KeyPressed += OnHookKeyPressed;
        Hook.KeyReleased += OnHookKeyReleased;

        Hook.MousePressed += OnHookMouseButtonPressed;
        Hook.MouseReleased += OnHookMouseButtonReleased;

        Hook.MouseWheel += OnHookMouseWheel;
    }
    #endregion

    #region Sharp Hook Signal Handlers
    private void OnHookKeyPressed(object sender, KeyboardHookEventArgs e)
    {
        string[] sharpKeyNames = MapGodotKeyToSharpKey(
            MapSharpKeyToGodotKey(e.RawEvent.Keyboard.KeyCode.ToString())
        );

        UpdateSharpKeyState(sharpKeyNames, true);
    }

    private void OnHookKeyReleased(object sender, KeyboardHookEventArgs e)
    {
        string[] sharpKeyNames = MapGodotKeyToSharpKey(
            MapSharpKeyToGodotKey(e.RawEvent.Keyboard.KeyCode.ToString())
        );

        UpdateSharpKeyState(sharpKeyNames, false);
    }

    private void OnHookMouseButtonPressed(object sender, MouseHookEventArgs e)
    {
        string[] sharpKeyNames = MapGodotKeyToSharpKey(
            MapSharpKeyToGodotKey(e.RawEvent.Mouse.Button.ToString())
        );

        UpdateSharpKeyState(sharpKeyNames, true);
    }

    private void OnHookMouseButtonReleased(object sender, MouseHookEventArgs e)
    {
        string[] sharpKeyNames = MapGodotKeyToSharpKey(
            MapSharpKeyToGodotKey(e.RawEvent.Mouse.Button.ToString())
        );

        UpdateSharpKeyState(sharpKeyNames, false);
    }

    private void OnHookMouseWheel(object sender, MouseWheelHookEventArgs e)
    {
        SharpHook.Native.MouseWheelScrollDirection direction = e.RawEvent.Wheel.Direction;
        int rotation = e.RawEvent.Wheel.Rotation;
        if (direction == SharpHook.Native.MouseWheelScrollDirection.Vertical)
        {
            if (rotation > 0) 
            {
                UpdateSharpKeyState("WheelUp", true);
            }
            else if (rotation < 0) 
            {
                UpdateSharpKeyState("WheelDown", true);
            }
        }
        else if (direction == SharpHook.Native.MouseWheelScrollDirection.Horizontal)
        {
            if (rotation > 0) 
            {
                UpdateSharpKeyState("WheelLeft", true);
            }
            else if (rotation < 0) 
            {
                UpdateSharpKeyState("WheelRight", true);
            }
        }
    }
    #endregion

    #region Helper Functions
    private static string GetEventName(InputEvent inputEvent)
    {
        string eventName = "";
        switch(inputEvent)
        {
            case InputEventMouse inputEventMouse:
                eventName = inputEventMouse.AsText();
                break;
            case InputEventKey inputEventKey:
                eventName = inputEventKey.AsText().Replace("(Physical)", "").Trim();
                break;
        }
        return eventName;
    }
    
    private static string GetEventGodotKey(InputEvent inputEvent)
    {
        string godotKey = "";
        switch (inputEvent)
        {
            case InputEventMouseButton inputEventMouseButton:
                godotKey = "Mouse" + inputEventMouseButton.ButtonIndex.ToString();
                break;
            case InputEventKey inputEventKey:
                godotKey = inputEventKey.PhysicalKeycode.ToString().Replace("(Physical)", "").Trim();
                if (godotKey == "") godotKey = inputEventKey.Keycode.ToString().Trim();
                break;
        }
        return godotKey;
    }
    
    private bool GetEventState(InputEvent inputEvent)
    {
        bool state = false;

        string godotKeyName = GetEventGodotKey(inputEvent);
        string[] sharpKeynames = MapGodotKeyToSharpKey(godotKeyName);
        foreach (string sharpKeyName in sharpKeynames)
        {
            if (SharpKeyState[sharpKeyName]) state = true;
        }

        return state;
    }

    private string[] MapGodotKeyToSharpKey(string godotKey)
    {
        string[] sharpKeyNames = new string[0];
        if (GodotKeyToSharpKey.ContainsKey(godotKey))
        {
            sharpKeyNames = GodotKeyToSharpKey[godotKey];
        }

        return sharpKeyNames;
    }

    private string MapSharpKeyToGodotKey(string sharpKey)
    {
        string godotKey = "";
        foreach (string godotKeyName in GodotKeyToSharpKey.Keys){
            string[] sharpKeyNames = GodotKeyToSharpKey[godotKeyName];
            foreach (string sharpKeyName in sharpKeyNames)
            {
                if (sharpKeyName == sharpKey) {
                    godotKey = godotKeyName;
                }
            }

            if (godotKey != "") break;
        }
        return godotKey;
    }

    private bool IsEventModifierPressed(KeyModifierMask keyModifierMask)
    {
        bool keyModifierState = true;
        if (keyModifierMask > 0)
        {
            string keyModifierString = keyModifierMask.ToString().Replace("Mask", "");
            string[] keyModifierStringArray = keyModifierString.Split(", ");
            foreach (string keyModifier in keyModifierStringArray)
            {
                string[] sharpKeyNames = MapGodotKeyToSharpKey(keyModifier);

                foreach (string sharpKeyName in sharpKeyNames)
                {
                    if (!SharpKeyState[sharpKeyName]) keyModifierState = false;
                }
            }
        }
        return keyModifierState;
    }
    
    private void UpdateActionDictionary(string action)
    {
        if (!ActionDictionary.ContainsKey(action))
        {
            ActionDictionary.Add(action, new Dictionary<string, Dictionary<string, bool>>());
        }

        Dictionary<string, Dictionary<string, bool>> actionDict = ActionDictionary[action];

        foreach (string inputEventName in InputMap.ActionGetEvents(action).Select(x => GetEventName(x)))
        {
            if (!actionDict.ContainsKey(inputEventName)) actionDict.Add(inputEventName, new Dictionary<string, bool>()
            {
                {"justPressedPrevState",    false},
                {"justPressedState",        false},
                {"pressedPrevState",        false},
                {"pressedState",            false},
                {"justReleasedPrevState",   false},
                {"justReleasedState",       false}
            });
        }

        if (actionDict.ContainsKey(OverallInputEventName)) return;

        actionDict.Add(OverallInputEventName, new Dictionary<string, bool>()
        {
            {"justPressedPrevState",    false},
            {"justPressedState",        false},
            {"pressedPrevState",        false},
            {"pressedState",            false},
            {"justReleasedPrevState",   false},
            {"justReleasedState",       false}
        });
    }


    private void UpdateAction(string action, string stateString, string prevStateString)
    {
        UpdateActionDictionary(action);

        bool hasWheel = false;
        int eventCount = 0;
        int eventLength = InputMap.ActionGetEvents(action).Count;
        System.Collections.Generic.List<string> wheelEventNames = new System.Collections.Generic.List<string>();
        foreach (InputEvent inputEvent in InputMap.ActionGetEvents(action))
        {
            string inputEventType = null;
            string inputEventName = null;
            KeyModifierMask? inputEventModifierMask = null;
            switch (inputEvent)
            {
                case InputEventMouse inputEventMouse:
                    inputEventType = "MouseButton";
                    inputEventName = GetEventName(inputEventMouse);
                    inputEventModifierMask = inputEventMouse.GetModifiersMask();
                    break;
                case InputEventKey inputEventKey:
                    inputEventType = "Key";
                    inputEventName = GetEventName(inputEventKey);
                    inputEventModifierMask = inputEventKey.GetModifiersMask();
                    break;
            }

            if (inputEventType == null) continue;

            Dictionary<string, bool> eventStateDictionary = ActionDictionary[action][inputEventName];
            bool eventModifierState = IsEventModifierPressed((KeyModifierMask) inputEventModifierMask);

            eventStateDictionary[prevStateString] = eventStateDictionary[stateString];
            eventStateDictionary[stateString] = GetEventState(inputEvent) && eventModifierState;

            UpdateOverallEventDictionary(action);

            if (GetEventName(inputEvent).Contains("Wheel"))
            {
                hasWheel = true;
                wheelEventNames.Add(GetEventName(inputEvent));
            }
            
            if (eventCount == eventLength - 1 && hasWheel)
            {
                // GD.Print(wheelEventNames);
                foreach (string wheelEventName in wheelEventNames)
                {
                    Dictionary<string, bool> wheelEventStateDictionary = ActionDictionary[action][wheelEventName];
                    if (wheelEventName.Contains("Wheel Up")) {
                        UpdateSharpKeyState("WheelUp", false);
                        wheelEventStateDictionary[stateString] = false;
                    }
                    if (wheelEventName.Contains("Wheel Down")) {
                        UpdateSharpKeyState("WheelDown", false);
                        wheelEventStateDictionary[stateString] = false;
                    }
                    if (wheelEventName.Contains("Wheel Left")) {
                        UpdateSharpKeyState("WheelLeft", false);
                        wheelEventStateDictionary[stateString] = false;
                    }
                    if (wheelEventName.Contains("Wheel Right")) {
                        UpdateSharpKeyState("WheelRight", false);
                        wheelEventStateDictionary[stateString] = false;
                    }
                }
            }
            eventCount++;
        }
    }
    
    private void UpdateSharpKeyState(string sharpKeyName, bool state)
    {
        if (SharpKeyState.ContainsKey(sharpKeyName))
        {
            SharpKeyState[sharpKeyName] = state;
        }
    }

    private void UpdateSharpKeyState(string[] sharpKeyNames, bool state)
    {
        foreach (string sharpKeyName in sharpKeyNames)
        {
            UpdateSharpKeyState(sharpKeyName, state);
        }
    }
    
    private void UpdateOverallEventDictionary(string actionName)
    {
        Dictionary<string, bool> overallEventStateDictionary = ActionDictionary[actionName]["Overall"];

        bool justPressedPrevState = false;
        bool justPressedState = false;
        bool pressedPrevState = false;
        bool pressedState = false;
        bool justReleasedPrevState = false;
        bool justReleasedState = false;

        foreach (InputEvent inputEvent in InputMap.ActionGetEvents(actionName))
        {
            string eventType = null;
            string eventName = null;

            switch (inputEvent)
            {
                case InputEventMouseButton eventMouseButton:
                    eventType = "MouseButton";
                    eventName = GetEventName(eventMouseButton);
                    break;
                case InputEventKey eventKey:
                    eventType = "Key";
                    eventName = GetEventName(eventKey);
                    break;
            }

            if (eventType == null) continue;

            Dictionary<string, bool> eventStateDictionary = ActionDictionary[actionName][eventName];
            if (eventStateDictionary["justPressedPrevState"]) justPressedPrevState = true;
            if (eventStateDictionary["justPressedState"]) justPressedState = true;
            if (eventStateDictionary["pressedPrevState"]) pressedPrevState = true;
            if (eventStateDictionary["pressedState"]) pressedState = true;
            if (eventStateDictionary["justReleasedPrevState"]) justReleasedPrevState = true;
            if (eventStateDictionary["justReleasedState"]) justReleasedState = true;
        }

        overallEventStateDictionary["justPressedPrevState"] = justPressedPrevState;
        overallEventStateDictionary["justPressedState"] = justPressedState;
        overallEventStateDictionary["pressedPrevState"] = pressedPrevState;
        overallEventStateDictionary["pressedState"] = pressedState;
        overallEventStateDictionary["justReleasedPrevState"] = justReleasedPrevState;
        overallEventStateDictionary["justReleasedState"] = justReleasedState;
    }

    #endregion

    Node2D MousePositionNode2D;
    Vector2? screen_min = null;
    Vector2? screen_max = null;
    public override void _Ready()
    {
        for (int i = 0; i < DisplayServer.GetScreenCount(); i++)
        {
            var pos = DisplayServer.ScreenGetPosition(i) - DisplayServer.ScreenGetPosition((int)DisplayServer.ScreenPrimary);
            var size = DisplayServer.ScreenGetSize(i);
            if (screen_min == null)
            {
                screen_min = pos;
            }
            else {
                if (pos.X < ((Vector2)screen_min).X) screen_min = new Vector2(pos.X, ((Vector2)screen_min).Y);
                if (pos.Y < ((Vector2)screen_min).Y) screen_min = new Vector2(((Vector2)screen_min).X, pos.Y);
            }

            if (screen_max == null)
            {
                screen_max = new Vector2(pos.X + size.X, pos.Y + size.Y);
            }
            else
            {
                if (pos.X + size.X > ((Vector2)screen_max).X) screen_max = new Vector2(pos.X + size.X, ((Vector2)screen_max).Y);
                if (pos.Y + size.Y > ((Vector2)screen_max).Y) screen_max = new Vector2(((Vector2)screen_max).X, pos.Y + size.Y);
            }
        }
        MousePositionNode2D = new();
        AddChild(MousePositionNode2D);
        InitializeSharpKeyState();
        InitializeActionDictionary();
        InitializeSignals();

        Hook.RunAsync();
    }

    public override void _Input(InputEvent inputEvent)
    {
        if (inputEvent is InputEventKey inputEventKey)
        {
            if (inputEventKey.IsPressed())
            {
                string[] sharpKeyNames = MapGodotKeyToSharpKey(GetEventGodotKey(inputEventKey));
                UpdateSharpKeyState(sharpKeyNames, true);
            }
            else if (inputEventKey.IsReleased())
            {
                string[] sharpKeyNames = MapGodotKeyToSharpKey(GetEventGodotKey(inputEventKey));
                UpdateSharpKeyState(sharpKeyNames, false);
            }
        }
    }

    #region Godot Input Methods
    public bool IsActionJustPressed(string action)
    {
        string stateString = "justPressedState";
        string prevStateString = "justPressedPrevState";
        UpdateAction(action, stateString, prevStateString);
        Dictionary<string, bool> overallEventStateDictionary = ActionDictionary[action][OverallInputEventName];
        bool prevState = overallEventStateDictionary[prevStateString];
        bool state = overallEventStateDictionary[stateString];
        if (!prevState && state) return true;
        return false;
    }
    
    public bool IsActionPressed(string action)
    {
        string stateString = "pressedState";
        string prevStateString = "pressedPrevState";
        UpdateAction(action, stateString, prevStateString);
        Dictionary<string, bool> overallEventStateDictionary = ActionDictionary[action][OverallInputEventName];
        bool prevState = overallEventStateDictionary[prevStateString];
        bool state = overallEventStateDictionary[stateString];
        if (prevState && state) return true;
        return false;
    }

    public bool IsActionJustReleased(string action)
    {
        string stateString = "justReleasedState";
        string prevStateString = "justReleasedPrevState";
        UpdateAction(action, stateString, prevStateString);
        Dictionary<string, bool> overallEventStateDictionary = ActionDictionary[action][OverallInputEventName];
        bool prevState = overallEventStateDictionary[prevStateString];
        bool state = overallEventStateDictionary[stateString];
        if (prevState && !state) return true;
        return false;
    }
    
    public Vector2 GetVector(StringName negativeX, StringName positiveX, StringName negativeY, StringName positiveY){
        Vector2 inputVector = new Vector2
        {
            X = (IsActionPressed(positiveX) ? 1 : 0) - (IsActionPressed(negativeX) ? 1 : 0),
            Y = (IsActionPressed(positiveY) ? 1 : 0) - (IsActionPressed(negativeY) ? 1 : 0)
        };
        return inputVector;
	}

    public bool IsKeyPressed(Key key)
    {
        string[] sharpKeyNames = MapGodotKeyToSharpKey(key.ToString());
        if (sharpKeyNames.Length == 0) return false;
        foreach (string sharpKeyName in sharpKeyNames)
        {
            if (SharpKeyState[sharpKeyName]) return true;
        }
        return false;
    }

    public bool IsAnythingPressed(){
        foreach (string actionName in InputMap.GetActions()){
            if (IsActionPressed(actionName)) return true;
        }
        return false;
    }


    public Vector2 GetMousePosition() {
        return (Vector2)(MousePositionNode2D.GetGlobalMousePosition() + DisplayServer.WindowGetPosition() + screen_min);
    }
    #endregion
}
