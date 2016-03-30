u8_from_zu16:
.prolog:
.body:  xor r8d, r8d
        mov eax, [rcx]
.caput: cmp ax, 0xfffe  ;   Check for UTF-16LE BOM.
        jz .loop
.corpus:test ax, ax     ;   Check for zero termination
        jz .cauda
        cmp ax, 0x7f    ;   Check for single code unit code points
        jna .single
        inc edx
        cmp ax, 0x7ff   ;   Check for double code unit code point
        jna .double
        inc edx
        cmp ax, 0xd7ff  ;   Check for low triple code unit code points
        jna .triple
        cmp ax, 0xdfff  ;   Check for high triple code unit code points
        ja .triple
        cmp ax, 0xdbff  ;   Check for unmatched low surrogate code unit
        ja .triple      ;   (invalid but possible in e.g. Windows filenames)
        cmp eax, 0xdbff0000;Check for unmatched high surrogate
        jna .triple     ;   (invalid but possible in e.g. Windows filenames)
        cmp eax, 0xdfffffff;Check for unmatched high surrogate
        ja .triple      ;   (invalid but possible in e.g. Windows filenames)
.multi: add rcx, 0x2
        mov r8d, eax
        and eax, 0x3ff  ;   Low ten bits
        and r8d, 0x3ff0000; High ten bits
        shr r8d, 0x6    ;   Shift down the high bits
        or r8d, 0x100000;   Add the 21st bit
        or eax, r8d     ;   Merge all 21 bits
.quad:  shr r8d, 0x12   ;   Shift down the 18 low bits
        or r8b, 0xf0    ;   Add four byte lead byte marker
        mov [rdx], r8b
        inc rdx
        jmp .cont3
.triple:mov r8w, ax
        shr r8w, 0xc    ;   Shift down 12 bits
        or r8b, 0xe0    ;   Add three byte lead byte marker
        mov [rdx], r8b
        inc rdx
        jmp .cont2
.double:mov r8w, ax
        shr r8w, 0x6    ;   Shift down 6 bits
        or r8b, 0xc0    ;   Add two byte lead byte marker
        mov [rdx], r8b
        inc rdx
        jmp .cont
.single:mov [rdx], al
        jmp .loop
.cont3: mov r8d, eax
        shr r8d, 0xc    ;   Shift down 12 bits
        and r8b, 0x3f   ;   Mask low six bits
        or r8b, 0x80    ;   Add continuation marker
        mov [rdx], r8b
        inc rdx
.cont2: mov r8w, ax
        shr r8w, 0x6    ;   Shift down 6 bits
        and r8b, 0x3f   ;   Mask low 6 bits
        or r8b, 0x80    ;   Add continuation marker
        mov [rdx], r8b
        inc rdx
.cont:  and al, 0x3f    ;   Mask low 6 bits
        or al, 0x80     ;   Add continuation marker
        mov [rdx], al
.loop:  inc rdx
        add rcx, 0x2
        mov eax, [rcx]
        jmp .corpus
.cauda: mov eax, edx
.epilog:ret
.end:
