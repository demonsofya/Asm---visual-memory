.model tiny
.code
org 100h

start:		    mov ax, 0b800h
                mov es, ax

                mov bx, 81h         ; номер позиции в строке (позиция в памяти)
                mov cl, ds:[80h]    ; длина строки

                mov di, 160 * 8     ; отступ 8 строк
                add di, 80          ; идем в середину строки
                sub di, cx          ; двигаем в середину (cx тк каждый символ 2байта)

                xor ax, ax
                mov ah, 1bh         ; cyan на фоне темно-синего
                
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