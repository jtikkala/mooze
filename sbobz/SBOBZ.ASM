;"Great" tre hours project by LÖKÖ of Napalm Software
; I saw a message on our local support site Juho's Place BBS
; about the art of shade bobs.
; I decided to do my own shade bobs just for fun at christmas eve

; I'm fucking tired because of all thiese "nice" TASM features.
; It took me fucking two hours to discover a bug in this eazy
; piezy of code. The only thing that was fucking wrong was that
; I used three fucking variables like this "mov si,xplace".
; normally this would work ok, but now the fucking program loaded
; the variable from the fucking DS segment instead of CS. And DS
; was pointing to the fucking font data. Fucking funny!

; I have (OHO) optimized the code somehow, but there are still some
; bytes to crush. Anyway nice 1K intro?

cseg    segment
        assume cs:cseg
        org 0100h
        .286

start:
  mov ax,13h
  int 10h

;You could try the following three lines instead of INT 10h call 
;  push 0f000h
;  pop  ds     ;One byte smaller than "MOV AX,0f000h  MOV DS,AX"
;  mov  bp,0fa6eh
        mov ax,01130h   ;Load 8x8 font pointer
        mov bh,3
        int 10h
        push es
        pop  ds
        push 0a000h     ;ES points to vidmem. DS points to 8x8 font
        pop  es

  mov dx,3c8h
  xor ax,ax
  out dx,al
  inc dx
  @pal_loop1: ;Set colors 0-62
  out dx,al
  out dx,al
  out dx,al
  inc al
  cmp al,63
  jne @pal_loop1
  @pal_loop2: ;set colors 63-127
  out dx,al
  out dx,al
  out dx,al
  dec al
  jnz @pal_loop2
  @pal_loop3: ;set colors 127-194
  xchg al,ah
  out dx,al
  out dx,al
  xchg al,ah
  out dx,al
  inc al
  cmp al,63
  jne @pal_loop3
  @pal_loop4: ;set rest
  xchg al,ah
  out dx,al
  out dx,al
  xchg al,ah
  out dx,al
  dec al
  jnz @pal_loop4

  @main_loop:
  call update_bobe      ;Make bobe. Update coordinates
  cmp byte ptr cs:[offset temp_count],speedy
  jne @no_text
  mov byte ptr cs:[offset temp_count],0
  call dotext
  @no_text:
  inc byte ptr cs:[offset temp_count]
  mov ah,1
  int 16h
  jz  @main_loop
  mov ax,3
  int 10h
  push cs      ;Display last message
  pop ds
  mov dx,offset endansi
  mov ah,9
  int 21h
  ret          ;Not actually very wise "exit to dos". Works fine with COM files

Update_bobe     proc    near
;Move the shade bob
                pusha
                ;Update bob coordinates
                cmp     byte ptr cs:[offset bobexdir],0
                jne     @oikea
                add     word ptr cs:[offset bobex],2
                @oikea:
                dec     word ptr cs:[offset bobex]
                cmp     byte ptr cs:[offset bobeydir],0
                jne     @ylos
                add     word ptr cs:[offset bobey],2
                add     word ptr cs:[offset bobeyfast],640
                @ylos:
                dec     word ptr Cs:[offset bobey]
                sub     word ptr cs:[offset bobeyfast],320

                ;Check if the bob is bouncing
                cmp     word ptr cs:[offset bobey],199-bobesize
                jle     @ei_ylos
                mov     byte ptr cs:[offset bobeydir],1
                @ei_ylos:
                cmp     word ptr cs:[offset bobey],bobesize
                jge     @ei_alas
                mov     byte ptr cs:[offset bobeydir],0
                @ei_alas:
                cmp     word ptr cs:[offset bobex],319-bobesize
                jle     @ei_vasen
                mov     byte ptr cs:[offset bobexdir],1
                @ei_vasen:
                cmp     word ptr cs:[offset bobex],0
                jg      @ei_oikea
                mov     byte ptr cs:[offset bobexdir],0
                @ei_oikea:

;Make shade bob
                mov si,cs:[offset bobeyfast]
                add si,cs:[offset bobex]
                xor bx,bx
                mov dx,bobesize
                @y_loop:
                mov cx,bobesize
                @x_loop:
                mov al,es:[si]
                add al,cs:[offset bobe+bx]
                inc bx
                mov es:[si],al
                inc si
                loop @x_loop
                add si,320-bobesize
                dec dx
                jnz @y_loop
                popa
                ret
update_bobe     endp

dotext          proc    near  ;DS:BP = pointer to font table
                pusha
                ;Display text
                mov di,cs:[offset xplace]
                mov si,cs:[offset char_counter]
                xor bh,bh
                mov bl,cs:[offset txt+si] ;Load character to BX
                shl bx,3
                add bp,bx                 ;Now BP points to character bitmap data
                xor bx,bx

                mov dx,8                  ;Horizontal counter
                @horiz_loop:
                mov cx,8
                @vert_loop:
                mov al,ds:[bp]
                and al,cs:[offset translat+bx]
                cmp al,0
                je  @ei_pikseli
                mov al,62
                @ei_pikseli:
                mov es:[di],al
                add di,320                ;Next row
                inc bp
                loop @vert_loop
                inc bx
                sub di,320*8-1
                sub bp,8
                dec dx
                jnz @horiz_loop

                ;Update message counters
                add word ptr cs:[offset xplace],9
                inc word ptr cs:[offset char_counter]  ;Next character
                mov si,cs:[offset char_counter]
                cmp byte ptr cs:[offset txt+si],0      ;End of the line?
                jne @no_clear                          ;NOT! Don't change counters
                mov word ptr cs:[offset xplace],0
                inc word ptr cs:[offset char_counter]
                @no_clear:
                cmp byte ptr cs:[offset txt+si],1      ;End of text?
                jne @fake_end
                mov word ptr cS:[offset char_counter],0 ;End of text! Clear character counter
                mov word ptr cs:[offset xplace],0
                @fake_end:
                popa
                ret
dotext          endp

include bobe.inc ;Guess what this file includes?

;TXT could be RLE coded. But hey, in these dayz of Giga Warez
;and 500 Meg HD's ... Who cares about ten bytes?
txt             db 'Hi, What You See is All You Get',0
                db 'Smash a key !FAST!             ',0
                db 'Still watching?                ',0
                db 'Okay, greetings coming',0
                db 'Juffo-WUP             ',0
                db 'Nordic Vision',0
                db 'bReAdFaN     ',0
                db 'Kingi        ',0
                db 'Pete         ',0
                db 'all the other c00l guys',0
                db 'btw. The shitro made by LÖKÖ   ',0
                db 'beware. tXt will repeat        ',1

speedy          EQU 140    ;Draw text each 140th frame

endansi         db 27,'[36m"Great" 1K Shitro by LÖKÖ',27,'[0m',0dh,0ah,'$'

;Some variables
bobex           dw bobesize+1
bobey           dw bobesize+1
bobeyfast       dw (bobesize+1)*320
translat        db 128,64,32,16,8,4,2,1
char_counter    dw 0
xplace          dw 0
temp_count      db ?
bobexdir        db ?
bobeydir        db ?

cseg ends
     end start
