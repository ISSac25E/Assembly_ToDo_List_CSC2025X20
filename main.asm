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
toDo_list_extension byte ".todo.bin", 0
toDo_list_default_file byte "default_list", 0 ; default file

; object used for decoding and parsing
parse_str dword 0
output_str dword 0

open_file_str dword 0

.code
main proc near
rtc_esp_fail
rtc_esp_start
    call initialize_console@0

    ; string@set@8(*this, *char)
    ; returns void
    push offset toDo_list_default_file
    push offset open_file_str
    call string@set@8
    
    ; string@insert@12(*this, *char, index)
    ; returns void
    push -1
    push offset toDo_list_extension
    push offset open_file_str
    call string@insert@12

    ; linkedList@load@8(*this, *char)
    ; returns: error code
    push open_file_str
    push offset toDo_ll_obj
    call linkedList@load@8

    call print_todo_list@0

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
        call scrollConsole@0

        set_string offset output_str

        ; string@print_array_b 3ch, 3ch, 3ch, 32 ; "<<< "
        ; push parse_str
        ; string@writeString@4
        ; string@print_array_b 32, 3eh, 3eh, 3eh ; " >>>"

        ; string@println_str

        ;;;;; check if input matches a command
            ;;;;; check <ENTER>
            push offset parse_str
            call string@length@4
            cmp eax, 0
            je _enter_command

            ;;;;; check <+>
            ; if ((parse_str.compare("+") == 0) && parse_str.length() > 1)
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register
            mov bh, 1

            strcmp offset parse_str, "+", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            and bh, bl ; set high byte

            push offset parse_str
            call string@length@4
            cmp eax, 1
            seta bl ; must have minimum of two characters
            and bh, bl ; set high byte

            cmp bh, 1
            pop ebx ; restore
            je _plus_command ; plus command found

            ;;;;;; check <->
            ; if ((parse_str.compare("-") == 0))
            push ebx ; ebx is callee saved
            xor ebx, ebx ; clear comparison register

            strcmp offset parse_str, "-", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            or bh, bl ; set high byte

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

            ;;;;;; check <*>
            ; if (parse_str.compare("*") == 0)
            push ebx
            xor ebx, ebx
            mov bh, 1
            
            strcmp offset parse_str, "*", 0
            cmp eax, 0
            sete bl ; set bl if ZF set
            and bh, bl ; set high byte

            cmp bh, 1
            pop ebx ; restore
            je _star_command

            jmp _input_error

        ;;;;;;;;;; run commands:
            _enter_command:
                push output_str
                call writeString@4
                call scrollConsole@0
                jmp _end_command_search
                
            _plus_command:

                ; string@substr@12(* this, low index, high index)
                ; returns void
                push -1 ; get the entire end of string
                push 1 ; clip one character
                push offset parse_str
                call string@substr@12

                push -1 ; index to store node at

                ; test if store index specified
                ; util@parseInt@4(*char)
                ; returns number of valid digit characters, 0 if failed. edx contains result
                push parse_str
                call util@parseInt@4

                cmp eax, 0
                je _plus_command_normal_add

                mov ecx, parse_str
                add ecx, eax
                cmp byte ptr [ecx], 32 ; must be a space character
                jne _plus_command_normal_add

                add esp, 4 ; remove -1

                ; store result
                dec edx
                push edx

                inc eax
                push -1 ; get the entire end of string
                push eax ; clip head
                push offset parse_str
                call string@substr@12

                _plus_command_normal_add:

                pop edx ; index
                push edx ; store again

                ; linkedList@addNodeStr@12(* this, index, * char)
                ; returns 0 failed, 1 success
                push parse_str
                push edx ; index to store at
                push offset toDo_ll_obj
                call linkedList@addNodeStr@12
                cmp eax, 0
                je _plus_command_add_error

                    string@println_str
                    string@print_str "added item #"

                    ; linkedList@nodeCount@4(* this)
                    ; returns >=0 number of nodes on linked list
                    push offset toDo_ll_obj
                    call linkedList@nodeCount@4

                    pop edx
                    cmp eax, edx ; check if stored value was within ll range
                    jae _plus_command_inside_range

                    mov edx, eax ; change to end of list
                    dec edx

                    _plus_command_inside_range:

                    inc edx
                    string@print_int edx   ; print item list location
                    string@print_array_b 32, 34

                    push parse_str
                    string@writeString@4

                    string@print_array_b 34
                    string@println_str
                    string@println_str

                    call print_todo_list@0
                    
                    push output_str
                    call writeString@4

                    jmp _end_command_search

                _plus_command_add_error:
                    string@println_str
                    string@println_str "Error adding to list"
                    string@println_str

                    call print_todo_list@0

                    push output_str
                    call writeString@4
                    jmp _end_command_search

            _minus_command:
                ; string@substr@12(* this, low index, high index)
                ; returns void
                push -1 ; get the entire end of string
                push 1 ; clip one character
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
                    push edx
                    string@println_str
                    string@print_str "deleted item #"
                        pop edx
                        push edx
                        inc edx
                    string@print_int edx
                    string@print_array_b 32, 34

                        ; linkedList@getNodeData@8(* this, index)
                        ; returns pointer to node data. null if node doesn't exist
                        pop edx
                        push edx
                        push edx
                        push offset toDo_ll_obj
                        call linkedList@getNodeData@8

                    push eax
                    string@writeString@4

                        ; linkedList@deleteNode@8(* this, index)
                        ; returns void
                        ; push edx ; already pushed
                        push offset toDo_ll_obj
                        call linkedList@deleteNode@8

                    string@print_array_b 32
                    string@println_str
                    string@println_str

                    call print_todo_list@0
                    
                    push output_str
                    call writeString@4

                    jmp _end_command_search

                    _minus_command_number_error_format:
                        string@println_str
                        string@println_str "delete command format error"
                        string@println_str

                        call print_todo_list@0
                    
                        push output_str
                        call writeString@4
                        jmp _end_command_search

                    _minus_command_number_error_range:
                        string@println_str
                        string@println_str "delete command range error"
                        string@println_str

                        call print_todo_list@0
                    
                        push output_str
                        call writeString@4
                        jmp _end_command_search

                _minus_command_string:
                    string@println_str

                    push offset toDo_ll_obj
                    call linkedList@nodeCount@4

                    mov ecx, 0 ; counter value
                    push eax
                    push ecx

                    _minus_command_string_loop_start:
                        pop ecx
                        pop eax
                        cmp ecx, eax
                        jae _minus_command_string_loop_end
                        push eax
                        push ecx

                        ; linkedList@getNodeData@8(* this, index)
                        ; returns pointer to node data. null if node doesn't exist
                        push ecx
                        push offset toDo_ll_obj
                        call linkedList@getNodeData@8

                        push 0 ; string object
                        ; string@set@8(*this, *char)
                        ; returns void
                        push eax
                        push esp
                            add dword ptr [esp], 4
                        call string@set@8

                        ; string@strcmp@12(*this, *char compare, int start_index)
                        ; returns index of compare hit. -1 if compare failed
                        push 0
                        push parse_str
                        push esp
                            add dword ptr [esp], 8
                        call string@strcmp@12

                        cmp eax, 0
                        jge _minus_command_string_compare_hit

                        add esp, 4 ; deallocate the string

                        inc dword ptr [esp]
                        jmp _minus_command_string_loop_start

                        _minus_command_string_compare_hit:

                            string@print_str "deleted "
                            string@print_array_b 34
                            push [esp]
                            string@writeString@4
                            string@print_array_b 34
                            string@println_str

                            add esp, 4 ; deallocate the string
                            
                            ; linkedList@deleteNode@8(* this, index)
                            ; returns void
                            push [esp] ; push counter
                            push offset toDo_ll_obj
                            call linkedList@deleteNode@8

                            dec dword ptr [esp + 4] ; one less item in the list

                        jmp _minus_command_string_loop_start

                    _minus_command_string_loop_end:

                    string@println_str
                    call print_todo_list@0
                    
                    push output_str
                    call writeString@4
                    jmp _end_command_search


            _question_command:

                call print_todo_list@0
                println_str

                push output_str
                call writeString@4
                jmp _end_command_search

            _help_command:
                call print_instructions@0

                push output_str
                call writeString@4
                jmp _end_command_search

            _exclamation_command:
                string@println_str
                string@print_str "Saving "
                push open_file_str
                string@writeString@4
                string@println_str

                ; linkedList@store@8(*this, *char)
                ; returns: 0 failed, 1 success
                push open_file_str
                push offset toDo_ll_obj
                call linkedList@store@8
                string@println_str "Exiting..."

                push output_str
                call writeString@4
                jmp _end_prog_loop
            
            _star_command:
                ; string@substr@12(* this, low index, high index)
                ; returns void
                push -1 ; get the entire end of string
                push 1 ; clip one character
                push offset parse_str
                call string@substr@12

                push offset parse_str
                call string@length@4

                cmp eax, 0
                jne _star_command_load

                ;;;;; list available todo files:
                _star_command_list_dir:
                    push ebp ; base pointer
                    mov ebp, esp

                    push 0 ; [ebp - 4] allocate string object for extension manipulation
                    ; string@set@8(*this, *char)
                    ; returns void
                    push offset toDo_list_extension
                        lea eax, [ebp - 4] ; string object
                    push eax
                    call string@set@8

                    ; string@insert@12(*this, *char, index)
                    ; returns void
                    push_str "*"
                    push 0 ; beginning of string
                    push esp
                        add dword ptr [esp], 4 ; get *char
                        lea eax, [ebp - 4] ; string object
                    push eax
                    call string@insert@12
                    pop_str "*"

                    push 0 ; allocate linkedList object [ebp - 8]

                    ; util@listDir@8(linkedList *, char *)
                    ; return void
                        lea eax, [ebp - 4] ; string object
                    push [eax] ; string pointer
                        lea eax, [ebp - 8] ; linkedList object
                    push eax
                    call util@listDir@8
                    
                        lea eax, [ebp - 8]
                    push eax
                    call print_todo_dir@4
                    
                    ;;;;; safely deallocate:
                        lea eax, [ebp - 4] ; string object
                    push eax ; string pointer
                    call string@delete@4

                        lea eax, [ebp - 8] ; linkedList object
                    push eax
                    call linkedList@deInit@4

                    mov esp, ebp
                    pop ebp

                    push output_str
                    call writeString@4
                    jmp _end_command_search

                _star_command_load:
                    ;;;;; close current file
                    ; linkedList@store@8(*this, *char)
                    ; returns: 0 failed, 1 success
                    push open_file_str
                    push offset toDo_ll_obj
                    call linkedList@store@8

                    ; string@set@8(*this, *char)
                    ; returns void
                    push parse_str
                    push offset open_file_str
                    call string@set@8

                    ; string@insert@12(*this, *char, index)
                    ; returns void
                    push -1
                    push offset toDo_list_extension
                    push offset open_file_str
                    call string@insert@12

                    ; linkedList@load@8(*this, *char)
                    ; returns: error code
                    push open_file_str
                    push offset toDo_ll_obj
                    call linkedList@load@8

                    string@println_str
                    string@println_str "opened file"
                    string@println_str

                    call print_todo_list@0
                    
                    push output_str
                    call writeString@4
                    jmp _end_command_search

            _input_error:
                string@println_str
                string@println_str "Input Error! Try Again"
                string@println_str

                push output_str
                call writeString@4
                jmp _end_command_search

        _end_command_search:
        jmp _prog_loop
    _end_prog_loop:


rtc_esp_end
	push	0
	call	_ExitProcess@4

main ENDP

; formats and prints directory of available files
;
; print_todo_dir@4(*linkedList)
; return void
print_todo_dir@4 proc near
    push ebp
    mov ebp, esp

    println_str "Available lists:"
    println_str
    
    push offset toDo_list_extension
    call util@charCount@4
    push eax ; [ebp - 4] extension character count

    ;;;;; get directory item count
    ; linkedList@nodeCount@4(* this)
    ; returns >=0 number of nodes on linked list
    push [ebp + 8] ; ll object
    call linkedList@nodeCount@4

    mov ecx, 0
    push eax ; store count
    push ecx ; counter value

    _list_dir_loop_start:
        pop ecx ; counter value
        pop eax ; item count
        cmp ecx, eax
        jae _list_dir_loop_end
        push eax ; store item count
        push ecx ; counter value

        print_str " - "

        push [esp] ; push index
        push [ebp + 8]
        call linkedList@getNodeData@8
        push eax ; store node data

        push [esp + 4] ; push index
        push [ebp + 8]
        call linkedList@getNodeSize@8

        sub eax, [ebp - 4]
        dec eax ; because of null terminator in ll
        pop ecx ; node data

        ; writeLine@8(* data, dataLength)
        ; returns void
        push eax
        push ecx
        call writeLine@8

        println_str
        
        inc dword ptr [esp] ; increment counter
        jmp _list_dir_loop_start
    _list_dir_loop_end:
    println_str
    
_exit:
    mov esp, ebp
    pop ebp
    ret 4
print_todo_dir@4 endp

; format and print the to do list
;
; print_todo_list@0(void)
; returns void
print_todo_list@0 proc near
    print_array_b 3ch, 3ch, 3ch, 32 ; "<<< "

    ; util@charCount@4 (* char buffer)
    ; returns number of characters, null terminator not included
    push offset toDo_list_extension
    call util@charCount@4
    push eax

    ; string@length@4(* this)
    ; returns string length
    push offset open_file_str
    call string@length@4
    
    pop ecx
    sub eax, ecx ; get list title only

    ; writeLine@8(* data, dataLength)
    ; returns void
    push eax
    push open_file_str
    call writeLine@8

    print_array_b 32, 3eh, 3eh, 3eh ; " >>>"
    println_str
    println_str

    ;;;;; get list item count
    ; linkedList@nodeCount@4(* this)
    ; returns >=0 number of nodes on linked list
    push offset toDo_ll_obj
    call linkedList@nodeCount@4

    mov ecx, 0
    push eax ; store count
    push ecx ; counter value

    _print_list_loop_start:
        pop ecx ; counter value
        pop eax ; item count
        cmp ecx, eax
        jae _print_list_loop_end
        push eax ; store item count
        push ecx ; counter value

        print_str "#"
            mov ecx, [esp] ; get counter
            inc ecx
        print_int ecx
        print_str ": "

        ; linkedList@getNodeData@8(* this, index)
        ; returns pointer to node data. null if node doesn't exist
        push [esp]
        push offset toDo_ll_obj
        call linkedList@getNodeData@8

        push eax
        call writeString@4
        
        println_str
        
        inc dword ptr [esp]
        jmp _print_list_loop_start
        
    _print_list_loop_end:

_exit:
    ret
print_todo_list@0 endp

print_instructions@0 proc near
    ; Please enter a command symbol (+, -, ? or !)
    ; <+> Add Chores
    ; <-> Delete Chores
    ; <?> View List
    ; <!> Save and Exit
    ; <*> Open List
    ; <[ENTER]> Clear Console

    println_str
    println_str "Please enter a command symbol"

    print_array_b '<', '+', '>'
    println_str " Add Chores"

    print_array_b '<', '-', '>'
    println_str " Delete Chores"
    
    print_array_b '<', '?', '>'
    println_str " View List"

    print_array_b '<', '*', '>'
    println_str " Open New List"

    print_array_b '<', 21h, '>'
    println_str " Save and Exit"

    println_str
    
    ret
print_instructions@0 endp
END
