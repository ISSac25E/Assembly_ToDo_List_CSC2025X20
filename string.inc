; string@init@4(* this)
; returns void
extern string@init@4 : proc

; string@length@4(* this)
; returns string length
extern string@length@4 : proc

; string@set@8(*this, *char)
; returns void
extern string@set@8 : proc

; string@insert@12(*this, *char, index)
; returns void
extern string@insert@12 : proc

; string@substr@12(* this, low index, high index)
; returns void
extern string@substr@12 : proc

; string@strcmp@12(*this, *char compare, int start_index)
; returns index of compare hit. -1 if compare failed
extern string@strcmp@12 : proc

; string@toLower@4(*this)
; returns void
extern string@toLower@4 : proc

; string@delete@4(*this)
; returns void
extern string@delete@4 : proc

set_string macro this:req, str:=<"">
    push_str &str&
    
    push esp
    push this
    call string@set@8

    pop_str &str&
endm

insert_string macro this:req, str:req, index:req
    push_str &str&

    push index
    push esp
        add dword ptr [esp], 4
    push this
    call string@insert@12

    pop_str &str&
endm

strcmp macro this:req, str:req, index:req
    push_str &str&

    push index
    push esp 
        add dword ptr [esp], 4
    push this
    call string@strcmp@12
    
    pop_str &str&
endm