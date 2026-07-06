; coop-control.ahk  —  Sts2SoloCoop  (AutoHotkey v2)
;
; One-key focus switching between the two tiled Slay the Spire 2 windows, so you can jump between
; controlling player 1 and player 2 without reaching for the mouse / Alt-Tab.
;
;   F1  -> focus the LEFT window   (player 1)
;   F2  -> focus the RIGHT window  (player 2)
;   F3  -> toggle to the other window
;   F4  -> re-tile both windows left/right (in case they moved)
;
; Requires AutoHotkey v2 (https://www.autohotkey.com/). Run coop-launch.ps1 first to open + tile the
; two instances, then double-click this .ahk. Set the game to WINDOWED mode so tiling works.

#Requires AutoHotkey v2.0
#SingleInstance Force

GameExe := "ahk_exe SlayTheSpire2.exe"

; Return the game windows sorted left-to-right by X position.
GetGameWindowsSorted() {
    ids := WinGetList(GameExe)
    wins := []
    for id in ids {
        WinGetPos(&x, , , , "ahk_id " id)
        wins.Push({ id: id, x: x })
    }
    ; insertion sort by x (ascending) — [1] = leftmost, [2] = next, ...
    loop wins.Length {
        i := A_Index
        loop wins.Length - i {
            j := A_Index
            if (wins[j].x > wins[j + 1].x) {
                tmp := wins[j], wins[j] := wins[j + 1], wins[j + 1] := tmp
            }
        }
    }
    return wins
}

ActivateSide(n) {
    wins := GetGameWindowsSorted()
    if (wins.Length >= n) {
        WinActivate("ahk_id " wins[n].id)
    } else {
        ToolTip("Only " wins.Length " game window(s) found")
        SetTimer(() => ToolTip(), -1500)
    }
}

ToggleSide() {
    wins := GetGameWindowsSorted()
    if (wins.Length < 2)
        return
    active := WinActive(GameExe)
    if (active = wins[1].id)
        WinActivate("ahk_id " wins[2].id)
    else
        WinActivate("ahk_id " wins[1].id)
}

TileLeftRight() {
    wins := GetGameWindowsSorted()
    if (wins.Length < 1)
        return
    m := MonitorGetWorkArea(MonitorGetPrimary(), &L, &T, &R, &B)
    halfW := (R - L) // 2
    for idx, w in wins {
        if (idx > 2)
            break
        x := L + (idx - 1) * halfW
        WinMove(x, T, halfW, B - T, "ahk_id " w.id)
    }
}

F1:: ActivateSide(1)
F2:: ActivateSide(2)
F3:: ToggleSide()
F4:: TileLeftRight()
