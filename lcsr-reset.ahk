; Lethal Company speedrun macros
; by Knawk
; 
; vim: expandtab:tabstop=4:shiftwidth=4

#Persistent
#NoEnv

;;; Settings

global KeyDelay := 40

global MainMenuDelay := 200

;;; (end of settings)

Reset() {
    global KeyDelay
    SetKeyDelay, KeyDelay

    CoordMode, Mouse, Client

    ; quit to main menu
    Send {Escape}{Down down}{Down up}{Down down}{Down up}{Down down}{Down up}{Enter}{Up down}{Up up}{Enter}
    Sleep, MainMenuDelay

    ; dismiss LAN mode warning
    Click, 1240 870
    Sleep, KeyDelay

    ; host lobby (making sure Host is selected, even if mouse hovers another)
    Send {Down down}{Down up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Enter}
    Sleep, KeyDelay

    ; delete file 1
    Click, 2237 609
    Sleep, KeyDelay
    Send {Down down}{Down up}{Up down}{Up up}{Enter}
    Sleep, KeyDelay

    ; confirm host lobby
    Send {Down down}{Down up}{Up down}{Up up}{Enter}
}

#If WinActive("Lethal Company ahk_class UnityWndClass")
{

+NumpadEnter:: ; Reset
    Reset()
return

F6:: ; Reset
    Reset()
return

}

