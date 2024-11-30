; ToDo List application
; Amir Gorkovchenko
; 11-14-2024

; reg reference:
;     eax - caller saved register - usually used for communication between caller and callee.
;     ebx - callee saved register
;     ecx - caller saved register - Counter register 
;     edx - caller Saved register - data, I use it for saving and restoring the return address
;     esi - callee Saved register - Source Index
;     edi - callee Saved register - Destination Index
;     esp - callee Saved register - stack pointer
;     ebp - callee Saved register - base pointer.386P

.386P
.model flat

extern _ExitProcess@4: near

include string.inc

include rtc_esp.inc
include utility.inc

include readWrite.inc
include linkedList.inc

.data
toDo_ll_obj dword 0
toDo_list_file byte "list.todo.dat", 0

; object used for decoding and parsing
parse_str dword 0

open_file_str dword 0

.code
main proc near
rtc_esp_fail
rtc_esp_start
    call initialize_console@0

    ; string@set@8(*this, *char)
    ; returns void
    push offset toDo_list_file
    push offset open_file_str
    call string@set@8

    ; linkedList@load@8(*this, *char)
    ; returns: error code
    push open_file_str
    push offset toDo_ll_obj
    call linkedList@load@8

    print_array_b 3ch, 3ch, 3ch ; "<<<"
    print_str " Command Line ToDo List "
    print_array_b 3eh, 3eh, 3eh ; ">>>"
    println_str
    println_str

    call print_instructions@0

    ; loops forever until program exit called:
    _prog_loop:
        print_str "Input Command "
        print_array_b 62,62,62,32 ; ">>> "
        call readLine_simple@0

        ; string@set@8(*this, *char)
        ; returns void
        push eax
        push offset parse_str
        call string@set@8

        ;;;;; clear console and rewrite for better readability:
        call clearConsole@0

        print_array_b 3ch, 3ch, 3ch, 32 ; "<<< "
        push parse_str
        call writeString@4
        print_array_b 32, 3eh, 3eh, 3eh ; " >>>"

        println_str

        ;;;;; check if input matches a command
            ;;;;; check <ENTER>
            push offset parse_str
            call string@length@4
            cmp eax, 0
            je _enter_command

            ;;;;; check <+>
            ; if ((parse_str.compare("+ ") == 0 || parse_str.compare("+\t") == 0) && parse_str.length() > 2)
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register

            strcmp offset parse_str, "+ ", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push_array_b '+', 9, 0 ; "+\t"
            push 0
            push esp
                add dword ptr [esp], 4
            push offset parse_str
            call string@strcmp@12
            pop_array_b '+', 9, 0 ; "+\t"
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push offset parse_str
            call string@length@4
            cmp eax, 2
            seta bl ; must have minimum of two characters
            and bh, bl ; set high byte

            cmp bh, 1
            pop ebx ; restore
            je _plus_command ; plus command found

            ;;;;;; check <->
            ; if ((parse_str.compare("- ") == 0 || parse_str.compare("-\t") == 0) && parse_str.length() > 2)
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register

            strcmp offset parse_str, "- ", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push_array_b '-', 9, 0 ; "-\t"
            push 0
            push esp
                add dword ptr [esp], 4
            push offset parse_str
            call string@strcmp@12
            pop_array_b '-', 9, 0 ; "-\t"
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push offset parse_str
            call string@length@4
            cmp eax, 2
            seta bl ; must have minimum of two characters
            and bh, bl ; set high byte

            cmp bh, 1
            pop ebx ; restore
            je _minus_command ; plus command found

            ;;;;;; check <?>
            ; if (parse_str.compare("?") == 0 && parse_str.length() == 1)
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register

            strcmp offset parse_str, "?", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push offset parse_str
            call string@length@4
            cmp eax, 1
            sete bl ; must have exactly one character
            and bh, bl ; set high byte

            cmp bh, 1
            pop ebx ; restore
            je _question_command ; question command found

            ;;;;;; check <help>
            ; if (parse_str.compare("help") == 0 && parse_str.length() == 4)
            push ebx
            xor ebx, ebx

            ; create new string object
            push 0 ; << empty string object

            ; string@set@8(*this, *char)
            ; returns void
            push parse_str ; push string address, not this
            push esp
                add dword ptr [esp], 4 ; increment to capture correct address
            call string@set@8

            ; string@toLower@4(*this)
            ; returns void
            push esp ; push this
            call string@toLower@4

            mov ecx, esp ; temporarily move to ecx to compare

            strcmp ecx, "help", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push esp
            call string@length@4
            cmp eax, 4
            sete bl ; must have exactly 4 characters for "help"
            and bh, bl ; set high byte

            add esp, 4 ; dealloc string object
            
            cmp bh, 0
            pop ebx ; restore
            ja _help_command ; question command found

            ;;;;;; check <!>
            ; if (parse_str.compare("!") == 0 && parse_str.length() == 1)
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register

            push_array_b 21h, 0 ; "!"
            push 0
            push esp
                add dword ptr [esp], 4
            push offset parse_str
            call string@strcmp@12
            pop_array_b 21h, 0 ; "!"
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

            push offset parse_str
            call string@length@4
            cmp eax, 1
            sete al ; must have exactly one character
            and bh, bl ; set high byte
            
            cmp bh, 0
            pop ebx ; restore
            ja _exclamation_command ; exclamation command found

            jmp _input_error

        ;;;;;;;;;; run commands:
            _enter_command:
                call clearConsole@0
                jmp _end_command_search
                
            _plus_command:
                ; string@substr@12(* this, low index, high index)
                ; returns void
                push -1 ; get the entire end of string
                push 2 ; clip two characters
                push offset parse_str
                call string@substr@12

                ; linkedList@addNodeStr@12(* this, index, * char)
                ; returns 0 failed, 1 success
                push parse_str
                push -1 ; end of the linked list
                push offset toDo_ll_obj
                call linkedList@addNodeStr@12
                cmp eax, 0
                je _plus_command_add_error

                    println_str
                    println_str "1 item added"
                    println_str
                    jmp _end_command_search

                _plus_command_add_error:
                    println_str
                    println_str "Error adding to list"
                    println_str
                    jmp _end_command_search

            _minus_command:
                ; string@substr@12(* this, low index, high index)
                ; returns void
                push -1 ; get the entire end of string
                push 2 ; clip two characters
                push offset parse_str
                call string@substr@12

                ; check which type of minus command it is:
                    ; if (util@parseInt@4(parse_str))
                    ; else cmp with every node to delete str
                    push ebx ; ebx is callee saved
                    xor ebx, ebx ; clear comparison register
                    mov bh, 1

                    ; util@parseInt@4(*char)
                    ; returns number of valid digit characters, 0 if failed. edx contains result
                    push parse_str
                    call util@parseInt@4
                    cmp eax, 0
                    seta bl
                    and bh, bl ; set high byte

                    cmp bh, 1
                    pop ebx
                    je _minus_command_number ; number command found

                    jmp _minus_command_string ; string command


                _minus_command_number:
                    push ebx
                    xor ebx, ebx ; clear compare value
                    ; 0 = good command
                    ; x1 = bad command format
                    ; 1x = bad range

                    ; save result value:
                    push edx

                    push eax ; save expected
                    
                    push offset parse_str
                    call string@length@4
                    pop ecx ; get expected length
                    cmp eax, ecx
                    setne bl
                    or bh, bl ; set high byte (x1)

                    ;;;;; get linkedList size
                    ; linkedList@nodeCount@4(* this)
                    ; returns >=0 number of nodes on linked list
                    push offset toDo_ll_obj
                    call linkedList@nodeCount@4

                    ; restore result value:
                    pop edx
                    dec edx ; this will reflect the actual index of the linkedList (0->n, not 1->n)
                    
                    cmp edx, eax ; compare command with nodeCount
                    setae bl
                    shl bl, 1 ; shift left 1
                    or bh, bl ; set high byte (1x)

                    mov ah, bh
                    pop ebx

                    test ah, 01h ; test bit x1
                    jnz _minus_command_number_error_format

                    test ah, 02h ; test bit 1x
                    jnz _minus_command_number_error_range

                    ;;;;; delete item at selected index
                    ; linkedList@deleteNode@8(* this, index)
                    ; returns void
                    push edx
                    push offset toDo_ll_obj
                    call linkedList@deleteNode@8

                    println_str
                    println_str "deleted 1 item"
                    println_str

                    jmp _end_command_search

                    _minus_command_number_error_format:
                        println_str
                        println_str "delete command format error"
                        println_str
                        jmp _end_command_search

                    _minus_command_number_error_range:
                        println_str
                        println_str "delete command range error"
                        println_str
                        jmp _end_command_search

                _minus_command_string:

                    

                    println_str "delete string command ToDo"
                    println_str 
                    jmp _end_command_search


            _question_command:
                ; print current list
                push offset toDo_ll_obj
                call linkedList@print_linkedList@4 ; for development only
                jmp _end_command_search

            _help_command:
                println_str
                call print_instructions@0
                jmp _end_command_search

            _exclamation_command:
                println_str
                print_str "saving "
                push open_file_str
                call writeString@4
                println_str

                ; linkedList@store@8(*this, *char)
                ; returns: 0 failed, 1 success
                push open_file_str
                push offset toDo_ll_obj
                call linkedList@store@8
                println_str "Exiting..."
                jmp _end_prog_loop

            _input_error:
                println_str
                println_str "Input Error! Try Again"
                println_str
        _end_command_search:
        jmp _prog_loop
    _end_prog_loop:


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
    ; <*> Open List
    ; <[ENTER]> Clear Console

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

    print_array_b '<', '*', '>'
    println_str " Open New List"

    print_array_b 60, 91 ; "<["
    print_str "ENTER"
    print_array_b 93, 62 ; "]>"
    println_str " Clear Console"

    println_str
    
    ret
print_instructions@0 endp
END
