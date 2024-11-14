; linkedList excremental test
; Amir Gorkovchenko
; 11-10-2024

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

extern _ExitProcess@4: proc

include linkedList.inc
include readWrite.inc
include utility.inc

; for stack checking:
include rtc_esp.inc

.data

linkedList_obj dword 0

ll_data_0 byte "ll node #0, a", 0
ll_data_1 byte "ll node #1, a", 0
ll_data_2 byte "ll node #2, ab", 0
ll_data_3 byte "ll node #3, abc", 0
ll_data_4 byte "ll node #4, abcd", 0
ll_data_5 byte "ll node #5, abcde", 0
my_string byte "HellowWorld", 0

.code


; input two number, add and return
funct@8 proc near
    push ebp
    mov ebp, esp

    mov eax, [ebp + 4]
    add eax, [ebp + 8]

_exit:
    pop ebp
    ret 8 
funct@8 endp


main PROC near
rtc_esp_fail
rtc_esp_start


    ; linkedList@addNodeStr@12(* this, index, * char)
    ; returns 0 failed, 1 success
    push offset ll_data_0
    push 0
    push offset linkedList_obj
    call linkedList@addNodeStr@12

    ; linkedList@addNodeStr@12(* this, index, * char)
    ; returns 0 failed, 1 success
    push offset ll_data_1
    push 0
    push offset linkedList_obj
    call linkedList@addNodeStr@12

    ; linkedList@addNodeStr@12(* this, index, * char)
    ; returns 0 failed, 1 success
    push offset ll_data_5
    push 0
    push offset linkedList_obj
    call linkedList@addNodeStr@12

    addNode_array_b offset linkedList_obj, 0, 5,2,0,1,2,4,6



    call initialize_console@0

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    ; linkedList@deleteNode@8(* this, index)
    ; returns void
    push 1
    push offset linkedList_obj
    call linkedList@deleteNode@8

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

rtc_esp_end
	push 0
	call _ExitProcess@4

main ENDP
END
