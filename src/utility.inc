; utilities library
; Amir Gorkovchenko
; 11-12-2024

; a collection of useful procedures declarations and macro definitions
; includes a varied pack of print macros for string, byte array, and integers

; util@charCount@4 (* char buffer)
; returns number of characters, null terminator not included
extern util@charCount@4 : proc

; util@itoa@8(int, *buffer)
; returns address location immediately after written
extern util@itoa@8 : proc

; util@parseInt@4(*char)
; returns number of valid digit characters, 0 if failed. edx contains result
extern util@parseInt@4 : proc

; util@listDir@8(linkedList *, char *)
; return void
extern util@listDir@8 : proc

; required external procedures!
    ; writeString@4
    ; util@itoa@8

; https://gchq.github.io/CyberChef/#recipe=Find_/_Replace(%7B'option':'Regex','string':'.(?%3D(.))'%7D,'%5C'$%26%5C',%20',true,false,true,false)Find_/_Replace(%7B'option':'Regex','string':'.$'%7D,'%5C'$%26%5C'',true,false,true,false)&input=SGVsbG8gV29ybGQ
; https://tinyurl.com/266k49m9

; https://www.phatcode.net/res/223/files/html/Chapter_8/CH08-7.html

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; printing macros
; you can print as a string (with limitations) or as a byte array (more tedious but less limits)
; you can also print an integer

; print_array_b
; prints arguments directly to console, adds null-terminator at the end
; ex. print_array_b 'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd', 33, 10
print_array_b macro args:vararg
    push_array_b &args&, 0
    push esp
    call writeString@4
    pop_array_b &args&, 0
endm

; print_str
; prints string argument to console. no line feed
; this can't take certain characters like '!' or quotation marks
; if printing a comma, enclose in brackets or quotes
; ex.
;  print_str Hello World
;  print_str "Hello World"
;  print_str <Hello World>
;  print_str "Hello World!!!" ; WON'T print "!" character
;  print_str Hello World, 23 ; WON'T print ", 23"
;  print_str 'Hello World' ; INVALID!
print_str macro str:req
    push_str &str&
    push esp
    call writeString@4
    pop_str &str&
endm

; println_str
; same exact as print_str, just with line feed
println_str macro str:=<"">
    push_str_ln &str&
    push esp
    call writeString@4
    pop_str_ln &str&
endm

; input a signed integer from -2,147,483,648 to 2,147,483,647
; prints to console, no line feed or spaces
print_int macro num:req
    push eax ; store eax

    sub esp, 12 ; buffer for largest possible negative 32-bit number with null-term 
    
    ; util@itoa@8(int, *buffer)
    ; returns address location immediately after written
    push esp
    push &num&
    call util@itoa@8
    mov byte ptr [eax], 0
    push esp
    call writeString@4
    add esp, 12

    pop eax ; restore eax
endm

;;;;;;;; helper functions ;;;;;;;;
load_array_b macro buffer, args:vararg 
    push eax
    mov eax, buffer
    FOR arg, <args>
        mov byte ptr [eax], arg  ; Move each byte into the buffer at the current offset
        inc eax                ; Increment offset by 1 to move to the next byte position
    endm
    pop eax
endm

push_array_b macro args:vararg 
    arg_size = 0
    FOR arg, <args>
        arg_size = arg_size + 1
    endm
    sub esp, arg_size

    arg_size = 0
    FOR arg, <args>
        mov [esp + arg_size], byte ptr arg
        arg_size = arg_size + 1
    endm
endm

pop_array_b macro args:VARARG 
    arg_size = 0
    FOR arg, <args>
        arg_size = arg_size + 1
    endm
    add esp, arg_size
endm

push_str macro str:req
    dec esp ; allocate 1 byte for null char
    mov byte ptr [esp], 0 

    strSize = 0
    forc c, <str>
        ifdif <c>,<!">
            strSize = strSize + 1
        endif
    endm
    sub esp, strSize 
    
    forc c, <str>
        ifdif <c>,<!">
            mov byte ptr [esp], '&c&'
            inc esp
        endif
    endm

    sub esp, strSize
endm

pop_str macro str
    strSize = 0
    forc c, <str>
        ifdif <c>,<!">
            strSize = strSize + 1
        endif
    endm
    strSize = strSize + 1  ; null-char
    add esp, strSize
endm

push_str_ln macro str:=<"">
    dec esp ; allocate 1 byte for null char
    mov byte ptr [esp], 0 
    dec esp ; allocate 1 byte for line feed
    mov byte ptr [esp], 10

    strSize = 0
    forc c, <str>
        ifdif <c>,<!">
            strSize = strSize + 1
        endif
    endm
    sub esp, strSize 
    
    forc c, <str>
        ifdif <c>,<!">
            mov byte ptr [esp], '&c&'
            inc esp
        endif
    endm

    sub esp, strSize
endm

pop_str_ln macro str:=<"">
    strSize = 0
    forc c, <str>
        ifdif <c>,<!">
            strSize = strSize + 1
        endif
    endm
    strSize = strSize + 2  ; null-char and line-feed
    add esp, strSize
endm