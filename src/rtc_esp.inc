; real-time-check esp register
; Amir Gorkovchenko
; 10 Nov 2024

; contains macros to check integrity of stack

; run rtc_esp_start before pushing parameters for proc call
; run rtc_esp_end after calling function 
; rtc_esp_fail must be placed in the same procedure, anywhere


; rtc_esp_fail must be placed in the same procedure, anywhere
rtc_esp_fail macro
    ; in case this macro is put in a bad place, accidental triggers are not wanted:
    jmp _safe_flag__rtc_esp_fail_macro_
    
_esp_failed_flag__rtc_esp_fail_macro_:
    call _ExitProcess@4

_safe_flag__rtc_esp_fail_macro_:
endm

; run rtc_esp_start before pushing parameters for proc call
rtc_esp_start macro
    push esp
endm


rtc_esp_end MACRO exit_code:=<543>
    ; Adjust the stack pointer and check ESP
    add esp, 4                 ; Adjust ESP after calling the function
    cmp dword ptr [esp - 4], esp  ; Check if ESP changed (it shouldn't)
    push exit_code             ; Push the exit code onto the stack
    jne _esp_failed_flag__rtc_esp_fail_macro_  ; Jump if ESP mismatch is detected
    add esp, 4                 ; Clean up the stack by adjusting ESP
endm
