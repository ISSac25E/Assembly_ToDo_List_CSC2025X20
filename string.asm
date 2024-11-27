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

    push [ebp + 8] ; push string address
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


;;;;; calculate new total length



_exit:
    mov esp, ebp ; reset stack
    pop ebp
    ret 12
string@insert@12 endp


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

end