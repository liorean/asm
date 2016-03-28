ccu8_in_zu16:
.prolog:
.body:  xor edx, edx
        xor r8d, r8d
        mov ax, [rcx]
.caput: cmp ax, 0xfffe  ;   Check for UTF-16LE BOM.
        jz .loop
.corpus:test ax, ax     ;   Check for zero termination
        jz .cauda
        inc edx         
        cmp ax, 0x7f
        jna .loop       ;   Single code unit code point
        inc edx
        cmp ax, 0x7ff
        jna .loop       ;   Double code unit code point
        inc edx
        cmp ax, 0xd7ff
        jna .loop       ;   Triple code unit code point  
        cmp ax, 0xdfff
        ja .loop        ;   Triple code unit code point  
        cmp ax, 0xdbff  ;   Unmatched low surrogate
        ja .losurr      ;   Triple code unit (invalid) code point
.multi: add rcx, 0x2
        mov ax, [rcx]
        cmp ax, 0xdbff  ;   Unmatched high surrogate
        jna .hisurr     ;   Triple code unit (invalid) code point
        cmp ax, 0xdfff  ;   Unmatched high surrogate
        ja .hisurr      ;   Triple code unit (invalid) code point
        inc edx
        jmp .loop       ;   Matching low and high surrogates
.hisurr:inc r8d
        jmp .corpus
.losurr:inc r8d
.loop:  add rcx, 0x2
        mov ax, [rcx]
        jmp .corpus
.cauda: mov eax, edx
.epilog:ret
.end:
