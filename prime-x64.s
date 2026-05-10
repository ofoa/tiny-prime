;;Copyright (c) 2026 ofoa
;;GNU GENERAL PUBLIC LICENSE
;;Version 3, 29 June 2007
;;
;;An 165B x86-64 Ehrlich Sieve Method Prime Number Calculator On Linux
;;To build: nasm -f bin prime-x64.s -o prime-x64
;;
;;The ELF header and program header table of this program are as follows
;;This part was inspired by https://www.muppetlabs.com/~breadbox/software/tiny/
;;In short, it uses an interesting method to embed the ELF header, program header table,
;;and instructions together, because Linux doesn't inspect every field in ELF.
;;00000000: 7f45 4c46 545e b214 0f05 41b7 0aff c73d
;;00000010: 0200 3e00 b203 eb34 0100 0000 0500 0000
;;00000020: 1800 0000 0000 0000 1800 0000 0500 0000
;;00000030: 490f afdf 563d 3800 0100 2c30 eb0a 0000
;;00000040: 0100 2c30 eb0a 0000


BITS 64

_start:
    dd      0x464c457F            ;ELF Magic Number
    push    rsp
    pop     rsi                   ;= mov rsi, rsp; set RSI to some buffer memory location
    mov     dl, 20                ;Buffer size = 20
    syscall                       ;rax = 0, sys_read

;;From here, to ensure that the code precisely fits the unimportant parts
;;of the ELF header, the location of some instractions may be confused

    mov     r15b, 10              ;Preparing for the following mul 10/div 10 loop
    inc     edi                   ;Preparing for sys_write at "print_dec_loop"
    cmp     eax, 0x003e0002       ;ELF informations, has no effect
    mov     dl, 3                 ;Preparing for sys_mmap
    jmp     dec_start
    dq      0x500000001
    dq      0x18
    dq      0x500000018           ;ELF informations


scan_dec_loop:                    ;This loop is to change the ascii input to the number in RBX
    imul    rbx, r15              ;RBX *= 10
    push    rsi                   ;It will be easier to understand if move this instraction and following 
                                  ;"push rbx" in front of "pop rsi", they just aim to push rsi; mov rsi, rbx
                                  ;We will push some garbage on stack, but it doesn't matter
    cmp     eax, 0x00010038       ;ELF informations
    sub     al, '0'               ;Now RAX is the number of the digit pointed by RSI 
    jmp     LL
    dw      0
    dq      0x00000aeb302c0001    ;ELF informations
LL:
    add     rbx, rax
    push    rbx                  
    dec_start:
    mov     al, [rsi]             ;Now RAX is the ascii of the digit pointed by RSI 
    inc     rsi                   ;Let RSI point to the lower digit
    cmp     al, 0x0a              ;If (rax == '\n') break; now RBX is the upper limit of prime numbers
    jne     scan_dec_loop


    mov     r10b, 0x22
    pop     rsi
    mov     al, 9
    syscall

;;This part of memory is used to store whether each number is a prime number, 0 means possible is, others mean not
;;sys_mmap, RDI(addr) == 1, Linux will ignore it and allocate an available address
;;          RSI(length) == RBX (the upper limit of prime numbers)
;;          RDX(prot) == 3
;;          R8(fd) == 0, the fd argument will be ignored if MAP_ANONYMOUS is set
;;          R9(offset) == 0
;;          R10(flags) == 0x22

    add     rbx, rax              ;RBX point to the address of upper limit
    not     byte [rax + 1]        ;1 is not a prime number
_loop:                            ;Main loop ,iterate through all numbers
    inc   rbp                     ;RBP is not an address, just the number to be judged
    inc   rax
    cmp   [rax], dh               ;dh == 0, if(*num != 0) continue;
    jne   loop_jump
    pop   rsi                     ;Reset RSI for "print_dec_loop"
    push  rsi
    push  rax
_loop2:                           ;Key logic of the Ehrlich Sieve Method
    add rax, rbp
    cmp rax, rbx
    jg  _break
    mov [rax], dl                 ;dl != 0, *num = (something not zero)
    jmp _loop2
_break:


    push rbp
    pop rax                       ;= mov rax, rbp; Move the prime number to RAX for the div operation
    mov   cl, 1  
                   
;;When Using sys_read to get a string, Linux will preserve the '\n' you type at the end
;;By skillful use of RSI, we can output the number and this '\n' at the same sys_write
;;"mov cl, 1" is to let RDX finally equals to 1 + len of number

print_dec_loop:                   ;This loop is to change the number in RBX to the ascii output
    dec rsi
    cqo
    div r15                       ;rdx = rax % 10; rax /= 10;
    add dl, '0'
    mov [rsi], dl                 ;Move the ascii to memory
    inc cl
    test rax, rax                 ;if (rax == 0) break;
    jnz print_dec_loop
    mov dl, cl
    inc al
    syscall                       ;rax = 1, sys_write
    pop rax
loop_jump:
    cmp rax, rbx                  ;if (num == upper_limit) break;
    jne _loop


    push byte 60
    pop rax                       ;= mov rax, 60
    syscall                       ;sys_exit, the exit code is 1, but set it to 0 will take our precious 2 bytes
