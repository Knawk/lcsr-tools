; Lethal Company speedrun macros
; by Knawk
;
; to-do list:
; - TODO: make macro work when starting from main menu
; - TODO: make macro work when starting from pause menu
; - TODO: support resolutions other than 1440p
; - TODO: allow resetting file 2 or 3
; - TODO: allow resetting challenge moons
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

; delay between macro actions (keyboard/mouse), in milliseconds (default: 30)
global ActionDelay := 30

; delay between quitting a lobby and using the main menu, in milliseconds (default: 200)
global MainMenuDelay := 200

; text to copy to clipboard during each reset (default: "scan")
;
; if empty (value ""), the clipboard won't be modified during resets.
;
; common values: "scan", "assurance", "vow"
global ClipboardOnReset := "scan"

;;; (end of settings)



Reset() {
    global ActionDelay
    SetKeyDelay, ActionDelay

    CoordMode, Mouse, Client

    ; quit to main menu
    Send {Escape}{Down down}{Down up}{Down down}{Down up}{Down down}{Down up}{Enter}{Up down}{Up up}{Enter}
    Sleep, MainMenuDelay

    ; dismiss LAN mode warning
    Click, 1240 870
    Sleep, ActionDelay

    ; host lobby (making sure Host is selected, even if mouse hovers another)
    Send {Down down}{Down up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Enter}
    Sleep, ActionDelay

    ; delete file 1
    Click, 2237 609
    Sleep, ActionDelay
    Send {Down down}{Down up}{Up down}{Up up}{Enter}
    Sleep, ActionDelay

    ; confirm host lobby
    Send {Down down}{Down up}{Up down}{Up up}{Enter}

    ; copy 
    global ClipboardOnReset
    if (ClipboardOnReset != "") {
        Clipboard := ClipboardOnReset
    }
}

Hotkey, IfWinActive, Lethal Company ahk_class UnityWndClass
Hotkey, % ResetKeys, Reset
