format ELF executable
entry _start

segment readable executable

_start:
mov     al,     4       ;4=write, see  http://docs.cs.up.ac.za/programming/asm/derick_tut/syscalls.html
mov     bl,     1       ;1=stdout
mov     ecx,    message
mov     dl,     messageLen
int     0x80

mov     al,     1       ;1=exit
mov     bl,     0
int     0x80

segment readable writable

message         db      'Test',0x0a
messageLen      =       $-message

