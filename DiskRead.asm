[BITS 16]
PROGRAM_SPACE equ 0x7e00

ReadDisk:
    mov ah, 0x02
    mov bx, PROGRAM_SPACE
    mov al , 1 ; count of sectors
    mov dl, [BOOT_DISK]
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02

    int 13h

    jc DiskReadFailed
    mov bx, DiskReadSuccessString
    call PrintString
    ret   

BOOT_DISK:
    db 0

DiskReadErrorString:
    db "Disk Read Failed!" , 0

DiskReadSuccessString:
    db "Disk Read Success!" , 0

DiskReadFailed:
    mov bx, DiskReadErrorString
    call PrintString
    jmp $