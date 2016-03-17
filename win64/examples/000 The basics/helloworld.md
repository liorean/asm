# Hello World

It has become tradition to start off your programming learning with writing a simple program that outputs the text `Hello World!` in some way. In x64 assembly for Windows, you have a couple of choices to make first: are you making a console program or a windowed program, and are you going to go through the C runtime libraries, or are you going to go directly to the Win64 APIs?

In my path to learning assembly, I chose console and Win64 for a start. After a few false starts, I eventually found NASMX, and began coding my Hello World program using that. I'll not use that program here though, for reasons that I will discuss later. Instead, let's start and look at the how the final version of the file looks.

```Assembly
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
```

By "Image" is here meant the executable in memory. The `bits 64` part specifies that we should be generating x64 assembly and not x86, though the "-f win64" in the command line parameters to NASM implies that too. The `default rel` directive tells the assembler to generate relative addresses instead of absolute. And `global main` makes the `main` procedure available from outside this module. For example as the entry point as specified by the "/entry main" command line parameter to GoLink.

```Assembly
;Linkage
extern GetStdHandle     ;   From kernel32.dll
extern WriteFile        ;   From kernel32.dll
extern ExitProcess      ;   From kernel32.dll
```

The `extern` directive makes these three procedures available from other sources. In our case, the linker will link them with the procedures with the same label in the kernel32.dll library that is core to the Win32/Win64 API.

```Assembly
section .data use64
    msg:                db      "Hello World!",0xd,0xa
    msglen:             equ     $-msg
    zero:               equ     0x0
    STD_OUTPUT_HANDLE:  equ     -11

section .bss use64
    hStdOutput: resq    1
    hNum:       resq    1
```

In an executable image, we don't just have the executable code, we also have data segments. In the `.data` segment, we have initialised data. In this case one piece of data, `msg`, which is a sequence of data of the size byte, whence `db`. There's also three compile time constants there, `msglen` which calculates the location in bytes of its own position subtracted by the location of `msg`, there's `zero` which is numerical zero, and there's `STD_OUTPUT_HANDLE` which is a constant we'll need to retrieve a handle to the standard out from the kernel.

In the `.bss` segment we have uninitialised data, in other words containers with no content at compile time, but reserving space that the program can fill. In this case, the `hStdOutput` label is reserved (`res`) for a single quad (`q`) word (4 words, or 8 bytes, or 64 bits) which is the size of a memory address in 64 bit mode, which we'll fill with the address to the actual standard out. The `hNum` label is likewise reserved for a single quad word, but that single quad word will be used as a number and not a memory address.

```Assembly
section .text use64
main: ; int main(int argc, char *argv[], char *envp[])
.prolog:
    sub rsp, 0x8*0x4+0x8 ; 4 register spill * 8 bytes + 8 byte stack argument
    ; if you add 8 bytes for the return pointer on stack, that is 0x30 which
    ; aligns on 16 bytes which is required for non-leaf procedures.
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
.epilog: ; undo prolog in reverse order in the epilog
    add rsp, 0x8*0x4+0x8
    ret
.end:
```

Despite its deceptive name, the `.text` segment actually contains the actual programming instructions and not text. First in this segment we see a label, `main`, which as you might recall is both a name we've declared `global` earlier, and the entry point we on the command line specify to our linker. When the program executes, this is where the kernel program loading will turn execution to when passing control on to our program. Next comes a line declaring a sublabel, `main.prolog`, that isn't strictly necessary but that I like to have for aesthetical reasons. Then we see the first actual instruction of our hello world program.

In Windows programming, the stack is extended downward, so what `sub rsp, 0x8*0x4+0x8` does is allocate a space of five bytes on the stack. The Win64 ABI (application binary interface) doesn't just specify how functions should be called, where arguments are placed, but also specific structure for exactly what is allowed to go in the prolog, body and epilog part of a procedure, as well as what order it has to go in. It also specifies exception handling and stack unwinding. Not only must saving of nonvolatile registers and every stack operation that goes on in the prolog be undone in reverse order in the epilog, but it must also be registred in the procedure data and unwinding data segments so the structured exception handling mechanism of Windows can unwind the stack and/or turn control over to exception handlers that are registred. So, in other words, there's more to what happens in the prolog than is readily apparent.

So, why did the prolog contain that `sub rsp, 0x8*0x4+0x8` anyway? Well, the calling conventions of Win64 passes the first four arguments to any procedure in the registers `rcx, rdx, r8 r9`, but also requires the caller of any procedure to reserve room for at least that many arguments on the stack. So the stack of any procedure that calls other procedures need to reserve at least that much on the stack. Win64 ABI also specifies that any arguments more than those first four are passed on the stack, so we have to allocate a further 8 bytes for the fifth argument that we send in our longest procedure call, that to `WriteFile`. The stack pointer in Win64 needs to align on a 16 byte boundary, so we need to make sure that we do that. As the call to our function places the return address on the stack, that's 8 bytes, we need 8 bytes for that fifth stack argument on our longest function call, and we need to reserve 32 bytes for our four calling convention register whether they're needed or not. That becomes a minimum of 48 bytes reserved, and  of those 8 bytes are already on our stack as of our function being called. In other words, the prolog needs to subtract an odd number of 8 byte multipliers from the stack pointer `rsp` and that number needs to be at least 4 because of the requirement to provide register spill space for any called functions, so the least number of bytes we can subtract is 5, which is exactly as many bytes as we need for our most parameter abundant procedure call.

If we then proceed past the prolog, which ends with just that instruction in it, we come to the part of the program which actually does something useful. Before we can write our `Hello World!` string to the console, we need to grab a handle to the standard output, and to do that, we need to call into the Win64 API - in kernel32.dll there is a procedure called `GetStdHandle` that takes a single argument, a constant representing which standard input/output handle we're interested in, which we have stored in ´STD_OUTPUT_HANDLE´. To send a single argument to a procedure in the Win64 ABI, we need to place it in the first argument register, ´rcx´, thus which we do with the `mov rcx, STD_OUTPUT_HANDLE` instruction. Then we need to call the `GetStdHandle` procedure using the `call GetStdHandle` instruction. That function will give us a return value in the `rax` register, which will contain a handle for that device. That handle we will store in the `.bss` data area we already have reserved for it, with the label `hStdOutput`, using the `mov qword [hStdOutput], rax` instruction. Had this been an example more demanding robustness from us, we could have checked the return value and handle eventual errors here, but as it's just a first example weäll skip that for now. Also, note that we didn't have to save it to a data area at all, we only need it once in the next instruction, so we could easily have just done a ´mov rcx, rax´ and done away with `hStdOutput` entirely.

Following us getting the handle, we can try to write to it. This can be done using several different Win64 APIs, but the one that is most general is probably `WriteFile`, so that is what we will do. `Writefile` takes a handle as it's first argument, so we use `mov rcx, qword [hStdOutput]` to get our device to it. Second argument is a pointer to a buffer containing a string, this one we send the address of `msg` to using `mov rdx, msg`. Third argument is a `DWORD` length of that string, which we send as `mov r8d, msglen`. Fourth argument is an address to somewhere that `WriteFile` can store how many characters it actually printed, this we send using `mov r9, hNum`. Finally, ´WriteFile´ takes a fifth, optional argument that we send `NULL` to, which is different from our earlier argument passings in that we need to place it on the stack for ´Writefile` to grab if needed. Since we have made place for it on our stack already, we can just move it there using `mov qword [rsp+0x20], zero`. Finally we call the procedure using `call WriteFile` and promptly neglect to make this procedure call any more robust than our last one.

Wrapping up our procedure body, we place 0 as argument to `Exitprocess` using `mov ecx, zero` which zero extends `ecx` into `rcx` while being a shorter bit of machine code than `mov rcx, rcx` (though not as short as `xor ecx, ecx` would have been),  we set our return value register `rax` to zero using `xor eax, eax`, and we enter the epilog code.

The epilog has to reset the stack frame and if we had used any nonvolatile registers, undo whatever nonvolatile register overwriting our procedure has done, in reverse order of it happening, which in our case becomes a simple stack frame restoration ´add rsp, 0x8*0x4+0x8´ and then return, ´ret´.

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
            db      0x1 << 0x5 + 0x0 ; Version = 1, UNW_FLAG_NHANDLER flag
    .size:  db      main.body-main.prolog ; size of prolog that is
    .count: db      0x1 ; Only one unwind code
    .frame: db      0x0 ; Zero if no frame pointer taken
    .codes: db      main.body-main.prolog ; offset of next instruction
            db      0x24 ; UWOP_ALLOC_SMALL with 4*8+8 bytes
            db      0x0,0x0 ; Unused record to bring the number to be even
```

Once that is done, our executable is practically finished. We just need the last few components to make it conform to the Win64 ABI: we have a single frame procedure, `main`, which needs a corresponding entry in the `.pdata` section following the structure of [struct RUNTIME_FUNCTION](https://msdn.microsoft.com/en-us/library/ft9x1kdx.aspx). Basically this record needs to contain, for each frame procedure, an image relative 32-bit address to it's entry point, an image relative 32-bit address to just after its exit point, and an image relative 32-bit address to a [struct UNWIND_INFO](https://msdn.microsoft.com/en-us/library/ddssxxy8.aspx) representing that procedure's unwind information, where our simple procedure will have only a single entry of type [struct UNWIND_CODE](https://msdn.microsoft.com/en-us/library/ck9asaa9.aspx) representing what needs to be done to restore the stack frame, and neither termination handler, exception handler nor chained unwind info.
