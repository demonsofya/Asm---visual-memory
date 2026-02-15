.model tiny
.code
org 100h

start:           jmp main


;--------------------MAIN-------------------------
; expects: string, started with space, 
; 2 hex nums - latter & back color
; 2 hex num - string num
; (but is can by any 2 symbols,it just be random color for result)
; cx is always string length
;--------------------------
main:           mov ax, 0b800h
                mov es, ax

                mov bx, 82h         ; номер позиции в строке (позиция в памяти) + перепрыгиваем пробел
                mov cl, ds:[80h]    ; длина строки - не хватает регистров чтобы это хранить, проще каждый раз обращаться заново

                call get_user_num   ; getting color
                mov dh, al          ; moving color to dh

                call get_user_num   ; ax = string num
                mov si, bx
                sub si, 81h
                sub cx, si          ; cx - new length of line ('cause skipping read symbols)
                call print_user_string

                mov bp, 5
                mov bh, dh
                call draw_ramka

                push 1b19h          ; '-> but down' cyan on blue - arg1 for function
                add cx, 2
                push cx             ; str len - arg2 for func
                sub ax, 1
                push ax             ; str num - arg 3 for func
                call print_symbols_horizontal_string

                push 1b18h          ; '->' but up - arg 1
                push cx             ; str len - srg 2
                add ax, 2           ; str num - arg 3
                push ax
                call print_symbols_horizontal_string

                push 1b1ah          ; ->, arg 4
                push 3d             ; str len, arg 3
                mov dx, 80d
                sub dx, cx          ; dx = column num
                and dx, 0FFFEh
                push dx             ; column num, arg 2
                sub ax, 2           ; high string
                push ax             ; str num, arg 1
                call print_symbols_vertical_string
                add sp, 8           ; cleaning stack

                push 1b1bh          ; <-
                push 3d
                add dx, cx
                add dx, cx
                dec dx              ; want to floor(dx)
                and dx, 0FFFEh
                push dx
                push ax
                call print_symbols_vertical_string
                add sp, 8           ; cleaning stack

                
                mov ax, 4c00h
                int 21h
;--------------------------


;--------------------------
;reading two symbols and interpret them like a hex num, putted in al
;Entry:
;   bx - mem point  | returns to point after num
;Returns:
;   al - number - cause ax = al, and it is 2 hex nums - half of register 
;--------------------------
get_user_num proc 
        mov ax, [bx]            
                                ; first num
        cmp al, 57d             ; потому что ебучий литл эндиан
        jg  first_hex_letter    

        cmp al, 48d             ; ascii code of '0'-'9' starts from 48 and end with 57
        jl  first_hex_letter

        sub al, 48d             ; if it is 0-9
        jmp second_num

    first_hex_letter:           ; if it is a-f
        sub al, 87d             ; ascii code of 'a' starts from 87

    second_num:                 ; second num (if its not obvious)
        cmp ah, 57d
        jg  second_hex_letter

        cmp ah, 48d
        jl  second_hex_letter

        sub ah, 48d  
        jmp end

    second_hex_letter:
        sub ah, 87d  

    end:
        shl al, 4        ; al *= 16 -> to it go in ah like 1st num
        add al, ah       ; like 1st*16 + 2nd -> our num
        xor ah, ah       ; ax = al = hex num, ah = 0

        add bx, 3d      ; jumping over readen symbols (also space after)

        ret
;--------------------------



;--------------------------
;printout string from memory (even if it is db string)
;Expect:
;   es = 0b800h
;Entry:
;   cl - str length | save(!)
;   bx - mem point  | destroy
;   si              | destroy | using us num of mem cell
;   ax - ramka string num
;   dh - letters color + background color
;   bp              | destroy
;--------------------------
print_user_string proc
        mov di, ax          ; сохраняем перед умножением
        mov bp, dx
        push cx             ; save cx

        mov si, 160d
        mul si              ; отступ строк - dx не меняется потому что байт а не слово
        add ax, 80d
        sub ax, cx          ; двигаем в середину (cl тк каждый символ 2байта)
        xchg ax, si
        and si, 0FFFEh      ; making num even, cause colors and symbols will change in opposite
        mov dx, bp

        draw_user_str_cycle:
            mov dl, ds:[bx] 
            mov es:[si], dx
            inc bx
            add si, 2
            loop draw_user_str_cycle

        xchg ax, di
        pop cx

        ret
;--------------------------


;--------------------------
; PASCAL CALL TYPE
; void print_symbols_horizontal_string(symbol_color, str_len, string_num)
; printing string of str_len symbols in center of string_num string full of symbols symbol_color
; return nothing
;ax - string num    | save(!)
;di                 | destroy | using num of memory cell
;si                 | destroy
;cx - string length | save(!)
;bx - symbol & color| save(!) not dx because mul
;--------------------------
print_symbols_horizontal_string proc 
        push bp
        mov bp, sp

        mov ax, [bp + 4]         ; string num
        mov cx, [bp + 6]         ; str len
        mov bx, [bp + 8]         ; symbol, color

        push ax         ; save ax
        push cx         ; save cx
            
        mov si, 160d
        mul si          ; ax *= 160 - correct string
        add ax, 80d
        sub ax, cx      ; center of str
        and ax, 0FFFEh  ; making num even, cause colors and symbols will change in opposite

        mov di, ax      ; di = ax
        mov ax, bx      ; ax = correct symbol
        rep stosw  

        pop cx          
        pop ax

        pop bp
        ret 6d           ; clearing stack
;--------------------------


;--------------------------
; CDECL CALL TYPE
;void print_symbols_vertical_string(string_num, column_num, string_length, symbol&color)
;ax - string num        (save)
;dx - column num        (save)
;di - string length     (save)
;bx - symbol & color |  (save)
;si                  |  destroy
;--------------------------
print_symbols_vertical_string proc
        push bp
        mov bp, sp

        mov ax, [bp + 4]         ; string num
        push ax

        mov si, 160d
        mul si
        mov si, ax              ; si = right str
        pop ax                  ; saving ax

        mov dx, [bp + 6]
        add si, dx               ; dx = right column

        mov di, [bp + 8]         ; str len
        mov bx, [bp + 10]        ; symbol, color
        push di

        draw_vert_string_cycle:
                mov es:[si], bx
                add si, 160
                dec di
                cmp di, 0
                jne draw_vert_string_cycle 

        pop di                    ; saving di
        pop bp
        ret                       ; dont moving sp 'cause cdecl
;--------------------------


;--------------------------
;draw ramka bp tymes (да у меня кончились регистры)
; cx - start str length         | destroy
; ax - str num
; bx - color & symbol
; si - counter of ramka high    | destroy
; 
;--------------------------
draw_ramka proc 
        mov si, 1

        draw_one_ramka:
            mov bl, 19h
            add cx, 2           ; cx' = cx + 2 -> wide of ramka

                push si
            push bx
            push cx             ; str len - arg2 for func
            sub ax, si
            push ax             ; str num - arg 3 for func
            call print_symbols_horizontal_string
                pop si

                push si
            mov bl, 18h
            push bx             ; '->' but up - arg 1
            push cx             ; str len - srg 2
            add ax, si          ; str num - arg 3
            add ax, si
            push ax
            call print_symbols_horizontal_string
                pop si

                push si
            mov bl, 1ah
            push bx             ; ->, arg 4
            shl si, 1
            sub ax, si           ; high string
            add si, 1
            push si             ; vertical str len, arg 3
            mov dx, 80d
            sub dx, cx          ; dx = column num
            and dx, 0FFFEh
            push dx             ; column num, arg 2
            push ax             ; str num, arg 1
            call print_symbols_vertical_string
            add sp, 8           ; cleaning stack
                pop si

                push si
            mov bl, 1bh
            push bx          ; <-
            shl si, 1
            add si, 1
            push si
            add dx, cx
            add dx, cx
            dec dx              ; want to floor(dx)
            and dx, 0FFFEh
            push dx
            push ax
            call print_symbols_vertical_string
            add sp, 8           ; cleaning stack
                pop si

            add ax, si
            add si, 1
            add bh, 1

            dec bp
            cmp bp, 0
            jg draw_one_ramka

        ret
;--------------------------
end		 start