; tests parsing integers
; Amir Gorkovchenko
; 11-28-2024

.386P
.model flat

extern _ExitProcess@4 : near

extern _FindFirstFileA@8 : near

include ../../utility.inc
include ../../rtc_esp.inc
include ../../readWrite.inc
include ../../linkedList.inc

.data

file_byte byte "*.txt", 0
ll_obj dword 0

.code

main proc near
rtc_esp_fail
rtc_esp_start
    call initialize_console@0

    ; util@listDir@8(linkedList *, char *)
    ; return void
    push offset file_byte
    push offset ll_obj
    call util@listDir@8

    push offset ll_obj
    call linkedList@print_linkedList@4

rtc_esp_end
	push	0
	call	_ExitProcess@4
main endp
end