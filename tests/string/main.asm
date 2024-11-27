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

    set_string offset str_1, "Test String"

    push str_1
    call writeString@4

rtc_esp_end
	push	0
	call	_ExitProcess@4
main endp
end