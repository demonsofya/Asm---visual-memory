.model tiny
.code
org 100h

start:           jmp main


;--------------------MAIN-------------------------
; expects: string, started with space, after 1 hex num - string num
; continue with 2 hex nums - latter & back color
main:           mov ax, 0b800h
                mov es, ax
                xor ax, ax

                mov bx, 82h         ; номер позиции в строке (позиция в памяти) + перепрыгиваем пробел
                mov cl, ds:[80h]    ; длина строки - не хватает регистров чтобы это хранить, проще каждый раз обращаться заново

                call get_user_num
                mov dh, al
                sub cl, 4d

                mov ax, 7d
                call print_user_string

                mov ax, 4c00h
                int 21h
;--------------------------


;---------------------------
;Entry:
;   bx - mem point  | returns to point after num
;Returns:
;   al - number - потому что цвет хочу, а он в ah
;---------------------------
get_user_num proc 
        mov ax, [bx]

        cmp al, 57d             ; потому что ебучий литл эндиан
        jg  first_hex_letter

        cmp al, 48d
        jl  first_hex_letter

        sub al, 48d  
        jmp second_num

    first_hex_letter:
        sub al, 87d 

    second_num:
        cmp ah, 57d
        jg  second_hex_letter

        cmp ah, 48d
        jl  second_hex_letter

        sub ah, 48d  
        jmp end

    second_hex_letter:
        sub ah, 87d  

    end:
        shl al, 4
        add al, ah

        add bx, 3d

        ret
;------------------------------



;---------------------------
;Expect:
;   es = 0b800h
;Entry:
;   cl - str length | destroy
;   bx - mem point  | destroy
;   si              | destroy
;   ax - ramka string num
;   dh - letters color + background color
;----------------------------
print_user_string proc
        mov di, ax          ; сохраняем перед умножением
        mov bp, dx

        mov si, 160d
        mul si              ; отступ строк - dx не меняется потому что байт а не слово
        add ax, 80
        sub ax, cx          ; двигаем в середину (cl тк каждый символ 2байта)
        xchg ax, si
        and si, 0FFFEh
        mov dx, bp

        draw_user_str_cycle:
            mov dl, ds:[bx] 
            mov es:[si], dx
            inc bx
            add si, 2
            dec cl
            cmp cl, 0
            jg draw_user_str_cycle

        xchg ax, di

        ret
;--------------------------
    

end		 start