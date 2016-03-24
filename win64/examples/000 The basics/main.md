# PE32+ entry point isn't C `int main(int argc, char *argv[], char *envp[])`!

Sometimes assumptions can really bite you. I've spent a long time trying to debug a couple of variants of a C `strlen` equivalent that I thought I was using on `argv` that simply did not work for me. My favoured debugger isn't Win64 enabled, so that involved a lot of trial and error. Eventually I had four versions of `strlen` that all worked, when I tried them on my hard coded strings in an `.rdata` segment. But they all gave me error code `c0000005` "ACCESS_VIOLATION". Eventually I bit the bullet and went in search of a 64 bit enabled debugger to replace OllyDbg for me. Once I had a debugger that worked for Win64 code, the location of the error always ended up being whatever code was dereferencing the assumed string. So I made a short version that did nothing but the dereferencing, and lo! there it was, the error could be reduced down to:

```Assembly
;"%ASMROOT%\win64\examples\000 The Basics\main.asm"
;
;PE32+ entry is not C main entry!
;
;nasm -f win64 -l main.lst main.asm
;golink /console /ni /entry main main.obj kernel32.dll

;Image setup
bits 64
default rel
global main

;Linkage
extern ExitProcess

;Program code
section .text
main: ; int main(int argc, char *argv[], char *envp[]);
.prolog:
.body:  mov rdx, [rdx]          ;   Dereference *argv[]
        mov rdx, [rdx]          ;   Dereference the dereference of *argv[] 
        mov r8, [r8]            ;   Dereference *envp[]
        mov r8, [r8]            ;   Dereference the dereference of *envp[] 
.exit:  xor ecx, ecx
        call ExitProcess
        xor eax, eax
.epilog:ret
.end:
```

Well, that's not very far from being the minimal assembly for a Win64 console mode executable. It definitely doesn't contain any part of my `strlen` procedure any longer. What line of it is causing the access violation error? Well, the debugger finds it at the second instruction, `        mov rdx, [rdx]          ;   Dereference the dereference of *argv[] `.

So, then comes the question of what those registers `rcx`, `rdx` and `r8` actually contain, since in a C `main`, we are guaranteed that `*argv[0]` will not cause an error. The debugger gives us this answer:

```Assembly
Register Contents: PID 0x2660 TID 0x266C at IP:0x00000000`00401000
  RAX: +00000000`776559E0 kernel32.dll!BaseThreadInitThunk
1 RCX: +000007FF`FFFD3000 Process Environment Block
2 RDX: +00000000`00401000 main.exe + 0x00001000
  RBX:  00000000`00000000
  RSP: +00000000`0012FF58 *0x266C Thread Stack Area RSP - 0x0000
  RBP:  00000000`00000000
  RSI:  00000000`00000000
  RDI:  00000000`00000000
3 R8:  +000007FF`FFFD3000 Process Environment Block
4 R9:  +00000000`00401000 main.exe + 0x00001000
  R10:  00000000`00000000
  R11:  00000000`00000000
  R12:  00000000`00000000
  R13:  00000000`00000000
  R14:  00000000`00000000
  R15:  00000000`00000000
  RIP: +00000000`00401000 main.exe + 0x00001000
  EFL:  00000244  o d I t  s Z 0 a  0 P 0 c 
  CS:   0033
  DS:   002B
  ES:   002B
  FS:   0053
  GS:   002B
  SS:   0000
  DR0:  00000000`00000000
  DR1:  00000000`00000000
  DR2:  00000000`00000000
  DR3:  00000000`00000000
  DR6:  00000000`00000000
  DR7:  00000000`00000000
  DebugControl:          00000000`0028CEB0
  LastBranchToRip:       00000000`00000000
  LastBranchFromRip:     00000000`00000000
  LastExceptionToRip:    00000000`00000000
  LastExceptionFromRip:  00000000`00000000
```

As you can tell, the `rdx` register contains the `rip`, in other words points to the entry point of the executable. The first dereferencing that happens in other words will fill `rdx` with the first 8 bytes of the the executable code segment, and then the second dereferencing will try to load that as an address, which obviously is where we have our access violation. To get the equivalents of the C `main` procedure's arguments, we need to go to the Win64 libraries again and use a procedure call to fetch them. And if we want them parsed into something resembling `argc` and `*argv[]`, we need another function call to parse, and a third call to free the memory. But that comes later. Now let us just consider this a learning opportunity: audit your assumptions every once in a while, especially if things don't behave as you thought they would. Your assumptions are more likely to have gone wrong than anything else.
