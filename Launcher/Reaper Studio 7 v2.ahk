#Requires AutoHotkey v2.0
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
A_MaxHotkeysPerInterval := 5000 ; Increase the hotkey limit (default is 300).
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

	; SendMode('Input')       

	; SetMouseDelay -1

	; SetWinDelay 0	
;------------------------------------------------------------

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; So apparently, this configuration (which are global variables) needs to be declared before any hotkeys or functions, otherwise it won't work.                     =
; --- CONFIGURATION ---                                                                                                                                             =
global SlotCount := 5                                                                                                                                               ; total number of slots
global CurrentSlot := 1                                                                                                                                             ; starting slot number (persistent memory)    
global SlotKeys := ["{NumpadEnd}", "{NumpadDown}", "{NumpadPgDn}", "{NumpadLeft}", "{NumpadIns}"]                                                    ;                                                
global SlotNames := ["Marquee Tool", "Razor Tool", "Marker Tool", "Selection Tool", "None"] 																							; Optional: human-readable names for each slot — customize these to describe what each slot does in your program/game
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

;================================================================;
	
; --- CONFIGURATION ---
                                                                   
sourceFolder := "Splash"                ; Folder with your custom images
targetFile   := "ColorThemes\FL Studio Theme (beta 4)\splash.png" ; Path to the splash image the app uses
programPath  := "reaper.exe"  ; Path to the program executable

; --- PREPARE ---
backupFile := targetFile ".bak"

; Backup the original image if it doesn’t already exist
if !FileExist(backupFile) 
	{
    FileCopy targetFile, backupFile, false  ; false = don’t overwrite existing backup
	}

; --- PICK RANDOM IMAGE ---
images := []
Loop Files, sourceFolder "\*.png"
    images.Push(A_LoopFileFullPath)

if (images.Length = 0) 
	{
    MsgBox "No .png images found in " sourceFolder
    ExitApp
	}

RandomIndex := Random(1, images.Length)
chosenImage := images[RandomIndex]

; --- REPLACE SPLASH IMAGE ---
FileCopy chosenImage, targetFile, true  ; true = overwrite

; --- RUN THE PROGRAM ---

if !WinExist("ahk_exe reaper.exe") && FileExist(programPath)                                                  
	{
		; Sound files, specify your own .wav files here
		on := "SoundPlay/FL's_Start_Up_Sound_(Fruity_Behavior)_(On).wav"
		off := "SoundPlay/FL's_Start_Up_Sound_(Fruity_Behavior)_(Off).wav"

		; Play a sound when starting and stopping Reaper
		Soundplay (on)
		RunWait(programPath)
		Soundplay (off), "Wait"		; Wait until sound finishes playing before continuing
									; If you want to skip the sound when Reaper is closed, remove the "Wait" parameter above and uncomment the next line:
		; --- RESTORE ORIGINAL SPLASH IMAGE ---
		if FileExist(backupFile) 
			{
			FileCopy backupFile, targetFile, true  ; Restore original
			}
		ExitApp		; Exit the script when Reaper closes  
	}

                                                                                               

;================================================================;



; --- FUNCTIONS --- ; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
SelectSlot(direction)                                                           ;
{                                                                               ;
    global CurrentSlot, SlotCount, SlotKeys, SlotNames                          ; 
    if (direction = "down")                                                     ;
        CurrentSlot++                                                           ; Scroll up = +1, Scroll down = -1, but for our case, it's the opposite.
    else if (direction = "up")                                                  ;                       
        CurrentSlot--                                                           ;
                                                                                ;
    if (CurrentSlot > SlotCount)                                                ; Wrap around (so scrolling past edges loops)
        CurrentSlot := 1                                                        ;
    else if (CurrentSlot < 1)                                                   ;                                                       
        CurrentSlot := SlotCount                                                        ; CurrentSlot := SlotCount
    Send SlotKeys[CurrentSlot]                                                  ; Send the key assigned to that slot
    ; ToolTip CurrentSlot " - " SlotNames[CurrentSlot]                            ; Optional: show tooltip on screen for clarity (shows slot number + custom name).
	ToolTip SlotNames[CurrentSlot]                            					;
    SetTimer () => ToolTip(), -800                                              ; clear after 0.8s
}                                                                               ;
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 



;------------------------------------------------------------
!Tab::return
;------------------------------------------------------------
!Esc::
{
	Send ("{Blind}{Tab}") 
}
;------------------------------------------------------------
!+Esc::
{
	Send ("{Blind}{Tab}")
}
;------------------------------------------------------------
#Esc::
{
	Send ("{Blind}{d}")
}

^!Capslock::return


				

;------------------------------------------------------------
	
;================================================================;
#Hotif WinActive("ahk_exe reaper.exe") 
#c::MsgBox "You pressed Win-C inside of Reaper."
;>>>>>>>>>>>>>>>>>>>>>> Hotkeys Below <<<<<<<<<<<<<<<<<<<<<<<<<<<;


	;------------------------------------------------------------
	; Double Middle Click to swap envelope editing type!
	; ~MButton::
	; {
	; ; Double Click Detection
	; static cnt := 0
	; static var := ""
	; if (a_timesincepriorhotkey != -1 && a_timesincepriorhotkey<500)
	; cnt += 1
	; else if (a_timesincepriorhotkey > 50)
	; cnt := 0
	; if (cnt == 1)
	; 	var := "double click" 
	; SetTimer executeprogram, -0
	; return
	
	; executeprogram:
	; if (var == "double click")
	; {
	; 	Send ("{\}") 
	; }
	; }



; var := ""



;------------------------------------------------------------
#MButton::MButton
^#LButton::LButton
#LButton::LButton
	; because it causes it to open window function when they're combined, this stops it so that it won't launch windows.


;------------------------------------------------------------
	~RButton & MButton::
{
	If (GetKeyState("RButton","P") && GetKeyState("MButton","P"))
	{
	KeyWait("MButton")
	Send ("{Home}")
	Soundplay "SoundPlay/FL's Rim Job.wav"
	}
	else
	{
	KeyWait("MButton")
	Send ("{Home}")
	Soundplay "SoundPlay/FL's Rim Job.wav"
	}
}

;------------------------------------------------------------



;-----------------------------------------------------------
~RButton::
{
	;Send("{RButton down}")
	KeyWait ("RButton")
	;Send("{RButton up}")
	Send ("{Esc}")
	Send ("{Delete}")
}
;------------------------------------------------------------

;>>>>>>>> Alternative right click menu by Windows + Right Click <<<<<<<<;
;     >>>>>>>> It sends as Ctrl + Windows + Right Click though <<<<<<<<	;
	#RButton::NumpadDel

	;#Up::return
	;#Down::return
	;#Left::return
	;#Right::return

	#w::
	{
		Send ("{=}")
	}
;------------------------------------------------------------
	#s::
	;SendInput, {down}
	{
		Send ("{-}")
	}

;------------------------------------------------------------
	#a::
	;SendInput, {left}
	{
		Send ("{[}")
	}
;------------------------------------------------------------
	#d::
	;SendInput, {right}
	{
		Send ("{]}")
	}

;------------------------------------------------------------
	+#w::
	{
		Send ("+^{=}")
	}
;------------------------------------------------------------
	+#s::
	{
		Send ("+^{-}")
	}

;------------------------------------------------------------
	+#a::
	{
		Send ("+^{[}")
	}
;------------------------------------------------------------
	+#d::
	{
		Send ("+^{]}")
	}

;------------------------------------------------------------
	#Tab::
	{
		Send ("#{NumpadEnd}")
	}

;------------------------------------------------------------
	!w::
	{
		Send ("!{;}")
	}
;------------------------------------------------------------
	+!w::
	{
		Send ("+!{w}")
	}
;------------------------------------------------------------

;>>>>>>>> Preventing Windows key from being themselves and functions <<<<<<<<;
;------------------------------------------------------------;
	LWin::
	LWin & vkE8::

;------------------------------------------------------------;

	LWin & WheelUp::
	{
		SendInput "{Blind}{WheelUp}"
	}
;------------------------------------------------------------;

	LWin & WheelDown::
	{
		SendInput "{Blind}{WheelDown}"
	}

;------------------------------------------------------------;
	;LWin & MButton::
	;Send, {\}
	;return

;------------------------------------------------------------;


;>>>>>>>> Capslock functions <<<<<<<<;
	;+Capslock::
	;Send, {Blind}{\}
	;return
;------------------------------------------------------------;
	;~NumpadEnter::
	;Send {Blind}
	;return
;------------------------------------------------------------;
	Capslock::
	{
		Send ("{Blind}{vkE8}")
	}
	; this is to prevent Capslock from being toggled on and off

;------------------------------------------------------------;
	!Capslock::
	{
		Send ("{Blind}!{vkE8}")
	}
;------------------------------------------------------------;
	#Capslock::
	{
		Send ("{Blind}#{vkE8}")
	}

;------------------------------------------------------------;
	+Capslock::
	{
		Send ("{Blind}+{vkE8}")
	}

;------------------------------------------------------------
	^Capslock::
	{
		Send ("{Blind}^{vkE8}")
	}

;------------------------------------------------------------;



;>>>>>>>> Media Explorer & Quick Adder hotkeys <<<<<<<<;
;------------------------------------------------------------;
	!Tab::
	+!Tab::
	^!Tab::
	{
		Send "{Blind}{=}"
	}


;>>>>>>>> Toggle through tools by right hold + scroll up or down <<<<<<<<;
;	>>>>>>>> Requires Fruity Behavior <<<<<<<<		;

; = = = = = = = = = = = = = = = = = =
WheelUp::                           ;
{                                   ;
    if GetKeyState("RButton", "P")  ;
    {                               ;
        SelectSlot("up")            ;
    }                               ;
    else                            ;
    {                               ;
         Send("{WheelUp}")          ;
    }                               ;
}                                   ;
; = = = = = = = = = = = = = = = = = =
WheelDown::                         ;
{                                   ;
    if GetKeyState("RButton", "P")  ;
    {                               ;
        SelectSlot("down")          ;
    }                               ;
    else                            ;
		{                               ;
        Send("{WheelDown}")         ; 
    }                               ;
}                                   ;
; = = = = = = = = = = = = = = = = = =





;>>>>>>>> fast fader tool by Shift + Right Drag on media items <<<<<<<<;

;------------------------------------------------------------;
	; ~LShift & RButton::	
	; {
	; 	Loop
	; 	if fz = "break"
	; 	{
	; 	fz := "break"
	; 	}
	; 	else
	; 	{
	; 	Send ("{'}")
	; 	Sleep 25
	; 	}
	; }
	

	; LShift & RButton up::break
	; return

;------------------------------------------------------------;


#HotIf 

#c::MsgBox "You pressed Win-C outside of Reaper."












