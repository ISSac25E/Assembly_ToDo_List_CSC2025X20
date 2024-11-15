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
rtc_esp_fail
rtc_esp_start
    call initialize_console@0

    print_array_b 3ch, 3ch, 3ch ; "<<<"
    print_str " Command Line ToDo List "
    print_array_b 3eh, 3eh, 3eh ; ">>>"
    println_str
    println_str

    call print_instructions@0


rtc_esp_end
	push	0
	call	_ExitProcess@4

main ENDP

print_instructions@0 proc near
    ; Please enter a command symbol (+, -, ? or !)
    ; <+> Add Chores
    ; <-> Delete Chores
    ; <?> View List
    ; <!> Save and Exit

    print_str "Please enter a command symbol (+, -, ? or "
    print_array_b 21h ; '!'
    println_str ")"

    print_array_b '<', '+', '>'
    println_str " Add Chores"

    print_array_b '<', '-', '>'
    println_str " Delete Chores"
    
    print_array_b '<', '?', '>'
    println_str " View List"

    print_array_b '<', 21h, '>'
    println_str " Save and Exit"

    println_str
    
    ret
print_instructions@0 endp
END
