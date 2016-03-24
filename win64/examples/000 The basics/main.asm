;"%ASMROOT%\win64\examples\000 The Basics\main.asm"
;
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