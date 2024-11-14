; ToDo List application
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
toDo_ll_obj dword 0

.code
main proc near
_main:

	push	0
	call	_ExitProcess@4

main ENDP

print_instructions proc near
print_instructions endp
END
