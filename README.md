# tiny-prime
An 166B x86-64 Ehrlich Sieve Method Prime Number Calculator On Linux

For a normal 64-bit program, the ELF header and program header table are essential, which already take up 120 bytes. This program references the method in (https://www.muppetlabs.com/~breadbox/software/tiny/) and constructs a sieve of Ernst's method to calculate prime numbers in only 166 bytes. By inputting an upper limit, the program will output all prime numbers not greater than that limit.

You can download ```prime-x64.s``` and

```nasm -f bin prime-x64.s -o prime-x64```

to bulid or download a pre-built binary file ```prime-x64``` and run it.
