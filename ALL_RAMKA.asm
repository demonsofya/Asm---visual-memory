.model tiny
.code
org 100h

string_width equ 10d

screen_width equ 160d

hearts_symbol   equ 03h
spades_symbol   equ 06h
diamonds_symbol equ 04h
clubs_symbol    equ 05h

right_arrow_symbol      equ 1ah
left_arrow_symbol       equ 1bh
up_arrow_symbol         equ 18h
down_arrow_symbol       equ 19h

white_smile_face_symbol equ 01h
black_smile_face_symbol equ 02h
one_note_symbol         equ 0dh
two_notes_symbol        equ 0eh


start:           jmp main


;--------------------MAIN-------------------------
; expects: string, started with space, 
; 2 hex nums - 1st or 2nd ramka variant
;-----1st ramka variant
; 2 hex nums - ramka latter & back color
; 2 hex num - string num
; 2 hex nums - ramka width 
; 2 hex nums - user string color
; 2 hex nums (from 1 to 3) - ramka style
; (but is can by any 2 symbols,it just be random color for result)
;-----2nd ramka variant
; 2 hex nums - ramka back color
; 2 hex num - ramka height
; 2 hex nums - ramka width
; 2 hex nums - string color
; 2 hex nums - string num
;-----
; cx is always string length = string_width
;--------------------------
main:   
        mov bx, 82h        ; getting first user num
        mov cl, ds:[80h]        

        call get_user_num
        cmp ax, 3
        je third_ramka_variant

        cmp ax, 2
        je second_ramka_variant

        jmp first_ramka_variant

second_ramka_variant:   

        mov ax, 0b800h
        mov es, ax   
         
        call get_user_num   ; 1st - color & symbol
        mov di, ax

        call get_user_num   ; 2nd - height
        mov si, ax

        call get_user_num   ; 3d - width
        mov cx, ax

        mov ax, di
        mov ah, al

        call draw_rectangle_ramka

        call get_user_num   ; 4th - user string color
        mov dh, al

        call get_user_num   ; 5th - string num

        mov si, bx
        sub si, 81h         ; getting number of readen symbols (si - curr symbol position, 81h - start position)
        mov cl, ds:[80h]
        sub cx, si          ; cx - new length of line ('cause skipping read symbols)

        call print_user_string

        mov ax, 4c00h
        int 21h

third_ramka_variant:

        mov ax, 0b800h
        mov es, ax   
         
        call get_user_num   ; 1st - color & symbol
        mov di, ax

        call get_user_num   ; 2nd - height
        mov si, ax

        call get_user_num   ; 3d - width
        mov cx, ax

        mov ax, di
        mov ah, al

        call draw_numbers_ramka

        call get_user_num   ; 4th - user string color
        mov dh, al

        call get_user_num   ; 5th - string num

        mov si, bx
        sub si, 81h         ; getting number of readen symbols (si - curr symbol position, 81h - start position)
        mov cl, ds:[80h]
        sub cx, si          ; cx - new length of line ('cause skipping read symbols)

        call print_user_string

        mov ax, 4c00h
        int 21h

first_ramka_variant:

        mov ah, 09h
        mov dx, offset Hello
        int 21h             ; printing Hello-message to user

        mov ax, 0b800h
        mov es, ax
        
        mov cl, ds:[80h]    ; длина строки - не хватает регистров чтобы это хранить, проще каждый раз обращаться заново

        call get_user_num   ; getting color
        
        mov dh, al          ; moving color to dh
        xor dl, dl

        call get_user_num   ; ax = string num

        mov bp, ax
        call get_user_num
        xchg bp, ax         ; bp = ramka width, ax = string num

        mov si, ax
        call get_user_num
        xchg si, ax         ; style type


        push cx
        push bx
        push dx

        cmp si, 1
        je first_type
        cmp si, 2
        je second_type
        cmp si, 3
        je third_type
        jmp fourth_type


first_type:
        push right_arrow_symbol        
        push left_arrow_symbol               
        push up_arrow_symbol                
        push down_arrow_symbol                
        jmp call_draw_ramka

second_type:
        push hearts_symbol     
        push diamonds_symbol                
        push clubs_symbol                
        push spades_symbol                
        jmp call_draw_ramka

third_type:
        push white_smile_face_symbol                
        push black_smile_face_symbol               
        push one_note_symbol              
        push two_notes_symbol               
        jmp call_draw_ramka  

fourth_type:
        push 31h 
        push 32h
        push 33h
        push 34h
        jmp call_draw_ramka  

call_draw_ramka:
        mov cx, string_width
        mov bh, dh
        call draw_ramka
        add sp, 8

        pop dx
        pop bx
        pop cx

        xchg dx, ax         ; saving ax 
        call get_user_num
        xchg dx, ax         ; moving read number to dx and old ax value to ax
        xchg dl, dh

        mov cl, ds:[80h]

        mov si, bx
        sub si, 81h
        sub cx, si          ; cx - new length of line ('cause skipping read symbols)
        call print_user_string

        mov ax, 4c00h
        int 21h
;--------------------------



;--------------------------
;reading two symbols and interpret them like a hex num, putted in al
;Entry:
;   bx - mem point  | returns to point after num
;Destroy:
;   bx 
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

first_hex_letter:               ; if it is a-f
        sub al, 87d             ; ascii code of 'a' starts from 87

second_num:                     ; second num (if its not obvious)
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

        add bx, 3d      ; jumping over read symbols (also space after)

        ret
;--------------------------



;--------------------------
;printout string from memory (even if it is db string)
;Expect:
;   es = 0b800h
;Entry:
;   bx - mem point              | destroy
;   ax - ramka string num       | save
;   dh - letters + background color
;Using registers:
;   si - num of mem cell        | destroy 
;   bp - as counter             | destroy
;   di - for cycle              | destroy
;Destroy:
;   bx
;   si
;   bp 
;   di
;Return:
;   nothing
;--------------------------
print_user_string proc
        push ax             ; сохраняем перед умножением
        mov bp, dx
        push cx             ; save cx

        mov di, cx
        mov cx, string_width         ; TODO что такое нахуй 10????

        mov si, screen_width
        mul si              ; отступ строк - dx не меняется потому что байт а не слово
        add ax, 80d
        sub ax, cx          ; двигаем в середину (cl тк каждый символ 2байта)
        xchg ax, si
        and si, 0FFFEh      ; making num even, cause colors and symbols will change in opposite
        mov dx, bp

        xor bp, bp

drawing_many_strings:       ; it is loop (cycle in other cycle)
        push si             ; saving start position
        mov cx, string_width
        inc bp

draw_user_1string:
        mov dl, ds:[bx] 
        mov es:[si], dx
        inc bx
        add si, 2
        dec di
        cmp di, 0
        je draw_end

        loop draw_user_1string

        pop si
        add si, screen_width
        jmp drawing_many_strings
        
draw_end:
        mov es:[si], hearts_symbol    ; serdechko symbol
        mov es:[si+1], dh   ; back color
        add si, 2
        loop draw_end

        pop si

        pop cx
        pop ax

        ret
;--------------------------



;--------------------------
; PASCAL CALL TYPE
; void print_symbols_horizontal_string(symbol_color, str_len, string_num)
; printing string of str_len symbols in center of string_num string full of symbols symbol_color
; return nothing
; Expect:
;   ex = 0b800h
; Entry:
;   1st param - symbol & color
;   2nd param - string length
;   3rd param - string number
; Using registers:
;   ax - string num    | save(!)
;   cx - string length | save(!)
;   bx - symbol & color| save(!) not dx because mul
;   si                 | save(!)
;   di                 | save(!) using num of memory cell
; Destroy:
;   nothing
; Return:
;   nothing
;--------------------------
print_symbols_horizontal_string proc 
        
        push bp
        mov bp, sp

        push si         ; save si
        push ax         ; save ax
        push cx         ; save cx
        push di         ; save di

        mov ax, [bp + 4]         ; string num
        mov cx, [bp + 6]         ; str len
        mov bx, [bp + 8]         ; symbol, color

            
        mov si, screen_width     ; TODO ПОЧЕМУ НЕ 781329????
        mul si          ; ax *= 160 - correct string
        add ax, 80d
        sub ax, cx      ; center of str
        and ax, 0FFFEh  ; making num even, cause colors and symbols will change in opposite

        mov di, ax      ; di = ax
        mov ax, bx      ; ax = correct symbol
        rep stosw  

        pop di
        pop cx          
        pop ax
        pop si
        pop bp

        ret 6d           ; clearing stack
;--------------------------



;--------------------------
; CDECL CALL TYPE
;void print_symbols_vertical_string(string_num, column_num, string_length, symbol&color)
;printing vertical string with string_length symbols started from (column_num, string_num) 
; Expect:
;   ex = 0b800h
; Entry:
;   1st param - string number
;   2nd param - column number
; Using registers:
;   ax - string num     |  destroy to string_num as arg_1
;   dx - using for mul  |  destroy
;   di - string length  |  save
;   bx - symbol & color |  save
;   cx - using for loop |  save
;Destroy:
;   dx
;   ax
;Return:
;   nothing
;--------------------------
print_symbols_vertical_string proc
        push bp
        mov bp, sp
        push di

        mov ax, ss:[bp + 4]         ; string num
        push ax

        mov dx, screen_width
        mul dx
        mov dx, ax              ; dx = right str
        pop ax                  ; saving ax (cause mul)
        
        add dx, ss:[bp + 6]               ; dx + column

        mov di, ss:[bp + 8]         ; str len
        mov bx, ss:[bp + 10]        ; symbol, color

        xchg cx, di
        xchg di, dx

draw_vert_string_cycle:
        mov es:[di], bx
        add di, screen_width
        loop draw_vert_string_cycle 

        xchg di, dx
        xchg cx, di

        pop di
        pop bp
        ret                       ; dont moving sp 'cause cdecl
;--------------------------



;--------------------------
;draw ramka bp times (да у меня кончились регистры)
; Expect:
;   ex = 0b800h
; Entry:
;   arg_1, arg_2, arg_3, arg_4 - symbols for ramka
; Using registers:
;   cx - start str length         | destroy
;   ax - str num                  | save
;   bx - color & symbol           | save
;   si - counter of ramka high    | destroy to start bp value
;   bp - ramka width              | destroy to 0
;   di - using us bp              | destroy 
; Destroy:
;   cx
;   si
;   bp
;   di
; Return:
;   nothing
;--------------------------
draw_ramka proc 
        mov si, 1
        mov di, sp

draw_one_ramka:
        xor bl, bl
        add bx, ss:[di + 2]
        add cx, 2           ; cx' = cx + 2 -> wysdom (width) of ramka

        push bx             ; -> but down - arg1

        push cx             ; str len - arg2 for func

        sub ax, si
        push ax             ; str num - arg 3 for func

        call print_symbols_horizontal_string
        
        
        xor bl, bl
        add bx, ss:[di + 4]
        push bx             ; '->' but up - arg 1

        push cx             ; str len - srg 2

        add ax, si
        add ax, si
        push ax             ; str num - arg 3

        call print_symbols_horizontal_string



        push si             ; saving



        xor bl, bl
        add bx, ss:[di + 8]
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
        
        

        xor bl, bl
        add bx, ss:[di + 6]
        push bx          ; <- arg 4
        
        push si         ; vertical str len, arg 3
        
        mov dx, 80d
        add dx, cx          ; dont changing cx
        dec dx              ; want to floor(dx)
        and dx, 0FFFEh
        push dx             ; column num, arg 2

        push ax             ; str num, arg 1

        call print_symbols_vertical_string
        add sp, 8           ; cleaning stack


        pop si
        add ax, si
        inc si
        inc bh

        dec bp
        cmp bp, 0
        jg draw_one_ramka


        ret
;--------------------------



;--------------------------
;draw ramka ah (symbol = 00) color cx width and si high
; function that exsists only for next task
;destroy:  di, si, dx,
;save:     bx, ax, cx
;--------------------------
draw_rectangle_ramka proc
        push ax
        push bx

        xor di, di

    ; counting ramka position
        xchg ax, di ;---- saving to mul
        xor ax, ax
        add ax, 80d
        sub ax, cx      ; center of str
        and ax, 0FFFEh  ; making num even, cause colors and symbols will change in opposite
        xchg ax, di     ;di - correct address

        push di

        xor al, al      ; no symbol
        mov dx, cx      ; saving cx

draw_1_string:
        rep stosw
        mov cx, dx
        sub di, dx
        sub di, dx
        add di, screen_width
        dec si
        cmp si, 0
        jg draw_1_string 

        pop di
        add di, screen_width + 2
        sub dx, 2
        mov cx, dx

        pop bx
        pop ax

        ret
;--------------------------



;--------------------------
;draw ramka ah color cx width and si high
;using numbers 1-9
;destroy:  di, si, dx,
;save:     bx, ax, cx
;--------------------------
draw_numbers_ramka proc
        push ax
        push bx

        xor di, di

    ; counting ramka position
        xchg ax, di ;---- saving to mul
        xor ax, ax
        add ax, 80d
        sub ax, cx      ; center of str
        and ax, 0FFFEh  ; making num even, cause colors and symbols will change in opposite
        xchg ax, di     ;di - correct address

        xor al, al      ; no symbol
        mov dx, cx      ; saving cx

draw_first_string:
        sub cx, 2

        mov al, 31h     ; number 1 symbol
        stosw

        mov al, 32h     ; number 2 symbol
        rep stosw 

        mov al, 33h     ; number 3 symbol
        stosw

        mov cx, dx
        sub di, dx
        sub di, dx
        add di, screen_width

        dec si

draw_one_string:
        sub cx, 2

        mov al, 34h     ; number 4 symbol
        stosw

        mov al, 35h     ; number 5 symbol
        rep stosw

        mov al, 36h     ; number 6 symbol
        stosw

        mov cx, dx
        sub di, dx
        sub di, dx
        add di, screen_width
        dec si
        cmp si, 1
        jg draw_one_string

draw_last_string:
        sub cx, 2

        mov al, 37h 
        stosw

        mov al, 38h
        rep stosw 
        
        mov al, 39h 
        stosw

        mov cx, dx
        sub di, dx
        sub di, dx
        add di, screen_width

        pop bx
        pop ax

        ret
;--------------------------

Hello                   db "Note: In argument string must be 5 hex numbers, all for 2 symbols: ramka latter & back color | string num | ramka width | user string color | ramka style$"  

end		 start