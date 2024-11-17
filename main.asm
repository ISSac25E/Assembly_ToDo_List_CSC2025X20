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
fileName_3 byte "llist_3.bin", 0

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
    push offset fileName_3
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

    
    ret
load_ll endp

store_ll proc near
    push ebx
    push 0 ; start data value

    call initialize_console@0
    mov ebx, 0
    _loop_start:
        cmp ebx, 2000
        jae _loop_end

        mov eax, [esp] ; data value
        inc dword ptr [esp]
        addNode_array_b offset linkedList_obj, 0, al, al, al, bl, al 

        inc ebx
        jmp _loop_start
    _loop_end:
    pop eax
    pop ebx

    ; linkedList@store@8(*this, *char)
    ; returns: error code
    push offset fileName_3
    push offset linkedList_obj
    call linkedList@store@8
    ret
store_ll endp

end