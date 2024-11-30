; Main Console program
; Wayne Cook
; 10 March 2024
;
; changelog:
;   11-30-2024 - Amir Gorkovchenko
;   - added scrollConsole
;   11-29-2024 - Wayne Cook
;   - implemented cursor reset in clearConsole@0
;   11-15-2024 - Amir Gorkovchenko
;   - added clear console method
;   11-10-2024 - Amir Gorkovchenko
;   - revised naming convention
;   - adjusted modified registers to match __stdcall
;
;   Revised: WWC 14 March 2024 Added new module
;   Revised: WWC 15 March 2024 Added this comment ot force a new commit.
;   Revised: WWC 13 September 2024 Minor updates for Fall 2024 semester.
;   Revised: WWC 23 September 2024 Split to have main, utils, & program.
;   Revised: WWC 4 October 2024 Make writeNumber a recursive call.

; using __stdcall: https://learn.microsoft.com/en-us/cpp/cpp/stdcall?view=msvc-170
; name mangling: https://en.wikiversity.org/wiki/Visual_C%2B%2B_name_mangling

; reg reference:
;     eax - caller saved register - usually used for communication between caller and callee.
;     ebx - callee saved register
;     ecx - caller saved register - Counter register 
;     edx - caller Saved register - data, I use it for saving and restoring the return address
;     esi - callee Saved register - Source Index
;     edi - callee Saved register - Destination Index
;     esp - callee Saved register - stack pointer
;     ebp - callee Saved register - base pointer.386P

.model flat

; Library calls used for input from and output to the console
extern _GetStdHandle@4 : near
extern _GetConsoleMode@8 : near
extern _SetConsoleMode@8 : near
extern _WriteConsoleA@20 : near
extern _ReadConsoleA@20 : near
extern _ExitProcess@4 :  near
extern _SetConsoleCursorPosition@8 : near

include utility.inc

.data

outputHandle    dword ?           ; Output handle writing to consol. uninitialized
inputHandle     dword ?           ; Input handle reading from console. uninitialized
; written         dword ? ; not needed

INPUT_FLAG      equ   -10
OUTPUT_FLAG     equ   -11

; Reading and writing requires buffers. I fill them with 00h.
readBuffer      byte  1024        DUP(00h)
writeBuffer     byte  1024        DUP(00h)
numberBuffer    byte  1024        DUP(00h)
numCharsToRead  dword 1024
numCharsRead  dword 1024


.code
;; Call initialize_console@0() - No Parameters, no return value
;; Initialize Input and Output handles so you only have to do that once.
; initialize_console@0()
; returns void
initialize_console@0 PROC near
    ; https://learn.microsoft.com/en-us/windows/console/getstdhandle
    ; HANDLE WINAPI GetStdHandle(
    ;   _In_ DWORD nStdHandle
    ; );
    push    OUTPUT_FLAG
    call    _GetStdHandle@4
    mov     outputHandle, eax

    push  INPUT_FLAG
    call  _GetStdHandle@4
    mov   inputHandle, eax
    ret
initialize_console@0 ENDP

;; Call readline() - No Parameters, Returns ptr to buffer in eax
;; Now the read/write handles are set, read a line
; readLine@0()
; returns buffer ptr
readLine@0 PROC near
_readline: 
    ; https://learn.microsoft.com/en-us/windows/console/readconsole
    ; BOOL WINAPI ReadConsole(
    ;   _In_     HANDLE  hConsoleInput,
    ;   _Out_    LPVOID  lpBuffer,
    ;   _In_     DWORD   nNumberOfCharsToRead,
    ;   _Out_    LPDWORD lpNumberOfCharsRead,
    ;   _In_opt_ LPVOID  pInputControl
    ; );
    push  0
    push  offset numCharsRead
    push  numCharsToRead
    push  offset readBuffer
    push  inputHandle
    call  _ReadConsoleA@20
    mov   eax, offset readBuffer
    ret
readLine@0 ENDP

; Call readLine_simple() - No Parameters, Returns ptr to buffer in eax
; this version of read line will clear out carriage return and line feed
;
; readLine_simple@0()
; returns buffer ptr
readLine_simple@0 PROC near
    call readLine@0

    push eax

_start_loop:
    cmp byte ptr [eax], 13 ; CR
    je _end_loop
    cmp byte ptr [eax], 10 ; LF
    je _end_loop
    cmp byte ptr [eax], 0 ; control, don't want to be loop forever looking for non-existent chars
    je _end_loop

    inc eax ; next char
    jmp _start_loop

_end_loop:
    mov byte ptr [eax], 0
    pop eax
    ret
readLine_simple@0 ENDP

; write buffer to console
; writeLine@8(* data, dataLength)
; returns void
writeLine@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    ; https://learn.microsoft.com/en-us/windows/console/writeconsole
    ; BOOL WINAPI WriteConsole(
    ;   _In_             HANDLE  hConsoleOutput,
    ;   _In_       const VOID    *lpBuffer,
    ;   _In_             DWORD   nNumberOfCharsToWrite,
    ;   _Out_opt_        LPDWORD lpNumberOfCharsWritten,
    ;   _Reserved_       LPVOID  lpReserved
    ; );
    push   0
    push   0 ; optional
    push   [ebp + 8 + (1 * 4)] ; return size to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack)
    push   [ebp + 8 + (0 * 4)] ; return the offset of the data to be written
    push   outputHandle
    call   _WriteConsoleA@20

_exit:
    pop ebp
    ret 8 
writeLine@8 endp

; write a null-terminated char string
; simplifies printing to console
; writeString@4(* char)
; returns void
writeString@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    push [ebp + 8 + (4 * 0)]
    call util@charCount@4

    push eax
    push [ebp + 8 + (4 * 0)]
    call writeLine@8

_exit:
    pop ebp
    ret 4
writeString@4 endp 

; clears console and scroll back too
; returns console mode back to normal
; https://learn.microsoft.com/en-us/windows/console/clearing-the-screen
; can get much more advanced here: https://en.wikipedia.org/wiki/ANSI_escape_code
; clearConsole@0()
; output: void
clearConsole@0 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    sub esp, 4
    push esp
    push outputHandle
    ; https://learn.microsoft.com/en-us/windows/console/getconsolemode
    ; BOOL WINAPI GetConsoleMode(
    ; _In_  HANDLE  hConsoleHandle,
    ; _Out_ LPDWORD lpMode
    ; );
    call _GetConsoleMode@8

    cmp eax, 0
    je  _error

    mov eax, [ebp - 4] ; get current console mode
    or eax, 04h ; ENABLE_VIRTUAL_TERMINAL_PROCESSING ; https://learn.microsoft.com/en-us/windows/console/setconsolemode

    ; https://learn.microsoft.com/en-us/windows/console/setconsolemode
    ; BOOL WINAPI SetConsoleMode(
    ; _In_ HANDLE hConsoleHandle,
    ; _In_ DWORD  dwMode
    ; );
    push eax
    push outputHandle
    call _SetConsoleMode@8

    cmp eax, 0
    je _error
    
    ; print "\x1b[2J", clear viewable screen
    ; print "\x1b[3J", clear scroll back
    ; "\x1b" is an escape char = 1bh
    print_array_b 1bh, '[', '2', 'J'
    print_array_b 1bh, '[', '3', 'J'

    push 0
    push  outputHandle            ; [--]
    call _SetConsoleCursorPosition@8


    ; restore the mode on the way out to be nice to other command-line applications
    ; pop eax   ; no need to pop and push
    ; push eax
    push outputHandle
    call _SetConsoleMode@8

    jmp _exit

_error:

_exit:
    mov esp, ebp ; because of the error handling, make sure no vars are forgotten
    pop ebp
    ret
clearConsole@0 endp

; scrolls console, does not delete history
; returns console mode back to normal
; https://learn.microsoft.com/en-us/windows/console/clearing-the-screen
; scrollConsole@0()
; output: void
scrollConsole@0 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    sub esp, 4
    push esp
    push outputHandle
    ; https://learn.microsoft.com/en-us/windows/console/getconsolemode
    ; BOOL WINAPI GetConsoleMode(
    ; _In_  HANDLE  hConsoleHandle,
    ; _Out_ LPDWORD lpMode
    ; );
    call _GetConsoleMode@8

    cmp eax, 0
    je  _error

    mov eax, [ebp - 4] ; get current console mode
    or eax, 04h ; ENABLE_VIRTUAL_TERMINAL_PROCESSING ; https://learn.microsoft.com/en-us/windows/console/setconsolemode

    ; https://learn.microsoft.com/en-us/windows/console/setconsolemode
    ; BOOL WINAPI SetConsoleMode(
    ; _In_ HANDLE hConsoleHandle,
    ; _In_ DWORD  dwMode
    ; );
    push eax
    push outputHandle
    call _SetConsoleMode@8

    cmp eax, 0
    je _error
    
    push 0
    push  outputHandle            ; [--]
    call _SetConsoleCursorPosition@8

    ; print "\x1b[2J", clear viewable screen
    ; "\x1b" is an escape char = 1bh
    print_array_b 1bh, '[', '2', 'J'

    ; restore the mode on the way out to be nice to other command-line applications
    ; pop eax   ; no need to pop and push
    ; push eax
    push outputHandle
    call _SetConsoleMode@8

    jmp _exit

_error:

_exit:
    mov esp, ebp ; because of the error handling, make sure no vars are forgotten
    pop ebp
    ret
scrollConsole@0 endp

; genNumber and writeNumber were removed for using callee saved registers without restoring
END