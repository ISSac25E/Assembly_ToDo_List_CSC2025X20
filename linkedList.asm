; linked list
; Amir Gorkovchenko
; 09 Nov 2024

; this is a linked list class
; each member function expects the instance pointer as the first parameter
;
; each node's memory will be organized as following:
; [next_node_ptr(4-bytes)][node_length(4-bytes)][node_data(node_length-bytes)]
; head_node_ptr -> node_0 -> node_1 -> node_2...

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

include readWrite.inc
include utility.inc
include rtc_esp.inc

.data
.code

; add a node in the linked list at specified index
; If inputted index exceeds the number of nodes in the chain by more than 1,
; the new node will simply be added at the very end
;
; linkedList@addNode@16(* this, index, * data, dataLength)
; returns 0 failed, 1 success
linkedList@addNode@16 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    cmp dword ptr [ebp + 20], 0 ; check data length, must be more than zero
    ; jl _failed  ; zero is allowed. just an empty node though. accepting unsigned int

; allocate memory:
    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    ; HANDLE GetProcessHeap();
    call _GetProcessHeap@0

    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapalloc
    ; DECLSPEC_ALLOCATOR LPVOID HeapAlloc(
    ;   [in] HANDLE hHeap,
    ;   [in] DWORD  dwFlags,
    ;   [in] SIZE_T dwBytes
    ; );
    push [ebp + 8 + (4 * 3)] ; push number of bytes to allocate
    add dword ptr [esp], 8  ; extra space needed for next node and node size
    push 0 ; no flags. no thrown exceptions. only null return on fail
    push eax ; push handle
    call _HeapAlloc@12

    cmp eax, 0
    je _failed ; null returned, allocation failed

    push eax ; save allocated memory address
    mov edx, [ebp + 8 + (4 * 3)] ; move data length into edx
    mov dword ptr [eax + 4], edx  ; save data length
    mov dword ptr [eax], 0  ; clear next node pointer

; copy contents into allocated memory:
    ; https://learn.microsoft.com/en-us/windows/win32/devnotes/rtlmovememory
    ; VOID RtlMoveMemory(
    ;   _Out_       VOID UNALIGNED *Destination,
    ;   _In_  const VOID UNALIGNED *Source,
    ;   _In_        SIZE_T         Length
    ; );
    push [ebp + 8 + (4 * 3)] ; fourth param, data length
    push [ebp + 8 + (4 * 2)] ; third param, *data
    push eax ; allocated memory ptr
    add dword ptr [esp], 8 ; offset: [next_node_ptr(4-bytes)][node_length(4-bytes)][node_data(node_length-bytes)]
    call _RtlMoveMemory@12

    mov ecx, 0 ; set counter register

    ; lea edx, [ebp + 8 + (4 * 0)] ; moves the address of this pointer
    mov edx, [ebp + 8 + (4 * 0)] ; moves this pointer

_search_node_start:
    cmp ecx, [ebp + 8 + (4 * 1)] ; compare with node index
    jae _search_node_end
    cmp dword ptr [edx], 0 ; check pointer of this->nextNode
    je _search_node_end 

    mov edx, [edx] ; get next node pointer and check again
    inc ecx

    jmp _search_node_start


_search_node_end:
    ; edx holds target base-node
    pop eax ; retrieve allocated memory address

    ; relink linked-list:
    mov ecx, [edx]
    mov dword ptr [eax], ecx ; store next-node into new node
    mov [edx], eax ; store new-node address into previous node
    mov eax, 1 ; set return value to success
    jmp _exit

_failed:
    mov eax, 0
    jmp _exit

_exit:
    pop ebp
    ret 16 
linkedList@addNode@16 endp

; add a node with null-terminated string in the linked list at specified index
; simplifies the process of storing string
; If inputted index exceeds the number of nodes in the chain by more than 1,
; the new node will simply be added at the very end
;
; linkedList@addNodeStr@12(* this, index, * char)
; returns 0 failed, 1 success
linkedList@addNodeStr@12 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    push [ebp + 8 + (4 * 2)] ; push string add to stack
    call util@charCount@4
    inc eax ; include null terminator

    ; linkedList@addNode@16(* this, index, * data, dataLength)
    push eax
    push [ebp + 8 + (4 * 2)]
    push [ebp + 8 + (4 * 1)]
    push [ebp + 8 + (4 * 0)]
    call linkedList@addNode@16

_exit:
    pop ebp
    ret 12 
linkedList@addNodeStr@12 endp

; delete node in the linked list at specified index
; if index is invalid, will return without error
;
; linkedList@deleteNode@8(* this, index)
; returns void
linkedList@deleteNode@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer
    
    mov ecx, 0 ; set counter register

    mov edx, [ebp + 8 + (4 * 0)] ; moves this pointer

_search_node_start:
    cmp ecx, [ebp + 8 + (4 * 1)] ; compare with node index
    jae _search_node_end
    cmp dword ptr [edx], 0 ; check pointer of this->nextNode
    je _search_node_end 

    mov edx, [edx] ; get next node pointer and check again
    inc ecx

    jmp _search_node_start


_search_node_end:
    cmp dword ptr [edx], 0
    je _fail

    mov ecx, edx ; ecx now has address of node before target delete node
    mov edx, [edx] ; edx now has address of target delete node
    mov eax, [edx] ; eax now has address of node after target delete node
    mov [ecx], eax ; relink nodes
    
; delete edx:
    push edx ; push ahead of time to not loose pointer
    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-getprocessheap
    ; HANDLE GetProcessHeap();
    call _GetProcessHeap@0

    ; https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapfree
    ; BOOL HeapFree(
    ;   [in] HANDLE                 hHeap,
    ;   [in] DWORD                  dwFlags,
    ;   [in] _Frees_ptr_opt_ LPVOID lpMem
    ; );
    ; edx already pushed
    push 0
    push eax ; push handler
    call _HeapFree@12
    jmp _exit

_fail:
    mov eax, 0

_exit:
    pop ebp
    ret 8
linkedList@deleteNode@8 endp

; get pointer to node data
;
; linkedList@getNodeData@8(* this, index)
; returns pointer to node data. null if node doesn't exist
linkedList@getNodeData@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov ecx, 0 ; set counter register

    mov edx, [ebp + 8 + (4 * 0)] ; moves this pointer

_search_node_start:
    cmp ecx, [ebp + 8 + (4 * 1)] ; compare with node index
    jae _search_node_end
    cmp dword ptr [edx], 0 ; check pointer of this->nextNode
    je _search_node_end 

    mov edx, [edx] ; get next node pointer and check again
    inc ecx

    jmp _search_node_start


_search_node_end:
    cmp dword ptr [edx], 0
    je _fail

    mov edx, [edx]
    lea eax, [edx + 8]  ; get effective address of target node data
    jmp _exit

_fail:
    mov eax, 0

_exit:
    pop ebp
    ret 8
linkedList@getNodeData@8 endp

; get node size (data bytes)
;
; linkedList@getNodeSize@8(* this, index)
; returns node data byte count.
; if the node doesn't exist, 0 will be returned as default. however, a node can be 0 bytes long.
; Check 'getNodeData' to see if node exists
linkedList@getNodeSize@8 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov ecx, 0 ; set counter register

    mov edx, [ebp + 8 + (4 * 0)] ; moves this pointer

_search_node_start:
    cmp ecx, [ebp + 8 + (4 * 1)] ; compare with node index
    jae _search_node_end
    cmp dword ptr [edx], 0 ; check pointer of this->nextNode
    je _search_node_end 

    mov edx, [edx] ; get next node pointer and check again
    inc ecx

    jmp _search_node_start


_search_node_end:
    cmp dword ptr [edx], 0
    je _fail

    mov edx, [edx]
    mov eax, [edx + 4]  ; get target node size
    jmp _exit

_fail:
    mov eax, 0

_exit:
    pop ebp
    ret 8
linkedList@getNodeSize@8 endp

; get total number of nodes on linked list.
;
; linkedList@nodeCount@4(* this)
; returns >=0 number of nodes on linked list
linkedList@nodeCount@4 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    mov eax, 0 ; counter and return value

    mov edx, [ebp + 8 + (4 * 0)] ; moves this pointer
_count_node_start:
    cmp dword ptr [edx], 0 ; check pointer of this->nextNode
    je _exit

    mov edx, [edx] ; get next node pointer and check again
    inc eax
    jmp _count_node_start

_exit:
    pop ebp
    ret 4
linkedList@nodeCount@4 endp

; take a linked-list object and print content
; print_linkedList@4(*this)
; return void
linkedList@print_linkedList@4 proc near
    ; get base pointer
    push ebp
    mov ebp, esp
    
    print_str "Linked List ("
    ; linkedList@nodeCount@4(* this)
    ; returns >=0 number of nodes on linked list
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@nodeCount@4
    push eax    ; store node count
    print_int eax
    
    println_str "):"

    push ebx
    mov ebx, 0

_start_loop:
    cmp ebx, [ebp - 4] ; compare with number of nodes in list
    jge _end_loop

    print_str "node "
    print_int ebx
    print_str " ("

    ; linkedList@getNodeSize@8(* this, index)
    ; returns node data byte count.
    push ebx ; node index
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@getNodeSize@8

    push eax ; store size
    sub esp, 4 ; allocate slot for data pointer
    push eax ; store size for another operation
    print_int eax   ; node size in bytes
    print_str "-bytes): "
    
    ;;;;; print node data as string:
    ; linkedList@getNodeData@8(* this, index)
    ; returns pointer to node data. null if node doesn't exist
    push ebx ; push current index
    push [ebp + 8] ; push instance pointer to ll
    call linkedList@getNodeData@8
    
    cmp eax, 0
    je _null_node
    
    mov [ebp - 16], eax ; for data printing loop
    push eax ; for string write
    
    print_array_b 022h ; quote mark
    ; we don't actually know if this data is a valid string so using writeLine
    ; writeLine@8(* data, dataLength) ; both already pushed
    ; returns void
    call writeLine@8  ; both *data and dataLength are on stack
    print_array_b 022h ; quote mark
    print_str " {"

    ; loop preparation:
    mov ecx, 0 ; loop counter
    _print_arr_loop_start:
        cmp ecx, [ebp - 12] ; compare with saved dataLength
        jae _print_arr_loop_end
        push ecx ; save counter


        mov eax, [ebp - 16] ; get data pointer
        mov eax, [eax + ecx]
        and eax, 0FFh       ; Keep only the lower 8 bits, clear upper 24 bits
        print_int eax


        pop ecx ; restore counter
        inc ecx

        cmp ecx, [ebp - 12]
        jb _print_comma
        jmp _print_arr_loop_start

            _print_comma:
                push ecx
                print_str ", "
                pop ecx
                jmp  _print_arr_loop_start
        
    _print_arr_loop_end:

    add esp, 8   ; pop data size and data pointer
    
    println_str "}"

    inc ebx
    jmp _start_loop

_null_node:
    add esp, 12 ; pop both node sizes and data pointer
    println_str "null"
    inc ebx
    jmp _start_loop

_end_loop:
    pop ebx
    add esp, 4 ; pop eax
    jmp _exit

_exit:
    println_str
    pop ebp
    ret 4
linkedList@print_linkedList@4 endp

end