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

section .rdata use64
    msg:                db      "Hello World!",0xd,0xa
    msglen:             equ     $-msg
    zero:               equ     0x0
    STD_OUTPUT_HANDLE:  equ     -11
    UNW_VERSION:        equ     0x1
    UNW_FLAG_NHANDLER:  equ     0x0
    UNW_FLAG_EHANDLER:  equ     0x1
    UNW_FLAG_UHANDLER:  equ     0x2
    UNW_FLAG_CHAININFO: equ     0x4
    UWOP_PUSH_NONVOL:   equ     0x0
    UWOP_ALLOC_LARGE:   equ     0x1
    UWOP_ALLOC_SMALL:   equ     0x2
    UWOP_SET_FPREG:     equ     0x3
    UWOP_SAVE_NONVOL:   equ     0x4
    UWOP_SAVE_NONVOL_FAR:equ    0x5
    UWOP_SAVE_XMM128:   equ     0x8
    UWOP_SAVE_XMM128_FAR:equ    0x9
    UWOP_PUSH_MACHFRAME:equ     0xa
  
section .bss use64
    hStdOutput  resq    0x1
    hNum        resq    0x1

section .text use64
main: ; int main(int argc, char *argv[], char *envp[])
.prolog:
    sub rsp, 0x8*0x4+0x8 ; register spill 4 * 8 + highest stack argument number
    ; need to be an odd number of 8 byte adds, +rip makes it align at 16 bytes
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
    mov qword [rsp+0x20], zero ; fifth argument and on are passed on the stack
    call WriteFile

    ; ExitProcess ( 0 )
    mov ecx, zero ; ecx instead of rcx since zero extension works for us
    call ExitProcess

    ; return 0
    xor eax, eax
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