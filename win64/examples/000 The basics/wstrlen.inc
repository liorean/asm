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
