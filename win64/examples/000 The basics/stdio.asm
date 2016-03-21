; implementation defined structure exception info
; "%ASMROOT%\win64\examples\000 The Basics\stdio.asm"
;
; for compilation with the NASM assembler
;
; nasm -o stdio.obj -l stdio.lst -f win64 stdio.asm
; golink /console /ni /entry main stdio.obj kernel32.dll user32.dll gdi32.dll msvcrt.dll comctl32.dll comdlg32.dll oleaut32.dll hhctrl.ocx winspool.drv shell32.dll

;Image setup
bits 64
default rel
global main

;Linkage
extern GetStdHandle
extern WriteFile
extern ReadFile
extern ExitProcess

;Read only data
section .rdata use64
    zero:                   equ     0x0
    query:                  db      "What is your name?",0xd,0xa
    querylen:               equ     $-query
    greet:                  db      "Welcome, "
    greetlen:               equ     $-greet
    errmsg:                 db      "No errors to report!",0xd,0xa
    errmsglen:              equ     $-errmsg
    crlf:                   db      0xd,0xa
    crlflen:                equ     $-crlf
    bNamelim:               equ     0xff
    STD_INPUT_HANDLE:       equ     -10
    STD_OUTPUT_HANDLE:      equ     -11
    STD_ERROR_HANDLE:       equ     -12
    UNW_VERSION:            equ     0x1
    UNW_FLAG_NHANDLER:      equ     0x0
    UNW_FLAG_EHANDLER:      equ     0x1
    UNW_FLAG_UHANDLER:      equ     0x2
    UNW_FLAG_CHAININFO:     equ     0x4
    UWOP_PUSH_NONVOL:       equ     0x0
    UWOP_ALLOC_LARGE:       equ     0x1
    UWOP_ALLOC_SMALL:       equ     0x2
    UWOP_SET_FPREG:         equ     0x3
    UWOP_SAVE_NONVOL:       equ     0x4
    UWOP_SAVE_NONVOL_FAR:   equ     0x5
    UWOP_SAVE_XMM128:       equ     0x8
    UWOP_SAVE_XMM128_FAR:   equ     0x9
    UWOP_PUSH_MACHFRAME:    equ     0xa

;Uninitialised data
section .bss use64
    argc:       resq    0x1
    argv:       resq    0x1
    envp:       resq    0x1
    hStdInput:  resq    0x1
    hStdOutput: resq    0x1
    hStdError:  resq    0x1
    hNum:       resq    0x1
    hMode:      resq    0x1
    bName:      resb    0x100
    bNamelen:   resq    0x1

;Program code
section .text use64
main:
.prolog:
.argc:    mov qword [argc], rcx
.argv:    mov qword [argv], rdx
.envp:    mov qword [envp], r8
.rsp:     sub rsp, 0x8*0x4+0x8

.body:
        ; hStdInput = GetStdHandle (STD_INPUT_HANDLE)
        mov rcx, qword STD_INPUT_HANDLE
        call GetStdHandle
        mov qword [hStdInput], rax

        ; hStdOutput = GetStdHandle (STD_OUTPUT_HANDLE)
        mov rcx, qword STD_OUTPUT_HANDLE
        call GetStdHandle
        mov qword [hStdOutput], rax

        ; hStdError = GetStdHandle (STD_ERROR_HANDLE)
        mov rcx, qword STD_ERROR_HANDLE
        call GetStdHandle
        mov qword [hStdError], rax

        ; WriteFile (*hStdOutput, &query, querylen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword query
        mov r8d, dword querylen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; ReadFile (*hStdInput, &bName, bNamelim, &bNameLen, NULL)
        mov rcx, qword [hStdInput]
        mov rdx, qword bName
        mov r8d, dword bNamelim
        mov r9, qword bNamelen
        mov qword [rsp+0x20], zero
        call ReadFile

        ; WriteFile (*hStdOutput, &crlf, crlflen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword crlf
        mov r8d, dword crlflen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; WriteFile (*hStdOutput, &greet, greetlen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword greet
        mov r8d, dword greetlen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; WriteFile (*hStdOutput, &bName, *bNamelen, &hNum, NULL)
        mov rcx, qword [hStdOutput]
        mov rdx, qword bName
        mov r8d, dword [bNamelen]
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
        
        ; WriteFile (*hStdError, &errmsg, errmsglen, &hNum, NULL)
        mov rcx, qword [hStdError]
        mov rdx, qword errmsg
        mov r8d, dword errmsglen
        mov r9, qword hNum
        mov qword [rsp+0x20], zero
        call WriteFile

        ; ExitProcess(0)
.exit:  xor ecx, ecx
        call ExitProcess

.rval:  xor eax, eax ; return 0
.epilog:
        add rsp, 0x8*0x4+0x8
        ret
.end:

; Win64 Windows API x64 Structured Exception Handling (SEH) - procedure data
section .pdata  rdata align=4 use64
    pmain:
    .start: dd      main     wrt ..imagebase 
    .end:   dd      main.end wrt ..imagebase 
    .info:  dd      xmain    wrt ..imagebase 

; Win64 Windows API x64 Structured Exception Handling (SEH) - unwind information
section .xdata  rdata align=8 use64
    xmain:
    .versionandflags:
            db      UNW_VERSION + (UNW_FLAG_NHANDLER << 0x3) ; Version = 1
    ; Version is low 3 bits. Handler flags are high 5 bits.
    .size:  db      main.body-main.prolog ; size of prolog that is
    .count: db      0x1 ; Only one unwind code
    .frame: db      0x0 + (0x0 << 0x4) ; Zero if no frame pointer taken
    ; Frame register is low 4 bits, Frame register offset is high 4 bits,
    ; rsp + 16 * offset at time of establishing
    .codes: db      main.body-main.prolog ; offset of next instruction
            db      UWOP_ALLOC_SMALL + (0x4 << 0x4) ; UWOP_INFO: 4*8+8 bytes
    ; Low 4 bytes UWOP, high 4 bytes op info.
    ; Some ops use one or two 16 bit slots more for addressing here
            db      0x0,0x0 ; Unused record to bring the number to be even
    .handl: ; 32 bit image relative address to entry of exception handler
    .einfo: ; implementation defined structure exception info