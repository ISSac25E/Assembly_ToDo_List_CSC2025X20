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
    ; Please enter a symbol (+, -, ? or !) followed with your To-Do list item
    ; <+> Add Chores
    ; <-> Delete Chores
    ; <?> View List
    ; <!> End Program

    print_str "Please enter a symbol (+, -, ? or "
    print_array_b 21h ; '!'
    println_str ") followed with your To-Do list item"
    
    ret
print_instructions@0 endp
END
