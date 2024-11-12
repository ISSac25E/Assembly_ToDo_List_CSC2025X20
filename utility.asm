; utility
; Amir Gorkovchenko
; 09 Nov 2024

; collection of useful utility functions

; using __stdcall: https://learn.microsoft.com/en-us/cpp/cpp/stdcall?view=msvc-170
; name mangling: https://en.wikiversity.org/wiki/Visual_C%2B%2B_name_mangling

; reg reference:
;     eax - caller saved register - usually used for communication between caller and callee.
;     ebx - callee saved register
;     ecx - caller saved register - Counter register 
;     edx - caller Saved register - data, I use it for saving and restoring the return address
;     esi - callee Saved register - Source Index
;     edi - callee Saved register - Destination Index
;     esp - callee Saved register - stack pointer
;     ebp - callee Saved register - base pointer.386P

.386P
.model flat

.data
.code

; count number of chars in ansi string with null termination
; util@charCount@4 (* char buffer)
; returns number of characters, null terminator not included
util@charCount@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov eax, 0  ; counter value
    mov ecx, [ebp + 8]

_char_count_loop_start:
    cmp dword ptr [ecx + eax], 0
    je _exit

    inc eax
    jmp _char_count_loop_start

_exit:
    pop ebp
    ret 4 
util@charCount@4 endp

; convert signed integer into character array. Make sure array has enough space
; optimized to minimize stack footprint, recursive function
; util@itoa@8(int, *buffer)
; returns address location immediately after written
util@itoa@8 proc near

    ; clean up stack for efficiency:
    pop edx ; return address
    pop eax ; integer
    pop ecx ; buffer address
    push edx ; return address

    cmp eax, 0
    jge _positive_num
    neg eax ; change to positive value
    mov byte ptr [ecx], '-'

    inc ecx ; set buffer address to next location

_positive_num:
    ; dividend already loaded into eax
    mov edx, 0

    ; divide by 10
    push ecx
    mov ecx, 10
    div ecx
    pop ecx

    cmp eax, 0  
    je _baseCase ; nothing left to divide
    
    push edx ; push remainder, this gets put on buffer. but a different position
    push ecx  ; don't modify address, this is not our address
    push eax ; push quotient for further processing
    call util@itoa@8
    ; eax now contains correct position
    pop edx ; restore

    jmp _write_buffer

_baseCase:
    mov eax, ecx ; eax contains buffer address now

_write_buffer:
    add edx, '0'
    mov byte ptr [eax], dl ; move character into buffer (last position)
    inc eax ; prepare for next recursion or parent return

_exit:
    ret ; no params to pop
util@itoa@8 endp
end