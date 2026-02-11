.model tiny
.code
org 100h

start:		mov ax, 0b800h
                mov es, ax
                xor bx, bx

                mov ax, 10     ; номер строки
                mov bx, 80     ; номер столбца

                mov dx, 160
                mul dx
                add bx, ax

                mov byte ptr es:[bx], 13h
                mov byte ptr es:[bx + 1], 1bh

                mov ax, 4c00h
                int 21h

end		 start