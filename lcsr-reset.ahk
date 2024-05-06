; Lethal Company reset macro
; by Knawk
;
; --- HOW TO USE ---
;
; This macro requires AutoHotkey v2.0+ (https://www.autohotkey.com/).
; Once AutoHotkey is installed, double-click/open this script to start it.
; A green square "H" icon will appear in the system tray / taskbar.
;
; By default, pressing CTRL+R from in-game will:
;  - exit to the main menu
;  - delete Save File 1 and start a new lobby (on File 1)
;  - copy "scan" to the clipboard (for easy bee scanning)
;
; Then any time after loading into the lobby ("SYSTEMS ONLINE" fade-out), pressing CTRL+T will:
;  - move your character to the terminal
;  - access the terminal and route the ship to Assurance
;  - quit the terminal
;
; --- CONFIGURATION ---
;
; To route to a different moon:
;  1. right-click the system tray icon
;  2. select the "Starting Moon" item
;  3. enter the moon name as you would in the terminal (like "march" or "mar" for March)
;
; To select a different save file to reset:
;  1. right-click the system tray icon
;  2. select an option under "Save File"
;
; See the Settings section below to configure:
;  - the reset hotkey
;  - the default save file
;  - text to copy to the clipboard when resetting
;  - macro action delays
;  - ability to reset from the main menu
; (and more)
;
; vim: expandtab:tabstop=4:shiftwidth=4

#Requires AutoHotkey >=2.0-
Persistent



;;; Settings

; NOTE: If you change any settings,
; you'll need to "Reload Script" from the system tray icon for them to take effect.

; key(s) to trigger reset (default: "^r" = CTRL+R)
;
; see modifier keys (CTRL, SHIFT, ALT, etc.) here: https://www.autohotkey.com/docs/v1/Hotkeys.htm#Symbols
; see full list of keys here: https://www.autohotkey.com/docs/v1/KeyList.htm
global ResetKeys := "^r"

; key(s) to trigger start-of-run actions (default: "^t" = CTRL+T)
;
; see modifier keys (CTRL, SHIFT, ALT, etc.) here: https://www.autohotkey.com/docs/v1/Hotkeys.htm#Symbols
; see full list of keys here: https://www.autohotkey.com/docs/v1/KeyList.htm
global StartRunKeys := "^t"

; default moon to route (default: "ass")
;
; common values: "ass", "vow"
global StartRunMoon := "ass"

; default file to play (default: "1")
;
; you can also select a different save file using the system tray menu
;
; allowed values: "1", "2", "3", "challenge"
global SaveFile := "1"

; text to copy to clipboard during each reset (default: "scan")
;
; if empty (value ""), the clipboard won't be modified during resets.
;
; common values: "scan", "assurance", "vow"
global ClipboardOnReset := "scan"

; delay between macro actions (keyboard/mouse), in milliseconds (default: 30)
global ActionDelay := 30

; delay between quitting a lobby and using the main menu, in milliseconds (default: 300)
global MainMenuDelay := 300

; whether to enable resetting on main menu (default: false)
;
; (this will slow down resets a little, so it's disabled by default)
global CanResetFromMainMenu := false

; whether to narrate settings changes using text-to-speech (default: true)
global TTS := true

; script debug mode (default: false)
global DebugMode := false

;;; (end of settings)



; set defaults
SendMode "Event"
CoordMode "Mouse", "Client"
SetDefaultMouseSpeed 0

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

StartRun(*)
{
    SetupKeyDelays()

    Send "{Shift down}{a down}"
    endTime := A_TickCount + 1500
    ; set a bound to make sure there's no possibility of infinitely looping
    Loop 40 {
        Send "e"
        Sleep 33
        if (A_TickCount >= endTime) {
            break
        }
    }

    Send "{Shift up}{a up}"
    Sleep 150
    Send StartRunMoon . "{Enter}"
    Sleep 250
    Send "c{Enter}{Escape}"
}

SetStartRunMoon(ItemName, *)
{
    global StartRunMoon

    ib := InputBox("Enter starting moon:", "Set Starting Moon", "", StartRunMoon)
    if (ib.Result == "OK") {
        StartRunMoon := ib.Value
        A_TrayMenu.Rename(ItemName, "Starting Moon: " . StartRunMoon)
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
A_TrayMenu.Add("Starting Moon: " . StartRunMoon, SetStartRunMoon)

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
Hotkey StartRunKeys, StartRun
if (DebugMode) {
    Hotkey "^a" TestCoords
}

Say("Ready")
