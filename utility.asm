; utility
; Amir Gorkovchenko
; 09 Nov 2024

; 11-30-2024
; - added list directory function

; collection of useful utility functions

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

extern _FindFirstFileA@8 : near
extern _FindNextFileA@8 : near
extern _FindClose@4 : near

include linkedList.inc

.data
.code

; count number of chars in ansi string
;
; util@charCount@4 (* char buffer)
; returns number of characters, null terminator not included
util@charCount@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov eax, 0  ; counter value
    mov ecx, [ebp + 8]

_char_count_loop_start:
    cmp byte ptr [ecx + eax], 0
    je _exit

    inc eax
    jmp _char_count_loop_start

_exit:
    pop ebp
    ret 4 
util@charCount@4 endp

; convert signed integer into character array. Make sure array has enough space
; optimized to minimize stack footprint, recursive function
;
; util@itoa@8(int, *buffer)
; returns address location immediately after written
util@itoa@8 proc near

    ; clean up stack for efficiency:
    pop edx ; return address
    pop eax ; integer
    pop ecx ; buffer address
    push edx ; return address

    cmp eax, 0
    jge _positive_num
    neg eax ; change to positive value
    mov byte ptr [ecx], '-'

    inc ecx ; set buffer address to next location

_positive_num:
    ; dividend already loaded into eax
    mov edx, 0

    ; divide by 10
    push ecx
    mov ecx, 10
    div ecx
    pop ecx

    cmp eax, 0  
    je _baseCase ; nothing left to divide
    
    push edx ; push remainder, this gets put on buffer. but a different position
    push ecx  ; don't modify address, this is not our address
    push eax ; push quotient for further processing
    call util@itoa@8
    ; eax now contains correct position
    pop edx ; restore

    jmp _write_buffer

_baseCase:
    mov eax, ecx ; eax contains buffer address now

_write_buffer:
    add edx, '0'
    mov byte ptr [eax], dl ; move character into buffer (last position)
    inc eax ; prepare for next recursion or parent return

_exit:
    ret ; no params to pop
util@itoa@8 endp

; parse integer from *char
; checks for negative numbers as well
; returns number of valid digit characters
; result in edx
;
; util@parseInt@4(*char)
; returns number of valid digit characters, 0 if failed. edx contains result
util@parseInt@4 proc near
    push ebp ; save base
    push ebx
    mov ebp, esp ; get stack pointer

    push 10 ; mul value

    mov eax, 0 ; clear result
	mov ecx, 0 ; valid digit flag

    mov ebx, [ebp + 12] ; get *char

    mov edx, 0
    mov dl, [ebx] ; next byte from the buffer
    cmp edx, '-' ; compare with minus sign
    push 1 ; to be multiplied by result at the end
    jne _next_digit

    add esp, 4 ; pop
    push -1 ; push negative
    inc ecx
    inc ebx ; increment to next character

_next_digit:

    mov edx, 0
    mov dl, [ebx] ; next byte from the buffer
	cmp edx, 0 ; Check for null terminator
	je _done ; If null, we're done

    cmp edx, '0' ; Check if less than '0'
	jb _done
	cmp edx, '9' ; Check if greater than '9'
	ja _done

    inc ecx ; set flag to valid. count chars
	sub edx, '0' ; convert ascii to integer
    push edx ; save edx for mul
	mul dword ptr [ebp - 4] ; eax = eax * 10
    pop edx ; restore
	add eax, edx ; add the current digit to eax
	inc ebx ; move to the next character
	jmp _next_digit ; repeat

_done:
    mov edx, eax ; mov result to result register
    pop eax ; pop the signed multiply
    imul edx, eax ; change sign if needed
    mov eax, ecx ; move char count into return

_exit:
    mov esp, ebp ; reset stack
    pop ebx
    pop ebp
    ret 4
util@parseInt@4 endp

; find directories and list into a LinkedList
; input a wild card filename: https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findfirstfilea
;
; util@listDir@8(linkedList *, char *)
; return void
util@listDir@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    ;;;;; clear linkedList before starting
    ; linkedList@deinit@4(* this)
    ; returns void
    push [ebp + 8] ; get ll
    call linkedList@deinit@4

    ; MAX_PATH = 260
    ; typedef struct _WIN32_FIND_DATAA {
    ;   DWORD    dwFileAttributes;
    ;   QWORD FILETIME ftCreationTime; https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
    ;   QWORD FILETIME ftLastAccessTime; https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
    ;   QWORD FILETIME ftLastWriteTime; https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
    ;   DWORD    nFileSizeHigh;
    ;   DWORD    nFileSizeLow;
    ;   DWORD    dwReserved0;
    ;   DWORD    dwReserved1;
    ;   CHAR     cFileName[MAX_PATH];
    ;   CHAR     cAlternateFileName[14];
    ;   DWORD    dwFileType; // Obsolete. Do not use.
    ;   DWORD    dwCreatorType; // Obsolete. Do not use
    ;   WORD     wFinderFlags; // Obsolete. Do not use
    ; } WIN32_FIND_DATAA, *PWIN32_FIND_DATAA, *LPWIN32_FIND_DATAA;
    ; 4 + 8 + 8 + 8 + 4 + 4 + 4 + 4 + 260 + 14 + 4 + 4 + 2 = 328
    sub esp, 328

    ; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findfirstfilea
    ; HANDLE FindFirstFileA(
    ; [in]  LPCSTR             lpFileName,
    ; [out] LPWIN32_FIND_DATAA lpFindFileData
    ; );
    push esp
    push [ebp + 8 + 4] ; get input file name
    call _FindFirstFileA@8

    ; find file handle
    sub esp, 4 ; [ebp - 332]
    
    mov [ebp - 332], eax

    cmp dword ptr [ebp - 332], -1
    je _end_search

    ; linkedList@addNodeStr@12(* this, index, * char)
    ; returns 0 failed, 1 success
    lea eax, [ebp - 328 + 4 + 8 + 8 + 8 + 4 + 4 + 4 + 4] ; get file name
    push eax
    push -1
    push [ebp + 8]
    call linkedList@addNodeStr@12

    _search_loop:
        ; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findnextfilea
        ; BOOL FindNextFileA(
        ; [in]  HANDLE             hFindFile,
        ; [out] LPWIN32_FIND_DATAA lpFindFileData
        ; );
        push esp ; allocated structure memory
            add dword ptr [esp], 4
        push [esp + 4] ; handle
        call _FindNextFileA@8
        cmp eax, 0
        je _close_search ; next file not found

        ; saved located file:
        lea eax, [ebp - 328 + 4 + 8 + 8 + 8 + 4 + 4 + 4 + 4] ; get file name
        push eax
        push -1
        push [ebp + 8]
        call linkedList@addNodeStr@12

        jmp _search_loop

_close_search:
    ; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findclose
    ; BOOL FindClose(
    ; [in, out] HANDLE hFindFile
    ; );
    push [esp]
    call _FindClose@4

_end_search:

_exit:
    mov esp, ebp ; because of the error handling, make sure no vars are forgotten
    pop ebp
    ret 8
util@listDir@8 endp
end