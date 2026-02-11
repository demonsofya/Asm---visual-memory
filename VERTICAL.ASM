.model tiny
.code
org 100h

start:		 mov ax, 0b800h
                mov es, ax

                mov bx, 10     ; номер столбца
                mov cx, 26     ; сколько раз будет выполняться команда
            
            draw:
                mov byte ptr es:[bx], 13h
                mov byte ptr es:[bx + 1], 1bh
                add bx, 160
                dec cx
                cmp cx, 0
                jne draw 
                
                mov ax, 4c00h
                int 21h

end		 start