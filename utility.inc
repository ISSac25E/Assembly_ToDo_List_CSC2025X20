extern util@charCount@4 : proc
extern util@itoa@8 : proc

; https://gchq.github.io/CyberChef/#recipe=Find_/_Replace(%7B'option':'Regex','string':'.(?%3D(.))'%7D,'%5C'$%26%5C',%20',true,false,true,false)Find_/_Replace(%7B'option':'Regex','string':'.$'%7D,'%5C'$%26%5C'',true,false,true,false)&input=SGVsbG8gV29ybGQ
; https://tinyurl.com/266k49m9


load_array_b macro buffer, args:VARARG 
    push eax
    mov eax, buffer
    FOR arg, <args>
        mov byte ptr [eax], arg  ; Move each byte into the buffer at the current offset
        inc eax                ; Increment offset by 1 to move to the next byte position
    endm
    pop eax
endm

push_array_b macro args:VARARG 
    FOR arg, <args>
        dec esp ; allocate one byte
        mov [esp], byte ptr arg
    endm
endm

pop_array_b macro args:VARARG 
    FOR arg, <args>
        inc esp ; de-allocate one byte
    endm
endm