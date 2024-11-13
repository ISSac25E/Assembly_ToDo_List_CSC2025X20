; linkedList excremental test
; Amir Gorkovchenko
; 11-10-2024

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

_exit:
    pop ebp
    ret 4
print_linkedList@4 endp




main PROC near
rtc_esp_fail



rtc_esp_start
    call initialize_console@0

    println_str "Hello World"
    print_str "printing a number: "
    print_int -1234
    println_str
rtc_esp_end


	push	0
	call	_ExitProcess@4

main ENDP
END
