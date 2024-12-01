; requirements!
; - utility.inc

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

insert_string macro this:req, str:req, index:=<-1>
    push_str &str&

    push index
    push esp
        add dword ptr [esp], 4
    push this
    call string@insert@12

    pop_str &str&
endm

strcmp macro this:req, str:req, index:=<0>
    push_str &str&

    push index
    push esp 
        add dword ptr [esp], 4
    push this
    call string@strcmp@12
    
    pop_str &str&
endm


;;;;;;;; collection of print functions modded to work with the string class instead
string@print_array_b macro args:vararg
    push_array_b &args&, 0
    push -1
    push esp
        add dword ptr [esp], 4
    push offset output_str
    call string@insert@12
    pop_array_b &args&, 0
endm

string@print_str macro str:req
    insert_string offset output_str, str, -1 ; insert at the end
endm

string@println_str macro str:=<"">
    push_str_ln &str&

    push -1
    push esp
        add dword ptr [esp], 4
    push offset output_str
    call string@insert@12

    pop_str_ln &str&
endm

string@print_int macro num:req
    push eax ; store eax

    sub esp, 12 ; buffer for largest possible negative 32-bit number with null-term

    ; util@itoa@8(int, *buffer)
    ; returns address location immediately after written
    push esp
    push &num&
    call util@itoa@8
    mov byte ptr [eax], 0 ; terminate the *char

    push -1
    push esp
        add dword ptr [esp], 4
    push offset output_str
    call string@insert@12

    add esp, 12 ; deallocate

    pop eax ; restore eax
endm

string@writeString@4 macro
    pop eax
    push -1
    push eax
    push offset output_str
    call string@insert@12
endm