;%USERPROFILE%\nasm\learning\arg.asm
;
;Basic usage of the standard input/output/error channels.
;
;nasm -f win64 arg.asm
;golink /console /ni /entry main arg.obj kernel32.dll

;Image setup
bits 64
default rel
global main

;Linkage
extern GetStdHandle
extern WriteFile
extern GetCommandLineW
extern ExitProcess

; Compile time constants that are aren't used in the program itself
    ; Win64 SEH & stack unwinding constants
    ;   UNWIND INFO
    UNW_VERSION:            equ     0x1 ;   Version of SEH handling ?
    UNW_FLAG_NHANDLER:      equ     0x0 ;   No exception or unwind handler flag
    UNW_FLAG_EHANDLER:      equ     0x1 ;   Exception handler flag
    UNW_FLAG_UHANDLER:      equ     0x2 ;   Unwind handler flag
    UNW_FLAG_CHAININFO:     equ     0x4 ;   Chained RUNTIME_FUNCTION flag
    ;   UNWIND_CODE
    UWOP_PUSH_NONVOL:       equ     0x0 ;   1 node. INFO=reg.
    UWOP_ALLOC_LARGE:       equ     0x1 ;   2-3 nodes. INFO=nodes0|1. Node=size.
    UWOP_ALLOC_SMALL:       equ     0x2 ;   1 node. INFO=bytes*8+8.
    UWOP_SET_FPREG:         equ     0x3 ;   1 node. INFO=reserved (0).
    UWOP_SAVE_NONVOL:       equ     0x4 ;   2 nodes. INFO=reg. Node=offset*8.
    UWOP_SAVE_NONVOL_FAR:   equ     0x5 ;   3 nodes. INFO=reg. Nodes=offset.
    UWOP_SAVE_XMM128:       equ     0x8 ;   2 nodes. INFO=xreg. Node=offset*16.
    UWOP_SAVE_XMM128_FAR:   equ     0x9 ;   3 nodes. INFO=xreg. Nodes=offset.
    UWOP_PUSH_MACHFRAME:    equ     0xa ;   1 node. INFO=error code present,0|1.
    ;   Win64 general usage register numbers
    REG_RAX:                equ     0x0     ;   Volatile over user calls
    REG_RCX:                equ     0x1     ;   Volatile over user calls
    REG_RDX:                equ     0x2     ;   Volatile over user calls
    REG_RBX:                equ     0x3     ;   Non-volatile
    REG_RSP:                equ     0x4     ;   Non-volatile
    REG_RBP:                equ     0x5     ;   Non-volatile
    REG_RSI:                equ     0x6     ;   Non-volatile
    REG_RDI:                equ     0x7     ;   Non-volatile
    REG_R8:                 equ     0x8     ;   Volatile over user calls
    REG_R9:                 equ     0x9     ;   Volatile over user calls
    REG_R10:                equ     0xa     ;   Volatile over kernel calls
    REG_R11:                equ     0xb     ;   Volatile over kernel calls
    REG_R12:                equ     0xc     ;   Non-volatile
    REG_R13:                equ     0xd     ;   Non-volatile
    REG_R14:                equ     0xe     ;   Non-volatile
    REG_R15:                equ     0xf     ;   Non-volatile

; Read-write data
section .data
    argslim:                dd  0xffff
    argslen:                dd  0x0
    args:   times 0x10000   db  0x0

;Read only data
section .rdata
    zero:               equ     0x0
    p0:                 db      "Program called as:",0xd,0xa,0x9
    p0len:              equ     $-p0
    p1:                 db      "Parameter "
    p1len:              equ     $-p1
    p2:                 db      ":",0xd,0xa,0x9
    p2len:              equ     $-p2
    p3:                 db      "Environment Variable "
    p3len:              equ     $-p3
    crlf:               db      0xd,0xa
    crlflen:            equ     $-crlf
    hexdigits:          db      "0123456789abcdef"
    STD_INPUT_HANDLE:   equ     -10
    STD_OUTPUT_HANDLE:  equ     -11
    STD_ERROR_HANDLE:   equ     -12
    misaligned:         equ     0xf
    aligned:            equ     0xfffffffffffffff0


;Uninitialised data
section .bss
        hStdOutput:         resq    0x1
        hNum:               resq    0x1
        cmdln:              resq    0x1


;Program code
section .text
main:
.prolog:
.rsi:   push rsi
.rdi:   push rdi
.rbx:   push rbx
.rbp:   push rbp
.rsp:   sub rsp, 0x8*0x4+0x8
.frame: mov rbp, rsp

.body:
        mov rdi, zero

        ; cmdln = GetCommandLineW ()
        call GetCommandLineW
        mov qword [cmdln], rax
        mov rsi, rax

        ; hStdOutput = GetStdHandle (STD_OUTPUT_HANDLE)
        mov rcx, qword STD_OUTPUT_HANDLE
        call GetStdHandle
        mov qword [hStdOutput], rax

.progname:
        ; WriteFile (*hStdOutput, &p0, p0len, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword p0
        mov r8d, dword p0len
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; strlen (cmdln)
        mov rcx, rsi
;        mov rdx, [rcx]
        call wstrlen

        ; WriteFile (*hStdOutput, argv[0], strlen(&argv[0]), &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, rsi
        mov r8d, eax
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; WriteFile (*hStdOutput, &crlf, crlflen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword crlf
        mov r8d, dword crlflen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        jmp .exit

.params:
        dec rbx
        jz .exit
;        inc rdi
        add rsi, 0x8

        ; WriteFile (*hStdOutput, &p1, p1len, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword p1
        mov r8d, dword p1len
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile
;;;;
;insert code to print number of param here
;;;;
        ; WriteFile (*hStdOutput, &p2, p2len, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword p2
        mov r8d, dword p2len
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; strlen (*argv)
        mov rcx, [rsi]
        call strlen

        ; WriteFile (*hStdOutput, argv[n], strlen(&argv[n]), &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, [rsi]
        mov r8d, eax
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; WriteFile (*hStdOutput, &crlf, crlflen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword crlf
        mov r8d, dword crlflen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        jmp .params

        ; ExitProcess (0)
.exit:  xor ecx, ecx
        call ExitProcess

        ; return 0
.return:xor eax, eax
.epilog:sub rsp, 0x8*0x4+0x8
        pop rbp
        pop rbx
        pop rdi
        pop rsi
        ret
.end:

; uint64 strlen (char *str)
; Win64 leaf procedure (uses no stack or nonvolatile registers)
strlen:
.prolog:
.body:
    .general:
        pxor xmm0, xmm0         ;   Null out xmm0
        mov rdx, rcx            ;   Copy address to rdx
        mov r8, rcx             ;   Copy address to r8
    .lead:
        and cl, misaligned      ;   Get size of eventual misalignment in cl
        and rdx, aligned        ;   Get aligned address in rdx
        movdqa xmm1, [rdx]      ;   Copy eventual misaligned portion into xmm1
        pcmpeqb xmm1, xmm0      ;   Compare xmm1 bytewise to nulls (in xmm0)
        pmovmskb eax, xmm1      ;   For xmm1 null bytes, set eax bits 0, else 1 
        shr eax, cl             ;   Shift out bits before string
        shl eax, cl             ;   Shift in zeroes
        bsf eax, eax            ;   Bitsearch for first 1 bit in eax
        jnz .calclen            ;   > 0 = end of string is within eax bytes
    .aligned:
        add rdx, 0x10           ;   Move vector frame 16-bit forward
        movdqa xmm1, [rdx]      ;   Move next 16 bytes into xmm1
        pcmpeqb xmm1, xmm0      ;   Compare xmm1 bytewise to nulls (in xmm0)
        pmovmskb eax, xmm1      ;   For xmm1 null bytes, set eax 0, else 1 bits
        bsf eax, eax            ;   Bitsearch for first 1 bit in eax
        jz .aligned             ;   > 0 = end of string is within eax bytes
    .calclen:
        sub rdx, r8             ;   Calc address range to start of last frame
        add rax, rdx            ;   Add number of nonzero bits in last frame
.epilog:ret
.end:

; uint64 strlen (uint16 *str)
; Win64 leaf procedure (uses no stack or nonvolatile registers)
; NOTE: Returns length in BYTES, not WORDS
wstrlen:
.prolog:
.body:
    .general:
        pxor xmm0, xmm0         ;   Null out xmm0
        mov rdx, rcx            ;   Copy address to rdx
        mov r8, rcx             ;   Copy address to r8
    .lead:
        and cl, misaligned      ;   Get size of eventual misalignment in cl
        and rdx, aligned        ;   Get aligned address in rdx
        movdqa xmm1, [rdx]      ;   Copy eventual misaligned portion into xmm1
        pcmpeqw xmm1, xmm0      ;   Compare xmm1 wordwise to nulls (in xmm0)
        pmovmskb eax, xmm1      ;   For xmm1 null bytes, set eax bits 0, else 1 
        shr eax, cl             ;   Shift out bits before string
        shl eax, cl             ;   Shift in zeroes
        bsf eax, eax            ;   Bitsearch for first 1 bit in eax
        jnz .calclen            ;   > 0 = end of string is within eax bytes
    .aligned:
        add rdx, 0x10           ;   Move vector frame 16-bit forward
        movdqa xmm1, [rdx]      ;   Move next 16 bytes into xmm1
        pcmpeqw xmm1, xmm0      ;   Compare xmm1 wordwise to nulls (in xmm0)
        pmovmskb eax, xmm1      ;   For xmm1 null bytes, set eax 0, else 1 bits
        bsf eax, eax            ;   Bitsearch for first 1 bit in eax
        jz .aligned             ;   > 0 = end of string is within eax bytes
    .calclen:
        sub rdx, r8             ;   Calc address range to start of last frame
        add rax, rdx            ;   Add number of nonzero bits in last frame
.epilog:ret
.end:
