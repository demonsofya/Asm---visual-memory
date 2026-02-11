.model tiny
.code
org 100h

start:		    mov ax, 0b800h
                mov es, ax

                mov bx, 81h         ; номер позиции в строке (позиция в памяти)
                mov cl, ds:[80h]    ; длина строки

                mov di, 160 * 8
                add di, 80
                sub di, cx          ; двигаем в середину

                xor ax, ax
                mov ah, 1bh 
                
            draw:
                mov al, [bx]
                stosw 
                inc bx
                dec cl
                cmp cl, 0
                jg draw 
                
                mov ax, 4c00h
                int 21h


end		 start