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
section .rodata use64
    zero                equ     0x0
    query               db      "What is your name?",0xd,0xa
    querylen            equ     $-query
    greet               db      "Welcome, "
    greetlen            equ     $-greet
    errmsg              db      "No errors to report!",0xd,0xa
    errmsglen           equ     $-errmsg
    crlf                db      0xd,0xa
    crlflen             equ     $-crlf
    bNamelim            equ     0xff
    STD_INPUT_HANDLE    equ     -10
    STD_OUTPUT_HANDLE   equ     -11
    STD_ERROR_HANDLE    equ     -12

;Uninitialised data
section .bss use64
    argc        resq    0x1
    argv        resq    0x1
    envp        resq    0x1
    hStdInput   resq    0x1
    hStdOutput  resq    0x1
    hStdError   resq    0x1
    hNum        resq    0x1
    hMode       resq    0x1
    bName       resb    0x100
    bNamelen    resq    0x1

;Program code
section .text use64
main:
.prolog:
    mov qword [argc], rcx
.argc:
    mov qword [argv], rdx
.argv:
    mov qword [envp], r8
.envp:
    add rsp, 0x8*0x4+0x8
.rsp:

.body:
    mov rcx, qword STD_INPUT_HANDLE
    call GetStdHandle
    mov qword [hStdInput], rax

    mov rcx, qword STD_OUTPUT_HANDLE
    call GetStdHandle
    mov qword [hStdOutput], rax

    mov rcx, qword STD_ERROR_HANDLE
    call GetStdHandle
    mov qword [hStdError], rax

    mov rcx, qword [hStdOutput]
    mov rdx, qword query
    mov r8d, dword querylen
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile

    mov rcx, qword [hStdInput]
    mov rdx, qword bName
    mov r8d, dword bNamelim
    mov r9, qword bNamelen
    mov qword [rsp+0x20], zero
    call ReadFile

    mov rcx, qword [hStdOutput]
    mov rdx, qword crlf
    mov r8d, dword crlflen
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile

    mov rcx, qword [hStdOutput]
    mov rdx, qword greet
    mov r8d, dword greetlen
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile

    mov rcx, qword [hStdOutput]
    mov rdx, qword bName
    mov r8d, dword [bNamelen]
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile

    mov rcx, qword [hStdOutput]
    mov rdx, qword crlf
    mov r8d, dword crlflen
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile
    
    mov rcx, qword [hStdError]
    mov rdx, qword errmsg
    mov r8d, dword errmsglen
    mov r9, qword hNum
    mov qword [rsp+0x20], zero
    call WriteFile

    xor ecx, ecx;
    call ExitProcess

    xor eax, eax;
.epilog:
    sub rsp, 0x8*0x4+0x8
    ret
.end:

; Windows API x64 Structured Exception Handling - procedure data
section .pdata  rdata align=4 use64
    pmain:
    .start: dd      main     wrt ..imagebase 
    .end:   dd      main.end wrt ..imagebase 
    .info:  dd      xmain    wrt ..imagebase 

; Windows API x64 Structured Exception Handling - unwind information
section .xdata  rdata align=8 use64
    xmain:
    .versionandflags:
            db      0x1 << 0x5 + 0x0 ; Version = 1, UNW_FLAG_NHANDLER flag
    .size:  db      main.body-main.prolog ; size of prolog that is
    .count: db      0x1 ; Only one unwind code-saving volatiles isn't unwound
    .frame: db      0x0 ; Zero if no frame pointer taken
    .codes: db      main.rsp-main.prolog ; offset of next instruction
            db      0x24 ; UWOP_ALLOC_SMALL with 4*8+8 bytes
            db      0x0,0x0 ; Unused record to bring the number to be even