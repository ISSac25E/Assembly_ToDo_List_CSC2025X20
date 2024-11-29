; tests parsing integers
; Amir Gorkovchenko
; 11-28-2024

.386P
.model flat

extern _ExitProcess@4: near

include ../../utility.inc
include ../../rtc_esp.inc
include ../../readWrite.inc

.data
.code

main proc near
rtc_esp_fail
rtc_esp_start

    call initialize_console@0

_loop_start:
    call readLine_simple@0

rtc_esp_start
    push eax
    call util@parseInt@4
rtc_esp_end

    push edx
    push eax
    println_str
    pop eax
    print_int eax
    print_str " "
    pop eax
    print_int eax
    println_str

    jmp _loop_start

_loop_end:
rtc_esp_end
	push	0
	call	_ExitProcess@4
main endp
end