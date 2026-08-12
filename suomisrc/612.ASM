;SUOMI-INTRO Copyright Napalm Software 1994
;------------------------------------------
;
;Tämä pieni "intro" luotiin täysin hetken mielijohteessa Suomen itsenäisen
;tasavallan 77. itsenäisyyspäivänä 6.12.1994. "Intron" koko, 612 tavua, ei ole
;sattuma, vaan alusta lähtien tuo koko oli tavoitteena: 612 eli 6.12, itse-
;näisyyspäivän päivämäärä! Tätä introa pystyisi vielä pienentämään varmaan
;melko paljonkin, mutta kun koko 612 tavua oli tavoitteena, niin miksi mennä
;muuttamaan sitä?
;
;Koodin kirjoittivat Tapio Äijälä (Unsigned) ja Antti Virtanen (Lökö) ja
;aikaa siihen kului useita tunteja johtuen äänien ohjelmoinnissa kohdatuista
;pienistä ongelmista, joita sitten ratkottiin noin 3-4 tuntia... :)
;
;Laitteistolta tämä "intro" vaatii 286 prosessorin, AdLib:iä hyödynnetään
;jos sellainen tai yhteensopiva laitteistosta löytyy, mutta sen olemassa oloa
;ei tarkisteta mitenkään! Toivokaamme siis, että kenenkään kone ei kaadu
;tämän takia...
;
;Jokaista pientä asiaa ei ole erikseen kommentoitu, vaan esim. jokaisen
;aliohjelman kommentista pitäisi selvitä mitä kyseinen aliohjelma tekee.
;Toivottavasti...

.286
code    segment
        assume cs:code, ds:code, es:code
        org 100h

;Tästä alkaa pääohjelma
main:
  mov ax,3              ;Asetetaan näyttötilaksi 80x25 tekstitila
  int 10h

  mov dx,3d4h           ;Kätketään kursori
  mov ax,800eh
  out dx,ax

  push cs
  pop  es

  call reset_adlib      ;Kutsutaan aliohjelmaa, joka resetoi AdLib:in

  mov bx,0120h          ;Luodaan jonkinlainen "instrumentti"
  call write_reg
  mov bx,1040h
  call write_Reg
  mov bx,4c60h
  call write_Reg
  mov bx,0123h
  call write_rEg
  mov bx,0f43h
  call write_Reg
  mov bx,6363h
  call write_reg

  mov bp,offset lippu  ;Muutetaan * ja + merkit lipuksi
  mov dx,42
  mov cx,2
  mov bl,0
  mov bh,16
  mov ax,1110h
  int 10h

  mov di,offset teksti+56 ;Asetetaan vieritettävän tekstin loppuun 80 merkkiä
  mov cx,40               ;tyhjää
  xor ax,ax
  cld
  rep stosw

  call make_flag        ;Piirretään ruudulle iso siniristilippu
  call hook_timer       ;Kytketään AdLib rutiinit ajastimeen

  ;Pääsilmukka, jossa ohjelma pyörii kunnes jotain näppäintä painetaan
  loopp:
    mov dx,3dah         ;Odotetaan "vertical retracea"
    vr1:
    in al,dx
    test al,8
    jnz vr1
    vr2:
    in al,dx
    test al,8
    jz vr2

    call update_teksti  ;Kutsutaan aliohjelmaa, joka vierittää tekstiä

    mov ah,1
    int 16h
    jz loopp            ;Jos mitään näppäintä ei ole painettu, palataan alkuun

  call unhook_timer     ;Irroitetaan AdLib rutiinit ajastimesta
  call reset_adlib      ;Resetoidaan AdLib

  mov ax,3              ;Asetetaan uudelleen 80x25 tekstitila
  int 10h

  mov ah,9              ;Tulostetaan ruudulle lopputeksti
  mov dx,offset stat_teksti
  push cs
  pop ds
  int 21h

  ret                   ;Lopetetaan ohjelma

make_flag       proc    near             ;Aliohjelma, joka piirtää ison
                pusha                    ;Suomen lipun ruudulle
                mov ax,0b800h
                mov es,ax
                mov ax,219+15*256
                mov di,8
                mov dx,16
                @pohja:
                mov cx,72
                rep stosw
                add di,16
                dec dx
                jnz @pohja

                mov dx,16
                mov di,8+20*2
                mov ah,1
                @pysty:
                mov cx,12
                rep stosw
                add di,160-48+24
                dec dx
                jnz @pysty

                mov di,8+6*160
                mov dx,4
                @vaaka:
                mov cx,72
                rep stosw
                add di,16
                dec dx
                jnz @vaaka
                popa
                ret
make_flag       endp

write_reg       proc near                ;Aliohjelma, jolla kirjoitetaan
                pusha                    ;haluttua dataa AdLib:in rekisterei-
                MOV    AL,BL             ;hin
                MOV    DX,388h           ;
                OUT    DX,AL             ;bl = halutun rekisterin indeksi
                MOV    CX,6              ;bh = haluttu data
                WAIT1:
                IN     AL,DX
                LOOP   WAIT1
                MOV    DX,389h
                MOV    AL,BH
                OUT    DX,AL
                MOV    CX,35
                WAIT2:
                IN     AL,DX
                LOOP   WAIT2
                popa
                ret
write_reg       endp

reset_adlib     proc near                ;Resetoidaan AdLib kirjoittamalla
                pusha                    ;jokaiseen rekisteriin nollaa
                mov cx,244               ;
                xor bh,bh                ;Ei ehkä hienostunein tapa, mutta
                next:                    ;toimii 100 prosenttisesti... :)
                mov bl,cl
                call write_reg
                loop next
                popa
                ret
reset_adlib     endp


update_music    proc    near             ;Tämä aliohjelma hoitaa ajastimeen
                pusha                    ;kytkettynä musiikin soittamisen

                xor     BH,BH            ;Nuottien aika-arvot jne. löytyvät
                xor     ah,ah            ;adlib2.inc:istä
                mov     bl,cs:[offset nuotti]
                mov     al,cs:[offset savelet+bx]
                mov     di,ax
                mov     ah,cs:[offset ajat+bx]

                mov     bl,0a0h
                mov     bh,cs:[di+offset fnum] ;FNum ja octavenote ovat
                call    write_reg              ;valmiiksi laskettuina
                mov     bl,0b0h                ;adlib2.inc:issä
                mov     bh,cs:[di+offset octavenote]
                call    write_reg

                inc     byte ptr cs:[offset kohta]
                cmp     byte ptr cs:[offset kohta],ah ;Note allready played?
                jne     @ei_next_note
                mov     byte ptr cs:[offset kohta],0
                inc     byte ptr cs:[offset nuotti]
                cmp     byte ptr cs:[offset nuotti],16
                jne     @ei_next_note
                mov     byte ptr cs:[offset nuotti],0
                @ei_next_note:
                popa
                jmp     dword ptr cs:[offset wanha_timer] ;Kutsutaan vanhaa
update_music    endp                                      ;keskeytystä

hook_timer      proc    near             ;Tämä aliohjelma kytkee AdLib rutii-
                pusha                    ;nit ajastimeen
                mov     ax,08+35h*256
                int     21h
                mov     cs:[offset wanha_timer],bx
                mov     cs:[offset wanha_timer+2],es
                mov     ah,25h
                mov     al,8h
                mov     dx,offset update_music
                push    cs
                pop     ds
                int     21h
                popa
                ret
hook_timer      endp

unhook_timer    proc    near             ;Tämä aliohjelma irroittaa AdLib
                pusha                    ;rutiinit ajastimesta
                mov     ax,cs:[offset wanha_timer + 2]
                mov     ds,ax
                mov     ah,25h
                mov     dx,cs:[offset wanha_timer]
                mov     al,8h
                int     21h
                popa
                ret
unhook_timer    endp

update_teksti   proc    near             ;Tämä aliohjelma päivittää ruudulla
                pusha                    ;näkyvää tekstiä
                push    es
                push    ds
                mov     ax,0b800h
                mov     es,ax
                mov     ds,ax
                mov     di,cs:[offset txt_counter]
                mov     al,cs:[offset teksti+di]
                mov     ah,12
                mov     es:[20*160+158],ax
                mov     di,2+20*160
                mov     si,4+20*160
                mov     cx,156
                rep     movsb
                inc     word ptr cs:[offset txt_counter]
                cmp     word ptr cs:[offset txt_counter],55+80
                jle     ohi
                mov     word ptr cs:[offset txt_counter],0
                ohi:
                pop     ds
                pop     es
                popa
                ret
update_teksti     endp

include         adlib2.inc               ;Tiedosto, josta löytyvät nuottien
                                         ;aika-arvot jne.
lippu           label byte               ;Millaiseksi * ja + merkit muutetaan
                db 00000000b
                db 00000000b
                db 00000000b

                db 00011100b
                db 00011100b
                db 00011100b

                db 11111111b
                db 11111111b
                db 11111111b

                db 00011100b
                db 00011100b
                db 00011100b

                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b

                db 00000000b
                db 00000000b
                db 00000000b

                db 11111111b
                db 11111111b
                db 11111111b

                db 00000000b
                db 00000000b
                db 00000000b

                db 00000000b
                db 00000000b
                db 00000000b
                db 00000000b

nuotti          db 0
kohta           db 0

txt_counter     dw 0

stat_teksti     db 'SUOMI-INTRO 6.12.1994',0dh,0ah,'$'

teksti          label byte
                db "*+ Paljon onnea itsenäisenäiselle Suomelle 6.12.1994! *+"
                db 80 dup(?)

wanha_timer     dw ?,?

code    ends
        end main
