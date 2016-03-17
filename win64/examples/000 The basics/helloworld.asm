; "%ASMROOT%\win64\examples\000 The Basics\helloworld.asm"
;
; for compilation with the NASM assembler
;
; nasm -o helloworld.obj -l helloworld.lst -f win64 helloworld.asm
; golink /console /ni /entry main helloworld.obj kernel32.dll user32.dll gdi32.dll msvcrt.dll comctl32.dll comdlg32.dll oleaut32.dll hhctrl.ocx winspool.drv shell32.dll

;Image setup
bits 64
default rel
global main

;Linkage
extern GetStdHandle     ;   From kernel32.dll
extern WriteFile        ;   From kernel32.dll
extern ExitProcess      ;   From kernel32.dll

section .data use64
    msg:                db      "Hello World!",0xd,0xa
    msglen:             equ     $-msg
    zero:               equ     0x0
    STD_OUTPUT_HANDLE:  equ     -11

section .bss use64
    hStdOutput  resq    1
    hNum        resq    1

section .text use64
main: ; int main(int argc, char *argv[], char *envp[])
.prolog:
    sub rsp, 0x30
.body:
    ; *hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov qword [hStdOutput], rax
    
    ; WriteFile(*hStdOutput, *msg, msglen, *hNum, NULL)
    mov rcx, qword [hStdOutput]
    mov rdx, msg
    mov r8d, msglen ; r8d instead of r8 since zero extension workd for us
    mov r9, hNum
    mov qword[rsp+0x20],zero ; fifth argument and on are passed on the stack
    call WriteFile

    ; ExitProcess ( 0 )
    mov ecx, zero ; ecx instead of rcx since zero extension works for us
    call ExitProcess

    ; return 0
    xor eax, eax
.epilog:
    add rsp, 0x30
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
            db      0x1 << 0x5 + 0x0 ; Version = 1, UNW_FLAG_NHANDLER flag
    .size:  db      main.prolog-main.body ; size of prolog that is
    .count: db      0x1 ; Only one unwind code-saving volatiles isn't unwound
    .frame: db      0x0 ; Zero if no frame pointer taken
    .codes: db      main.body-main.prolog ; offset of next instruction
            db      0x25 ; UWOP_ALLOC_SMALL with 5*8+8 bytes=48=0x30
            db      0x0,0x0 ; Unused record to bring the number to be even