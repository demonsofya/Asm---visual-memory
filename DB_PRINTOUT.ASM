.model tiny
.code
org 100h

start:		    mov ax, 0b800h
                mov es, ax

                mov bx, offset Hello        ; номер позиции в строке
                mov cx, offset line_end     ; длина строки
                sub cx, bx

                mov di, 80 * 11
                mov ah, 1bh 
                
            draw:
                mov al, [bx]
                stosw 
                inc bx
                dec cx
                cmp cx, 0
                jne draw 
                
                mov ax, 4c00h
                int 21h

Hello       db "Hello world"
line_end:

end		 start