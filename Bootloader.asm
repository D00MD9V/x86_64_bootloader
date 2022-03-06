[BITS 16]
[org 0x7c00]
 
    mov [BOOT_DISK] , dl

    mov bp, 0x7c00
    mov sp , bp

    mov bx , HelloString
    call PrintString
    call ReadDisk
    
    ; turning on A20 Gate
    in al, 0x92
    or al, 2
    out 0x92, al

    cli
    lgdt [GDT_DESCRIPTOR]
    mov eax , cr0
    or eax , 1 
    mov cr0 , eax

    jmp 08h:start_protected_mode    

HelloString:
    db "Bootloader loaded success!" , 0

    %include "bootloader/Sector1/Print.asm"
    %include "bootloader/Sector1/DiskRead.asm"

[BITS 32]
start_protected_mode:

    ; initing segment registers
    mov ax, DATA_SEG        
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; setuping stack 
    mov ebp, 0x90000        
    mov esp, ebp
    
    call check_cpuid
    call check_long_mode
    call set_up_page_tables 
    call enable_paging    

    lgdt [gdt64.pointer]
    jmp gdt64.code:long_mode_start




enable_paging:
    ; load P4 to cr3 register (cpu uses this to access the P4 table)
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE-flag in cr4 (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

set_up_page_tables:
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11 ; present + writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11 ; present + writable
    mov [p3_table], eax

    mov ecx, 0         ; counter variable
    
.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000  ; 2MiB
    mul ecx            ; start address of ecx-th page
    or eax, 0b10000011 ; present + writable + huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table  ; else map the next entry

    ret


check_long_mode:
    mov eax, 0x80000000     ; Set the A-register to 0x80000000.
    cpuid                               ; CPU identification.
    cmp eax, 0x80000001     ; Compare the A-register with 0x80000001.
    jb .no_long_mode           ; It is less, there is no long mode.
    mov eax, 0x80000000     ; Set the A-register to 0x80000000.
    cpuid                               ; CPU identification.
    cmp eax, 0x80000001     ; Compare the A-register with 0x80000001.
    jb .no_long_mode           ; It is less, there is no long mode.
    ret
.no_long_mode:
    mov al, "2"
    jmp error

check_cpuid:

    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    jmp $
    hlt


gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64 ; kernel code
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64 ; kernel data
    dq (1<<44) | (1<<47) | (1<<41)
.pointer:

GDT_DESCRIPTOR:
    dw GDT_END - GDT_TABLE - 1
    dd GDT_TABLE 
GDT_TABLE:
null_descriptor:
    dq 0x0
code_descriptor:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011110b
    db 11001111b
    db 0x0

data_descriptor:

    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
GDT_END:
CODE_SEG equ code_descriptor - GDT_TABLE
DATA_SEG equ data_descriptor - GDT_TABLE

section .text
[BITS 64]
long_mode_start:

    jmp 0x7e16


[BITS 32]

section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:
section .text




times 510-($-$$) db 0
dw 0xaa55
