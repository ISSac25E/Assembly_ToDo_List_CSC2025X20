; string@init@4(* this)
; returns void
extern string@init@4 : proc

; string@length@4(* this)
; returns string length
extern string@length@4 : proc

; string@set@8(*this, *char)
; returns void
extern string@set@8 : proc

; string@util@alloc@4(alloc_size)
; returns allocated address. null if failed
extern string@util@alloc@4 : proc

; string@util@free@4(address)
; returns bool
extern string@util@free@4 : proc