; string@init@4(* this)
; returns void
extern string@init@4 : proc

; string@length@4(* this)
; returns string length
extern string@length@4 : proc

; string@set@8(*this, *char)
; returns void
extern string@set@8 : proc

set_string macro this:req, str:=<"">
    push_str &str&
    push esp
    push this
    call string@set@8

    pop_str &str&
endm