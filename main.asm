; store and retrieve linkedList implementation    
; Amir Gorkovchenko
; 11-14-2024

.386P
.model flat

extern _ExitProcess@4: near

include rtc_esp.inc
include utility.inc

include readWrite.inc
include linkedList.inc

.data

linkedList_obj dword 0

ll_data_0 byte "ll node #0, a", 0
ll_data_1 byte "ll node #1, a", 0
ll_data_2 byte "ll node #2, ab", 0
ll_data_3 byte "ll node #3, abc", 0
ll_data_4 byte "ll node #4, abcd", 0
ll_data_5 byte "ll node #5, abcde", 0
my_string byte "HellowWorld", 0

fileName byte "llist.bin", 0
fileName_2 byte "llist_2.bin", 0

.code
main PROC near
_main:
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

    ; add array:
    addNode_array_b offset linkedList_obj, 0, 5,2,0,1,2,4,6

    call initialize_console@0

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    ; linkedList@store@8(*this, *char)
    ; returns: 0 failed, 1 success
    push offset fileName
    push offset linkedList_obj
    call linkedList@store@8

    ; linkedList@deleteNode@8(* this, index)
    ; returns void
    push 1
    push offset linkedList_obj
    call linkedList@deleteNode@8

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@deInit@4

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    ; linkedList@store@8(*this, *char)
    ; returns: 0 failed, 1 success
    push offset fileName_2
    push offset linkedList_obj
    call linkedList@store@8

rtc_esp_end
	push	0
	call	_ExitProcess@4

main ENDP
END