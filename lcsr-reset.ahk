; Lethal Company reset macro
; by Knawk
;
; How to reset:
;  1. start from either the main menu or in-game (but not the pause menu)
;  2. press CTRL+R (configurable in the settings below)
;
; How to select the save file to reset:
;  1. right-click the green square "H" icon in the system tray
;  2. choose an option under "Save File"
;
; vim: expandtab:tabstop=4:shiftwidth=4

#Persistent
#NoEnv



;;; Settings

; key(s) to trigger reset (default: "^r" = CTRL+r)
;
; see modifier keys (CTRL, SHIFT, ALT, etc.) here: https://www.autohotkey.com/docs/v1/Hotkeys.htm#Symbols
; see full list of keys here: https://www.autohotkey.com/docs/v1/KeyList.htm
global ResetKeys := "^r"

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

; delay between quitting a lobby and using the main menu, in milliseconds (default: 350)
global MainMenuDelay := 350

; whether to narrate settings changes using text-to-speech (default: true)
global TTS := true

; script debug mode (default: false)
global DebugMode := false

;;; (end of settings)



Say(Message)
{
    global TTS
    if (TTS) {
        ComObjCreate("SAPI.SpVoice").Speak(Message)
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

    coords := {fileY: {}}

    coords.exitCreditsX := centerX - Floor(0.0054 * centerAreaW)
    coords.exitCreditsY := centerY + Floor(0.4550 * centerAreaH)

    coords.dismissLanWarningX := centerX - Floor(0.0175 * centerAreaW)
    coords.dismissLanWarningY := centerY + Floor(0.1158 * centerAreaH)

    coords.fileX := centerX + Floor(0.28 * centerAreaW)
    fileYInterval := Floor(centerAreaH * 0.0883)
    coords.fileY["file1"] := centerY - fileYInterval
    coords.fileY["file2"] := centerY
    coords.fileY["file3"] := centerY + fileYInterval
    coords.fileY["challenge"] := centerY + fileYInterval + Floor(0.1 * centerAreaH)

    coords.playChallengeAgainX := centerX + Floor(0.0733 * centerAreaW)
    coords.playChallengeAgainY := centerY + Floor(0.3700 * centerAreaH)

    coords.confirmHostX := centerX - Floor(0.0054 * centerAreaW)
    coords.confirmHostY := centerY + Floor(0.1008 * centerAreaH)

    return coords
}

; from https://www.autohotkey.com/boards/viewtopic.php?p=197355#p197355
WinGetClientPos(ByRef X := "", ByRef Y := "", ByRef Width := "", ByRef Height := "", WinTitle := "", WinText := "", ExcludeTitle := "", ExcludeText := "")
{
    local hWnd, RECT
    hWnd := WinExist(WinTitle, WinText, ExcludeTitle, ExcludeText)
    VarSetCapacity(RECT, 16, 0)
    DllCall("user32\GetClientRect", Ptr, hWnd, Ptr, &RECT)
    DllCall("user32\ClientToScreen", Ptr, hWnd, Ptr, &RECT)
    X := NumGet(&RECT, 0, "Int")
    Y := NumGet(&RECT, 4, "Int")
    Width := NumGet(&RECT, 8, "Int")
    Height := NumGet(&RECT, 12, "Int")
}

; just for testing button coordinates
TestCoords()
{
    TestDelay := 200

    WinGetClientPos("", "", winW, winH, "A", "", "", "")
    coords := GetButtonCoords(winW, winH)

    CoordMode, Mouse, Client

    MouseMove, % coords.exitCreditsX, % coords.exitCreditsY
    Sleep, % TestDelay
    MouseMove, % coords.dismissLanWarningX, % coords.dismissLanWarningY
    Sleep, % TestDelay
    MouseMove, % coords.fileX, % coords.fileY["file1"]
    Sleep, % TestDelay
    MouseMove, % coords.fileX, % coords.fileY["file2"]
    Sleep, % TestDelay
    MouseMove, % coords.fileX, % coords.fileY["file3"]
    Sleep, % TestDelay
    MouseMove, % coords.fileX, % coords.fileY["challenge"]
    Sleep, % TestDelay
    MouseMove, % coords.playChallengeAgainX, % coords.playChallengeAgainY
    Sleep, % TestDelay
    MouseMove, % coords.confirmHostX, % coords.confirmHostY
}

; left click at the given client coords
LeftClick(X, Y)
{
    CoordMode, Mouse, Client
    SetDefaultMouseSpeed, 0

    ; specify Left to avoid coords being misinterpreted as another option type
    Click, % Format("{:i} {:i} Left", X, Y)
}

Reset()
{
    WinGetClientPos("", "", winW, winH, "A", "", "", "")
    coords := GetButtonCoords(winW, winH)

    global ActionDelay
    ; needs nonzero delay for some reason
    pressDuration := Max(5, Floor(ActionDelay / 2) + 1)
    SetKeyDelay, ActionDelay, % pressDuration

    ; pause and quit to main menu
    ; (using keys since pause menu positioning is weird)
    Send {Escape}{Down 3}{Enter}{Up}{Enter}
    Sleep, MainMenuDelay

    ; exit credits and move focus to Host button
    ; (in case Reset started on main menu, and opened credits above)
    LeftClick(coords.exitCreditsX, coords.exitCreditsY)
    Send {Up 3}
    Sleep, ActionDelay

    ; dismiss LAN mode warning
    LeftClick(coords.dismissLanWarningX, coords.dismissLanWarningY)
    Sleep, ActionDelay

    ; host lobby
    ; (using keys since main menu positioning is weird)
    Send {Enter}
    Sleep, ActionDelay

    global SaveFile
    if (SaveFile == "challenge") {
        ; select challenge file and click play again
        LeftClick(coords.fileX, coords.fileY["challenge"])
        Sleep, ActionDelay
        LeftClick(coords.playChallengeAgainX, coords.playChallengeAgainY)
        Sleep, ActionDelay
    } else {
        ; delete and select chosen save file
        LeftClick(coords.fileX, coords.fileY["file" . SaveFile])
        Sleep, ActionDelay
        Send {Right}{Enter}{Down}{Up}{Enter}
        Sleep, ActionDelay
        LeftClick(coords.fileX, coords.fileY["file" . SaveFile])
        Sleep, ActionDelay
    }

    ; confirm host lobby
    ; (can't use keyboard after selecting challenge, so just always use mouse)
    LeftClick(coords.confirmHostX, coords.confirmHostY)

    ; copy to clipboard
    global ClipboardOnReset
    if (ClipboardOnReset != "") {
        Clipboard := ClipboardOnReset
    }
}

SetSaveFile(ItemName, ItemPos, MenuName)
{
    global SaveFile
    SaveFile := Format("{:L}", ItemName)

    Menu, Tray, Uncheck, 1
    Menu, Tray, Uncheck, 2
    Menu, Tray, Uncheck, 3
    Menu, Tray, Uncheck, Challenge
    Menu, Tray, Check, % ItemName

    if (SaveFile == "challenge") {
        Say("Challenge file")
    } else {
        Say("File " . SaveFile)
    }
}

Menu, Tray, Add
Menu, Tray, Add, Save File, SetSaveFile
Menu, Tray, Add, 1, SetSaveFile, +Radio
Menu, Tray, Add, 2, SetSaveFile, +Radio
Menu, Tray, Add, 3, SetSaveFile, +Radio
Menu, Tray, Add, Challenge, SetSaveFile, +Radio
Menu, Tray, Disable, Save File
Menu, Tray, Check, % SaveFile

Hotkey, IfWinActive, Lethal Company ahk_class UnityWndClass
Hotkey, % ResetKeys, Reset
if (DebugMode) {
    Hotkey, ^a, TestCoords
}

Say("Ready")
