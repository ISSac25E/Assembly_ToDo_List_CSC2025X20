; tests for string class
; Amir Gorkovchenko
; 11-27-2024

.386P
.model flat

extern _ExitProcess@4: near

include ../../string.inc
include ../../utility.inc
include ../../rtc_esp.inc
include ../../readWrite.inc

.data

str_1 dword 0

.code

main proc near
rtc_esp_fail
rtc_esp_start
    call initialize_console@0

    set_string offset str_1

    insert_string offset str_1, "TestString", 0

    insert_string offset str_1, "-", 4
    insert_string offset str_1, "My ", 0

    push offset str_1
    call string@length@4

    insert_string offset str_1, " ...", eax

    insert_string offset str_1, " :)", -1

    push str_1
    call writeString@4
    println_str

    push 14 ; high index
    push 3 ; low index
    push offset str_1
    call string@substr@12

    push str_1
    call writeString@4
    println_str

    set_string offset str_1, "reverse this"

    push -1 ; high index
    push 0 ; low index
    push offset str_1
    call string@substr@12

    push str_1
    call writeString@4
    println_str


    push 0 ; high index
    push -1 ; low index
    push offset str_1
    call string@substr@12

    push str_1
    call writeString@4
    println_str

    push 10 ; high index
    push 12 ; low index
    push offset str_1
    call string@substr@12

    insert_string offset str_1, " Inserting a random string test for searching: hnbjgk7685, :::;;; test", -1

    push str_1
    call writeString@4
    println_str

    strcmp offset str_1, "test", 29
    
    print_int eax
    println_str

    strcmp offset str_1, "test", 30
    
    print_int eax
    println_str

rtc_esp_end
	push	0
	call	_ExitProcess@4
main endp
end