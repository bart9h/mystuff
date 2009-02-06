format ELF executable
entry _start

segment readable executable

_start:
mov     al,     4
mov     bl,     1
mov     ecx,    message
mov     dl,     messageLen
int     0x80

mov     al,     1
mov     bl,     0
int     0x80

segment readable writable

message         db      'Test',0x0a
messageLen      =       $-message

