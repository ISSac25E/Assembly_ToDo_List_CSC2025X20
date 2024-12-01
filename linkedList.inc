; linkedList@addNode@16(* this, index, * data, dataLength)
; returns 0 failed, 1 success
extern linkedList@addNode@16 : proc

; linkedList@addNode_empty@12(* this, index, nodeSize)
; returns 0 failed, 1 success
extern linkedList@addNode_empty@12 : proc

; linkedList@addNodeStr@12(* this, index, * char)
; returns 0 failed, 1 success
extern linkedList@addNodeStr@12 : proc

; linkedList@deleteNode@8(* this, index)
; returns void
extern linkedList@deleteNode@8 : proc

; linkedList@getNodeData@8(* this, index)
; returns pointer to node data. null if node doesn't exist
extern linkedList@getNodeData@8 : proc

; linkedList@getNodeSize@8(* this, index)
; returns node data byte count.
extern linkedList@getNodeSize@8 : proc

; linkedList@nodeCount@4(* this)
; returns >=0 number of nodes on linked list
extern linkedList@nodeCount@4 : proc

; linkedList@deinit@4(* this)
; returns void
extern linkedList@deInit@4 : proc

; print_linkedList@4(*this)
; return void
extern linkedList@print_linkedList@4 : proc

; linkedList@load@8(*this, *char)
; returns: error code
extern linkedList@load@8 : proc

; linkedList@store@8(*this, *char)
; returns: 0 failed, 1 success
extern linkedList@store@8 : proc


; macros dependency
; - include utility.inc

addNode_str macro ll_ptr, index, str:=<"">
endm

; addNode_array_b
; takes linkedList instance pointer, target index and byte array to store into node
; result stored in eax 
addNode_array_b macro ll_ptr, index, args:vararg
    push_array_b &args&

    argument_size = 0
    FOR arg, <args>
        argument_size = argument_size + 1
    endm

    ; linkedList@addNode@16(* this, index, * data, dataLength)
    ; returns 0 failed, 1 success
    push argument_size
    push esp
    add dword ptr [esp], 4
    push index
    push ll_ptr
    call linkedList@addNode@16

    push eax
    pop_array_b &args&
    pop eax
endm