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
;-------------------------
main:           mov ax, 0b800h
                mov es, ax
                xor ax, ax

                mov bx, 82h         ; номер позиции в строке (позиция в памяти) + перепрыгиваем пробел
                mov cl, ds:[80h]    ; длина строки - не хватает регистров чтобы это хранить, проще каждый раз обращаться заново

                call get_user_num   ; getting color
                mov dh, al          ; moving color to dh

                call get_user_num   ; ax = string num
                mov si, bx
                sub si, 81h
                sub cx, si          ; cx - new length of line ('cause skipping read symbols)
                call print_user_string

                push 1b19h          ; '-> but down' cyan on blue - arg1 for function
                add cx, 2
                push cx             ; str len - arg2 for func
                sub ax, 1
                push ax             ; str num - arg 3 for func
                call print_symbols_string

                push 1b18h          ; '->' but up - arg 1
                push cx             ; str len - srg 2
                add ax, 2           ; str num - arg 3
                push ax
                call print_symbols_string

                mov ax, 4c00h
                int 21h
;---------------------------


;---------------------------
;reading two symbols and interpret them like a hex num, putted in al
;Entry:
;   bx - mem point  | returns to point after num
;Returns:
;   al - number - cause ax = al, and it is 2 hex nums - half of register 
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
        xor ah, ah       ; ax = al = hex num

        add bx, 3d      ; jumping over readen symbols (also space after)

        ret
;------------------------------



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
;----------------------------
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
            dec cl
            cmp cl, 0
            jg draw_user_str_cycle

        xchg ax, di
        pop cx

        ret
;--------------------------


;--------------------------
; PASCAL CALL TYPE
; void print_symbols_string(symbol_color, str_len, string_num)
;return nothing
;ax - string num    | save(!)
;di                 | destroy | using num of memory cell
;si                 | destroy
;cx - string length | save(!)
;bx - symbol & color
;--------------------------
print_symbols_string proc 
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
;-------------------------

end		 start