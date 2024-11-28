; string
; Amir Gorkovchenko
; 11-26-2024

; this is a string class
; each member function expects the instance pointer as the first parameter.
; there is only one data member in this class, the string pointer

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

.386P
.model flat

extern _GetProcessHeap@0 : proc
extern _HeapAlloc@12 : proc
extern _HeapFree@12 : proc

extern _RtlMoveMemory@12 : proc

include utility.inc
include rtc_esp.inc

.data
.code

; init
; this will set the string empty ""
; this will deallocate any previous strings in the instance
;
; string@init@4(* this)
; returns void
string@init@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov ecx, [ebp + 8] ; get *this
    cmp dword ptr [ecx], 0
    je _str_dealloc

    push [ecx]
    call string@util@free@4

_str_dealloc:
    push 1
    call string@util@alloc@4

    mov ecx, [ebp + 8] ; get *this
    mov [ecx], eax ; update newly allocated memory location

    mov ecx, [ecx]
    mov byte ptr [ecx], 0 ; set string null terminator

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 4
string@init@4 endp

; return string length. null terminator NOT included. "" will return 0
; is *this is null, 0 will be returned
;
; string@length@4(* this)
; returns string length
string@length@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov eax, 0 ; start return value as 0 default
    mov ecx, [ebp + 8] ; get *this
    cmp dword ptr [ecx], 0
    je _exit ; eax already set

    push [ecx] ; push string address
    call util@charCount@4 ; eax should be set

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 4
string@length@4 endp

; copy to string from another string. Source must be the address of the char array, NOT string class
;
; string@set@8(*this, *char)
; returns void
string@set@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov ecx, [ebp + 8] ; get *this
    cmp dword ptr [ecx], 0
    je _str_dealloc

    push [ecx]
    call string@util@free@4

_str_dealloc:

    push [ebp + 8 + 4] ; push new *char
    call util@charCount@4 ; eax set
    inc eax ; for null terminator

    push eax ; push twice for mem cpy and alloc
    push eax
    call string@util@alloc@4
    cmp eax, 0
    je _exit ; failed to allocate

    mov ecx, [ebp + 8] ; get *this
    mov [ecx], eax ; update string wit allocated memory

    ; copy contents into allocated memory:
    ; https://learn.microsoft.com/en-us/windows/win32/devnotes/rtlmovememory
    ; VOID RtlMoveMemory(
    ;   _Out_       VOID UNALIGNED *Destination,
    ;   _In_  const VOID UNALIGNED *Source,
    ;   _In_        SIZE_T         Length
    ; );
    ; data length already pushed
    push [ebp + 8 + 4] ; src
    push eax ; dest
    call _RtlMoveMemory@12

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 8
string@set@8 endp

; concatenate to string from another string. Source must be the address of the char array, NOT string class
;
; string@add@8(*this, *char)
; returns void
string@add@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    ; get new string length, must be non-zero:
    push [ebp + 8 + 4]
    call util@charCount@4
    cmp eax, 0
    je _exit ; no point adding empty string

    push eax ; save new string length
    
    mov ecx, [ebp + 8] ; get this pointer
    mov ecx, [ecx] ; get string pointer

    cmp ecx, 0
    je _string_uninitialized
        
        push ecx
        call util@charCount@4

        push eax ; store original string length

    _string_uninitialized:


    
_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 8
string@add@8 endp

; insert a *char into string object at given index. 
; if index is greater than current string length, will be added at the end.
;
; string@insert@12(*this, *char, index)
; returns void
string@insert@12 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

;;;;; initialize string if needed
    mov ecx, [ebp + 8] ; get this
    cmp dword ptr [ecx], 0
    jne _string_initialized

    push [ebp + 8]
    call string@init@4

_string_initialized:
;;;;; calculate new total length
    push [ebp + 8] ; calculate current string length
    call string@length@4
    push eax ; save length [ebp - 4]

    ;;;;; modify index so it doesn't overreach based on string length:
        cmp [ebp + 8 + 8], eax ; compare index with string length
        jbe _good_index ; less than equal means valid

        mov [ebp + 8 + 8], eax ; set index to end of string

    _good_index:

    push [ebp + 8 + 4] ; calculate insert string length
    call util@charCount@4
    push eax ; save length [ebp - 8]

    mov ecx, [esp]
    add ecx, [esp + 4]

    push ecx ; save total string size for later reference [ebp - 12]
        inc ecx ;  include null terminator for allocation
    push ecx
    call string@util@alloc@4
    cmp eax, 0
    je _exit ; failed to allocate

    push eax ; save new location [ebp - 16]


;;;;; split string and copy to new location in three steps:

    ; https://learn.microsoft.com/en-us/windows/win32/devnotes/rtlmovememory
    ; VOID RtlMoveMemory(
    ;   _Out_       VOID UNALIGNED *Destination,
    ;   _In_  const VOID UNALIGNED *Source,
    ;   _In_        SIZE_T         Length
    ; );
    push [ebp + 8 + 8] ; push index
        mov ecx, [ebp + 8] ; get this pointer
    push [ecx] ; push start of old string location
    push eax ; push start of new location
    call _RtlMoveMemory@12

    push [ebp - 8] ; insert string length
    push [ebp + 8 + 4] ; insert string
        mov eax, [ebp - 16] ; get new location
        add eax, [ebp + 8 + 8] ; add with index
    push eax ; target location with offset
    call _RtlMoveMemory@12

        mov eax, [ebp - 4] ; get original string length
        sub eax, [ebp + 8 + 8] ; subtract with index to get remaining bytes to copy
    push eax ; remaining bytes to copy
        mov eax, [ebp + 8] ; get this
        mov eax, [eax]  ; get source string location
        add eax, [ebp + 8 + 8] ; offset by index
    push eax
        mov eax, [ebp - 16] ; get new location
        add eax, [ebp + 8 + 8] ; add with index
        add eax, [ebp - 8] ; add with insert string length
    push eax
    call _RtlMoveMemory@12

;;;;; clean up old string and link new one
        mov eax, [ebp + 8] ; get this
    push [eax] ; push string location
    call string@util@free@4

    mov ecx, [ebp - 16] ; get new location
    mov eax, [ebp + 8] ; get this
    mov [eax], ecx

    add ecx, [ebp - 12] ; add by total length to get address of string tail
    mov byte ptr [ecx], 0 ; insert null terminator 

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 12
string@insert@12 endp

; split a string according to start and stop index
; reversing low and high index will reverse the string as well
;
; string@substr@12(* this, int low_index, int high_index)
; returns void
string@substr@12 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

;;;;; initialize string if needed
    mov ecx, [ebp + 8] ; get this
    cmp dword ptr [ecx], 0
    jne _string_initialized

    push [ebp + 8]
    call string@init@4
    jmp _exit ; cant substr an empty string

_string_initialized:

;;;;; calculate current string length
    push [ebp + 8] ; *this
    call string@length@4
    push eax ; save string length [ebp - 4]

;;;;; adjust indexes as needed
    mov ecx, [ebp + 8 + 4] ; low index
    cmp ecx, [ebp - 4] ; cmp with string length
    jbe _low_index_in_range

    mov ecx, [ebp - 4] ; mov string length for low index (highest possible value)
    mov [ebp + 8 + 4], ecx ; update param

_low_index_in_range:

    mov ecx, [ebp + 8 + 8] ; high index
    cmp ecx, [ebp - 4] ; cmp with string length
    jbe _high_index_in_range

    mov ecx, [ebp - 4] ; mov string length for low index (highest possible value)
    mov [ebp + 8 + 8], ecx ; update param

_high_index_in_range:

;;;;; calculate difference
    mov ecx, [ebp + 8 + 8] ; get high index
    cmp [ebp + 8 + 4], ecx ; cmp with low index
    ja _low_index_higher

    push 1 ; save increment value [ebp - 8]

    sub ecx, [ebp + 8 + 4] ; get difference
    push ecx ; save difference [ebp - 12]
    jmp _index_cmp_done

_low_index_higher:
    push -1 ; save increment value [ebp - 8]

    mov ecx, [ebp + 8 + 4] ; get low index (larger num)
    sub ecx, [ebp + 8 + 8] ; get difference
    push ecx ; save difference [ebp - 12]

    dec dword ptr [ebp + 8 + 4] ; needed to make the math work

_index_cmp_done:

;;;;; copy data using loop

    ;; allocate memory:
    push [ebp - 12]
        inc dword ptr [esp] ; null terminator
    call string@util@alloc@4
    
    cmp eax, 0
    je _exit ; error

    push eax ; save new location [ebp - 16]

    ; ecx is read address
    ; eax is counter
    ; edx is write address
    mov ecx, [ebp + 8] ; get this
    mov ecx, [ecx] ; get * string
    add ecx, [ebp + 8 + 4] ; starting location is low index
    
    mov edx, [ebp - 16] ; get target location
    
    mov eax, 0
    _mem_cpy_loop:
        cmp eax, [ebp - 12] ; check number of chars left
        jae _mem_cpy_loop_end

        push eax
        mov al, [ecx]
        mov [edx], al
        pop eax

        add ecx, [ebp - 8] ; add with increment value
        inc edx
        inc eax
        jmp _mem_cpy_loop

    _mem_cpy_loop_end:

;;;;; clean up:
    mov byte ptr [edx], 0 ; null terminator

    mov ecx, [ebp + 8] ; get this
    push [ecx] ; push old string address
    call string@util@free@4

    mov edx, [ebp - 16] ; get target location
    mov ecx, [ebp + 8] ; get this
    mov [ecx], edx ; update with new string

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 12
string@substr@12 endp

; compare string to another string at start index
; will return index of first occurrence. -1 otherwise
;
; string@strcmp@12(*this, *char compare, int start_index)
; returns index of compare hit. -1 if compare failed
string@strcmp@12 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

;;;;; initialize string if needed
    mov ecx, [ebp + 8] ; get this
    cmp dword ptr [ecx], 0
    jne _string_initialized

    push [ebp + 8]
    call string@init@4

_string_initialized:

;;;;; get search range
    push [ebp + 8] ; *this
    call string@length@4
    push eax ; save string length [ebp - 4]

    push [ebp + 8 + 4] ; compare string
    call util@charCount@4
    cmp eax, [ebp - 4]
    ja _cmp_fail ; compare string too long, can't search

    sub [ebp - 4], eax ; [ebp - 4] contains highest searchable index

    ; ecx contains current search address
    ; [ebp - 8] contains stop search address
    mov ecx, [ebp + 8] ; get this
    mov ecx, [ecx] ; get string
    mov edx, ecx ; get sting for edx also
    add ecx, [ebp + 8 + 8] ; add start index

    add edx, [ebp - 4] ; edx has highest searchable address
    push edx

    _cmp_loop:
        cmp ecx, [ebp - 8]
        jg _cmp_fail
        
        ; string@util@strcmp@8(*char source, *char compare)
        ; returns bool. true = compared same
        push ecx ; save ecx
        push [ebp + 8 + 4] ; push compare string
        push ecx
        call string@util@strcmp@8
        pop ecx
        cmp eax, 0
        jne _cmp_success

        inc ecx ; increment working address
        jmp _cmp_loop

_cmp_success:
    mov eax, [ebp + 8] ; get this
    mov eax, [eax] ; get string start

    sub ecx, eax ; get difference (index of search hit)
    mov eax, ecx ; move to return value
    jmp _exit

_cmp_fail:
    mov eax, -1

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 12
string@strcmp@12 endp

; simplify memory allocation for string
; input allocation size.
; returns allocated address
; null if failed
;
; string@util@alloc@4(alloc_size)
; returns allocated address. null if failed
string@util@alloc@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    ; HANDLE GetProcessHeap();
    call _GetProcessHeap@0

    push [ebp + 8] ; push number of bytes to allocate
    push 0 ; no flags. no thrown exceptions. only null return on fail
    push eax ; push handle
    call _HeapAlloc@12

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 4
string@util@alloc@4 endp

; simplify freeing memory
; input address to free
; if the function succeeds, the return value is nonzero
;
; string@util@free@4(address)
; returns bool
string@util@free@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    ; HANDLE GetProcessHeap();
    call _GetProcessHeap@0

    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapfree
    ; BOOL HeapFree(
    ;   [in] HANDLE                 hHeap,
    ;   [in] DWORD                  dwFlags,
    ;   [in] _Frees_ptr_opt_ LPVOID lpMem
    ; );
    push [ebp + 8] ; push address to free
    push 0
    push eax ; push handler
    call _HeapFree@12
    ; return value saved in eax

_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 4
string@util@free@4 endp


; compare a source *char with compare *char
; the beginning of source *char MUST match compare *char exactly.
; source *char can be longer but NOT shorter than compare *char
;
; string@util@strcmp@8(*char source, *char compare)
; returns bool. true = compared same
string@util@strcmp@8 proc near
    mov ecx, [esp + 4] ; get source
    mov edx, [esp + 4 + 4] ; get compare

_cmp_loop_start:
    cmp byte ptr [edx], 0 ; check for null terminator
    je _cmp_good

    mov al, [ecx]
    cmp al, [edx]
    jne _cmp_bad

    inc ecx
    inc edx
    jmp _cmp_loop_start

_cmp_good:
    mov eax, 1
    ret 8

_cmp_bad:
    mov eax, 0
    ret 8
string@util@strcmp@8 endp

end