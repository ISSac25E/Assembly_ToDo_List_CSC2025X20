; clear console impl    
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

.code
main PROC near
_main:

    call initialize_console@0

    println_str "Hello World"
    call clearConsole@0
    
	push	0
	call	_ExitProcess@4

main ENDP
END