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

; take a linked-list object and print content
; print_linkedList@4(*linkedList)
print_linkedList@4 proc near
    ; get base pointer
    push ebp
    mov ebp, esp
    
    print_str "Linked List ("
    ; linkedList@nodeCount@4(* this)
    ; returns >=0 number of nodes on linked list
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@nodeCount@4
    print_int eax
    push eax    ; store node count
    println_str "):"

    push ebx
    mov ebx, 0

_start_loop:
    cmp ebx, [ebp - 4] ; compare with number of nodes in list
    jge _end_loop

    print_str "node "
    print_int ebx
    print_str " ("

    ; linkedList@getNodeSize@8(* this, index)
    ; returns node data byte count.
    push ebx
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@getNodeSize@8

    print_int eax   ; node size in bytes
    print_str "-bytes): "
    
    ;;;;; print node data as string:
    ; linkedList@getNodeData@8(* this, index)
    ; returns pointer to node data. null if node doesn't exist
    push ebx ; push current index
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@getNodeData@8

    cmp eax, 0
    je _null_node

    
    push eax ; to write later
    
    print_array_b 022h ; quote mark
    call writeString@4  ; eax already pushed on stack
    print_array_b 022h ; quote mark

    println_str

    inc ebx
    jmp _start_loop

_null_node:
    println_str "null"
    inc ebx
    jmp _start_loop

_end_loop:
    pop ebx
    add esp, 4 ; pop eax
    jmp _exit

_exit:
    println_str
    pop ebp
    ret 4
print_linkedList@4 endp


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


    call initialize_console@0

    push offset linkedList_obj  ; push linked list instance pointer
    call print_linkedList@4

    ; linkedList@deleteNode@8(* this, index)
    ; returns void
    push 1
    push offset linkedList_obj
    call linkedList@deleteNode@8

    push offset linkedList_obj  ; push linked list instance pointer
    call print_linkedList@4

rtc_esp_end
	push 0
	call _ExitProcess@4

main ENDP
END
