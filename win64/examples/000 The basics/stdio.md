# Standard Input Output Error

In Hello World we used the standard output to write to the console. But how about some code that shows off how to not only write to the console, but also how to ask the user for data. And what happens if we output to Standard Error?

```Assembly
; implementation defined structure exception info
; "%ASMROOT%\win64\examples\000 The Basics\stdio.asm"
;
; for compilation with the NASM assembler
;
; nasm -o stdio.obj -l stdio.lst -f win64 stdio.asm
; golink /console /ni /entry main stdio.obj kernel32.dll user32.dll gdi32.dll msvcrt.dll comctl32.dll comdlg32.dll oleaut32.dll hhctrl.ocx winspool.drv shell32.dll
;
; For normal ports mapping, just run:
;
; stdio.exe
;
; For mapping a file to each of the input, output and error ports:
;
; stdio.exe < input.file > output.file 2> error.file
;

;Image setup
bits 64
default rel
global main

;Linkage
extern GetStdHandle
extern WriteFile
extern ReadFile
extern ExitProcess
```

The preamble for the program is pretty much identical to the Hello World program. The only addition is that we need to not only write, but also read from console, so we need to import the Win64 procedure `ReadFile` from kernel32.dll.

```Assembly
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
```

This time we need to define a few other messages. We need to ask the user of the program for input, so we need to write a request to standard output. Then we need to read from standard input what has been entered, and we need to show that we've read it right, so we write it out to standard output again. Finally we need to write to the standard error to show that works too. All this writing needs strings to write, so we define them here in the read only data segment, `.rdata`. We also need to, in addition to our `STD_OUTPUT_HANDLE` from Hellow World, also have constants for the other two ports we'll be using, `STD_INPUT_HANDLE` and `STD_ERROR_HANDLE`. Another new constant we need is a constant for the maximum length to read from standard input when we request input from the user, `bNamelim`.

```Assembly
;Uninitialised data
section .bss use64
    hStdInput:  resq    0x1
    hStdOutput: resq    0x1
    hStdError:  resq    0x1
    hNum:       resq    0x1
    bName:      resb    0x100
    bNamelen:   resq    0x1
```

Like in Hello World, we want to store the handle to the standard output port somewhere, and `hStdOutput` is that place. It's placed in the `.bss` section as that is where we place uninitialised stuff that we want to fill in as the program runs. In addition to that, we of course need two other ports, `hStdInput` and `hStdError` as well this time.

We also want to store the string we're going to read from standard input somewhere, so we reserve a 256 byte large area to place it, `bName`, as well as a place to store the actual length of the string as it got read, ´bNamelen´.

```Assembly
;Program code
section .text use64
main:
.prolog:
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

        ; return 0
.rval:  xor eax, eax
.epilog: ; Undoes the prolog in reverse order.
        add rsp, 0x8*0x4+0x8
        ret
.end:
```

The body of the program this time calls `GetStdHandle` three times, once for each port, and then we start our sequence of reads and writes as required for the program. Of note here, is that we have a few subtle differences at some places. The call to `ReadFile` looks very similar to our calls to `WriteFile`, but we need to use the fourth argument to `ReadFile` (the address of the place where `ReadFile` stores the number of bytes actually read) after `hNum` has been overwritten by a subsequent call to `WriteFile`, so we need for this call use a different address - that of `bNamelen` - instead of the address of `hNum`.

The other place where our code looks different is in the call to `WriteFile` where we use `bName`. All our other calls, our third argument has been a compile time constant that is encoded by the assembler as an immediate value to the `mov` instruction that moves it into register `r8d`. `bNamelen` is an address to where to find the length, not the actual length. So we need to dereference that address into the value that is stored in it - the assembler needs to input it not as an immediate value, but as a memory reference. This is the reason for the braces in `mov r8d, dword [bNamelen]`. 

```Assembly
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
```

And the Structured Exception Handling and Stack Unwind segments looks identical to those of Hello World.
