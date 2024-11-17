; store and retrieve linkedList implementation    
; Amir Gorkovchenko
; 11-14-2024

Comment @
this is a block comment!
@
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
rtc_esp_fail
rtc_esp_start

call load_ll

rtc_esp_end
	push	0
	call	_ExitProcess@4

main ENDP

load_ll proc near
rtc_esp_fail
    call initialize_console@0

    ; linkedList@store@8(*this, *char)
    ; returns: error code
rtc_esp_start
    push offset fileName
    push offset linkedList_obj
    call linkedList@load@8
rtc_esp_end

    push eax
    print_str "load error code: "
    pop eax
    print_int eax
    println_str
    
    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    println_str


    ; linkedList@store@8(*this, *char)
    ; returns: error code
rtc_esp_start
    push offset fileName_2
    push offset linkedList_obj
    call linkedList@load@8
rtc_esp_end

    push eax
    print_str "load error code: "
    pop eax
    print_int eax
    println_str

    push offset linkedList_obj  ; push linked list instance pointer
    call linkedList@print_linkedList@4

    
    ret
load_ll endp

store_ll proc near
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
    ret
store_ll endp

end