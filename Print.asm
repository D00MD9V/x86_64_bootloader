PrintString:
    push ax 
    push bx
    

    mov ah , 0x0e
.Loop:
    cmp [bx] , byte 0
    je .Exit
        mov al, [bx]
        int 10h
        inc bx
        jmp .Loop
    .Exit:

    pop ax
    pop bx
    ret 

TestString:
    db "This is a test str",0