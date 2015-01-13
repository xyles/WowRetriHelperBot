Opt('MustDeclareVars', 1)

; this is required to not try to casts spells 1000 times per second while silenced :(
global $MaxFPS = 4

; Keyboard shortcut to kill this script
HotKeySet("[", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("\", "TogglePause")

global $LuaFramePosX = -1
global $LuaFramePosy = -1
global $RGBStep = 16
global $FirstValidRGB = 1 * $RGBStep
global $SendKeyForMainTarget[20]
global $SendKeyForFocusTarget[20]
global $ExpectedLUAIdleValue = 0x0010FF80

; you can find key values here : https://www.autoitscript.com/autoit3/docs/appendix/SendKeys.htm
$SendKeyForMainTarget[0] = "8"		;Fist of Justice
$SendKeyForMainTarget[1] = "9"		;Rebuke
$SendKeyForMainTarget[3] = "0"		;Arcane Torrent
$SendKeyForMainTarget[4] = "9"		;Counterspell
$SendKeyForMainTarget[5] = "9"		;Wind Shear
$SendKeyForMainTarget[6] = "9"		;Kick
$SendKeyForMainTarget[7] = "9"		;Counter Shot
$SendKeyForMainTarget[8] = "9"		;Pummel
$SendKeyForMainTarget[9] = "9"		;Spear Hand Strike
$SendKeyForMainTarget[10] = "9"		;Mind Freeze
$SendKeyForMainTarget[11] = "9"		;Strangulate
; List is very similar, we only send different key for the spell as you will probably be using a macro like : /cast @focustarget Rebuke
$SendKeyForFocusTarget[0] = "-"		;Fist of Justice
$SendKeyForFocusTarget[1] = "="		;Rebuke
$SendKeyForFocusTarget[3] = "0"		;Arcane Torrent
$SendKeyForFocusTarget[4] = "="		;Counterspell
$SendKeyForFocusTarget[5] = "="		;Wind Shear
$SendKeyForFocusTarget[6] = "="		;Kick
$SendKeyForFocusTarget[7] = "="		;Counter Shot
$SendKeyForFocusTarget[8] = "="		;Pummel
$SendKeyForFocusTarget[9] = "="		;Spear Hand Strike
$SendKeyForFocusTarget[10] = "="	;Mind Freeze
$SendKeyForFocusTarget[11] = "="	;Strangulate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Anything below should be working without any changes. If not.....it's bad
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <Misc.au3>
#include <Date.au3>

global $ScriptIsRunning = 1
global $ScriptIsPaused = 0

Func Terminate()
    $ScriptIsRunning = 0
EndFunc

Func TogglePause()
    $ScriptIsPaused = 1 - $ScriptIsPaused
EndFunc

; wait until you alt+tab to wow window
WinWaitActive( "World of Warcraft" )

; Debugging. Can delete this
if( IsDeclared( "MB_SYSTEMMODAL" ) <> 1 ) then 
	global $MB_SYSTEMMODAL = 4096
endif

; probably did not set manually a value
if( $LuaFramePosX == -1 ) then
	TryToGuessLocation()
endif

; Debugging. Can delete this
if( PixelGetColor( $LuaFramePosX, $LuaFramePosY ) <> $ExpectedLUAIdleValue ) then
	MsgBox( $MB_SYSTEMMODAL, "", "KickBot Lua frame has an unexpected value. Manually set $LuaFramePosX and $LuaFramePosY" )
endif

global $FrameHandleDuration = 1000 / $MaxFPS

;MsgBox( $MB_SYSTEMMODAL, "", " but1 " & $KeyToAllowScriptToTakeActionsHex & " but 2 " & $KeyToAllowScriptToTakeActionsHex2 )

local $PrevValue = 0
;loop until the end of days
local $LastActionCheckStamp = _Date_Time_GetTickCount( )
; monitor that part of the screen and check if something changed. If it did, than we take actions 
while( $ScriptIsRunning == 1 )
	local $TickNow = _Date_Time_GetTickCount( )
	
	; get the color of our LUA frame
	local $LuaColor = PixelGetColor( $LuaFramePosX, $LuaFramePosY )
	
	; do not spam same keys
	if( $PrevValue <> $LuaColor ) then 
		;MsgBox( $MB_SYSTEMMODAL, "", "change detected " & $ColorB )
		local $ColorB = Int( $LuaColor / 65535 )
		local $ColorR = Mod( $LuaColor, 256 )
		local $ColorIndex = Int( ( $ColorB - $FirstValidRGB ) / $RGBStep )
		local $TargetIndex = Int( ( $ColorB - $FirstValidRGB ) / $RGBStep )
		
		; Debugging. Can delete this
		if( WinActive( "World of Warcraft" ) ) then 
			Send( "{ENTER}" & " change detected " & $ColorB & " with index " & $ColorIndex & " {ENTER}" )	
		endif
		
		EventImageFound( $ColorIndex )
		$PrevValue = $LuaColor
	endif
	
	;this is required to not overspam unusable actions
	local $TickAtEnd = _Date_Time_GetTickCount( )
	local $DeltaTime = $TickAtEnd - $TickNow
	if( $DeltaTime < $FrameHandleDuration ) then
		Sleep( $FrameHandleDuration - $DeltaTime )
	endif
wend

func EventImageFound( $SpellNameIndex, $TargetIndex )
;	MsgBox( $MB_SYSTEMMODAL, "", "found img " & $SendKeyForMainTarget[ $SpellNameIndex ] & " at index " & $SpellNameIndex )
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	if( $TargetIndex == 0 &&  $SendKeyForMainTarget[ $SpellNameIndex ] ) then 
		Send( $SendKeyForMainTarget[ $SpellNameIndex ] )
	elseif( $SendKeyForFocusTarget[ $SpellNameIndex ] ) then
		Send( $SendKeyForFocusTarget[ $SpellNameIndex ] )
	endif
endfunc

Func TryToGuessLocation()
	MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame is not define. Trying to search for it" )
	Local $set = PixelSearch( 0, 0, @DesktopWidth, @DesktopHeight, $ExpectedLUAIdleValue, 0 )
	If Not @error Then
		$LuaFramePosX = $set[0] + 8
		$LuaFramePosY = $set[1] + 8
		MouseMove( $LuaFramePosX, $LuaFramePosY )
		MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame found at : " & $LuaFramePosX & " " & $LuaFramePosY )
	endif
endfunc
