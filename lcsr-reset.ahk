; Lethal Company reset macro
; by Knawk
;
; --- HOW TO USE ---
;
; This macro requires AutoHotkey v2.0+ (https://www.autohotkey.com/).
; Once AutoHotkey is installed, double-click/open this script to start it.
; A green square "H" icon will appear in the system tray / taskbar.
;
; By default, pressing CTRL+R from in-game will reset by:
;   - exiting to the main menu
;   - deleting Save File 1 and starting a new lobby (on File 1)
;   - copying "scan" to the clipboard (for easy bee scanning)
;
; Then after loading into the lobby ("SYSTEMS ONLINE" fade-out), pressing ALT+R will set up the run by:
;   - accessing the terminal and routing the ship to Assurance
;   - facing towards the lever
; (If this doesn't work, you may need to change the KEYBOARD/MOUSE SETTINGS below.)
;
; --- CONFIGURATION ---
;
; To route to a different moon:
;   1. right-click the system tray icon
;   2. select the "Starting Moon" item
;   3. enter the moon name as you would in the terminal (like "march" or "mar" for March)
;
; To select a different save file to reset:
;   1. right-click the system tray icon
;   2. select an option under "Save File"
;
; See the SETTINGS sections below to configure:
;   - the reset and setup-run keybinds
;   - the default save file
;   - text to copy to the clipboard when resetting
;   - macro action delays
;   - ability to reset from the main menu
;   - (and more)
; NOTE: After changing settings, select "Reload Script" from the system tray icon to reload them.
;
; vim: expandtab:tabstop=4:shiftwidth=4

#Requires AutoHotkey >=2.0-
Persistent



; --- KEYBOARD/MOUSE SETTINGS ---
;
; NOTE: These settings use AutoHotkey's key names, like "a" for A, "+" for Shift, and "{Space}" for Space.
; The modifier keys (CTRL, SHIFT, ALT) are listed here: https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols
; Letters/numbers and other keys are listed here: https://www.autohotkey.com/docs/v2/KeyList.htm

; key bound to "Interact" in Lethal Company (default: "e")
global GameInteractKey := "e"

; key bound to "Walk forward" in Lethal Company (default: "w")
global GameForwardKey := "w"

; mouse/look sensitivity in Lethal Company (default: 1)
;   - on the slider, the left side is 1, the middle gray bar is 10, and the right side is 20
global GameLookSensitivity := 1

; key(s) to trigger reset (default: "^r" = CTRL+R)
global ResetKeys := "^r"

; key(s) to trigger setup run (default: "!r" = ALT+R)
global SetupRunKeys := "!r"



; --- MACRO SETTINGS ---

; default moon to route (default: "ass")
;   - common values: "ass", "vow"
global StartingMoon := "ass"

; default file to play (default: "1")
;   - you can also select a different save file using the system tray menu
;   - allowed values: "1", "2", "3", "challenge"
global SaveFile := "1"

; text to copy to clipboard during each reset (default: "scan")
;   - if empty (value ""), the clipboard won't be modified during resets
;   - common values: "scan", "assurance", "vow"
global ClipboardOnReset := "scan"

; delay between macro actions (keyboard/mouse), in milliseconds (default: 40)
;   - if inputs are being missed, you may need to increase this
global ActionDelay := 40

; delay between quitting a lobby and using the main menu, in milliseconds (default: 300)
;   - if main menu inputs are being missed, you may need to increase this
global MainMenuDelay := 300

; whether to enable resetting on main menu (default: false)
;  - this will slow down resets a little, so it's disabled by default
global CanResetFromMainMenu := false

; whether to narrate settings changes using text-to-speech (default: true)
global TTS := true

; script debug mode (default: false)
global DebugMode := false



; --- END OF SETTINGS ---



; set defaults
SendMode "Event"
CoordMode "Mouse", "Client"
SetDefaultMouseSpeed 0

; prevent ALT/WIN hotkeys from also causing CTRL events,
; which is crouch by default (and can't be configured on some versions like v40)
A_MenuMaskKey := "vkFF"

Say(Message)
{
    global TTS
    if (TTS) {
        ComObject("SAPI.SpVoice").Speak(Message)
    }
}

; returns button coordinates for:
; - exitCreditsX, exitCreditsY
; - dismissLanWarningX, dismissLanWarningY
; - hostX, hostY
; - fileX, fileY with keys "file1", "file2", "file3", "challenge"
; - playChallengeAgainX, playChallengeAgainY
; - confirmHostX, confirmHostY
GetButtonCoords(WinW, WinH)
{
    centerX := Floor(WinW / 2)
    centerY := Floor(WinH / 2)

    ; compute dimensions of 2x1 "center area" relative to which many UI elements are positioned
    centerAreaW := WinW
    centerAreaH := WinH
    if (WinW > WinH * 2) {
        ; height-constrained
        centerAreaW := WinH * 2
    } else {
        ; width-constrained
        centerAreaH := WinW / 2
    }

    coords := Map()

    coords["exitCreditsX"] := centerX - Floor(0.0054 * centerAreaW)
    coords["exitCreditsY"] := centerY + Floor(0.4550 * centerAreaH)

    coords["dismissLanWarningX"] := centerX - Floor(0.0175 * centerAreaW)
    coords["dismissLanWarningY"] := centerY + Floor(0.1158 * centerAreaH)

    coords["fileX"] := centerX + Floor(0.28 * centerAreaW)
    fileYInterval := Floor(centerAreaH * 0.0883)
    coords["fileY"] := Map()
    coords["fileY"]["file1"] := centerY - fileYInterval
    coords["fileY"]["file2"] := centerY
    coords["fileY"]["file3"] := centerY + fileYInterval
    coords["fileY"]["challenge"] := centerY + fileYInterval + Floor(0.1 * centerAreaH)

    coords["playChallengeAgainX"] := centerX + Floor(0.0733 * centerAreaW)
    coords["playChallengeAgainY"] := centerY + Floor(0.3700 * centerAreaH)

    coords["confirmHostX"] := centerX - Floor(0.0054 * centerAreaW)
    coords["confirmHostY"] := centerY + Floor(0.1008 * centerAreaH)

    return coords
}

; just for testing button coordinates
TestCoords()
{
    TestDelay := 200

    WinGetClientPos(, , &winW, &winH, "A", , ,)
    coords := GetButtonCoords(winW, winH)

    MouseMove coords["exitCreditsX"], coords["exitCreditsY"]
    Sleep TestDelay
    MouseMove coords["dismissLanWarningX"], coords["dismissLanWarningY"]
    Sleep TestDelay
    MouseMove coords["fileX"], coords["fileY"]["file1"]
    Sleep TestDelay
    MouseMove coords["fileX"], coords["fileY"]["file2"]
    Sleep TestDelay
    MouseMove coords["fileX"], coords["fileY"]["file3"]
    Sleep TestDelay
    MouseMove coords["fileX"], coords["fileY"]["challenge"]
    Sleep TestDelay
    MouseMove coords["playChallengeAgainX"], coords["playChallengeAgainY"]
    Sleep TestDelay
    MouseMove coords["confirmHostX"], coords["confirmHostY"]
}

SetupKeyDelays()
{
    global ActionDelay
    ; needs nonzero delay for some reason
    pressDuration := Max(5, Floor(ActionDelay / 2) + 1)
    SetKeyDelay ActionDelay, pressDuration
}

; left click at the given client coords
LeftClick(X, Y)
{
    ; specify Left to avoid coords being misinterpreted as another option type
    Click Format("{:i} {:i} Left", X, Y)
}

; turn the camera by Yaw degrees right and Pitch degrees down
CameraTurnRelative(Yaw, Pitch)
{
    prevSendMode := A_SendMode

    SendMode "Play"
    sens := Float(GameLookSensitivity)
    x := Round(125.0 * Float(Yaw) / sens)
    y := Round(125.0 * Float(Pitch) / sens)
    DllCall "mouse_event", "UInt", 0x01, "UInt", x, "UInt", y

    SendMode prevSendMode
}

Reset(*)
{
    WinGetClientPos(, , &winW, &winH, "A", , ,)
    coords := GetButtonCoords(winW, winH)

    SetupKeyDelays()

    ; pause and quit to main menu
    ; (using keys since pause menu positioning is weird)
    Send "{Escape}"
    Sleep ActionDelay
    Send "{Down 3}{Enter}{Up}{Enter}"
    Sleep MainMenuDelay

    global CanResetFromMainMenu
    if (CanResetFromMainMenu) {
        ; exit credits and move focus to Host button
        ; (in case Reset started on main menu, and opened credits above)
        LeftClick(coords["exitCreditsX"], coords["exitCreditsY"])
        Send "{Up 3}"
        Sleep ActionDelay
    }

    ; dismiss LAN mode warning
    LeftClick(coords["dismissLanWarningX"], coords["dismissLanWarningY"])
    Sleep ActionDelay

    ; host lobby
    ; (using keys since main menu positioning is weird)
    Send "{Enter}"
    Sleep ActionDelay

    global SaveFile
    if (SaveFile == "challenge") {
        ; select challenge file and click play again
        LeftClick(coords["fileX"], coords["fileY"]["challenge"])
        Sleep ActionDelay
        LeftClick(coords["playChallengeAgainX"], coords["playChallengeAgainY"])
        Sleep ActionDelay
    } else {
        ; delete and select chosen save file
        LeftClick(coords["fileX"], coords["fileY"]["file" . SaveFile])
        Sleep ActionDelay
        Send "{Right}{Enter}{Down}{Up}{Enter}"
        Sleep ActionDelay
        LeftClick(coords["fileX"], coords["fileY"]["file" . SaveFile])
        Sleep ActionDelay
    }

    ; confirm host lobby
    ; (can't use keyboard after selecting challenge, so just always use mouse)
    LeftClick(coords["confirmHostX"], coords["confirmHostY"])

    ; copy to clipboard
    global ClipboardOnReset
    if (ClipboardOnReset !== "") {
        A_Clipboard := ClipboardOnReset
    }
}

SetupRun(*)
{
    SetupKeyDelays()

    ; turn torwards terminal
    CameraTurnRelative(-56.0, 0.0)
    Sleep ActionDelay

    ; walk to and access terminal
    Send "{w down}"
    endTime := A_TickCount + 500
    ; set a bound to make sure there's no possibility of infinitely looping
    Loop 15 {
        Send "e"
        Sleep 33
        if (A_TickCount >= endTime) {
            break
        }
    }
    Send "{w up}"

    ; enter terminal commands and quit terminal
    Sleep 650
    Send StartingMoon . "{Enter}"
    Sleep 250
    Send "c{Enter}{Escape}"
    Sleep 400

    ; turns towards lever
    CameraTurnRelative(-100.0, 19.0)
}

SetStartingMoon(ItemName, *)
{
    global StartingMoon

    ib := InputBox("Enter starting moon:", "Set Starting Moon", "", StartingMoon)
    if (ib.Result == "OK") {
        StartingMoon := ib.Value
        A_TrayMenu.Rename(ItemName, "Starting Moon: " . StartingMoon)
        Say("Moon changed")
    }
}

SetSaveFile(ItemName, *)
{
    global SaveFile
    SaveFile := Format("{:L}", ItemName)

    A_TrayMenu.Uncheck("1")
    A_TrayMenu.Uncheck("2")
    A_TrayMenu.Uncheck("3")
    A_TrayMenu.Uncheck("Challenge")
    A_TrayMenu.Check(ItemName)

    if (SaveFile == "challenge") {
        Say("Challenge file")
    } else {
        Say("File " . SaveFile)
    }
}

A_TrayMenu.Add()
A_TrayMenu.Add("Starting Moon: " . StartingMoon, SetStartingMoon)

A_TrayMenu.Add()
A_TrayMenu.Add("Save File", SetSaveFile)
A_TrayMenu.Add("1", SetSaveFile, "+Radio")
A_TrayMenu.Add("2", SetSaveFile, "+Radio")
A_TrayMenu.Add("3", SetSaveFile, "+Radio")
A_TrayMenu.Add("Challenge", SetSaveFile, "+Radio")
A_TrayMenu.Disable("Save File")
A_TrayMenu.Check(SaveFile)

HotIfWinActive "Lethal Company ahk_class UnityWndClass"
Hotkey ResetKeys, Reset
Hotkey SetupRunKeys, SetupRun
if (DebugMode) {
    Hotkey "^a" TestCoords
}

Say("Ready")
