.model tiny
.code
org 100h

start:		 mov ax, 0b800h
               	 mov es, ax

                 mov ax, 10     ; номер строки
                 mov cx, 80     ; сколько раз будет выполняться команда

                 mov dx, 160
                 mul dx
               	 xor di, di
                 add di, ax
                 mov ax, 1b13h

                 rep stosw 

                 mov ax, 4c00h
		         int 21h

end		 start