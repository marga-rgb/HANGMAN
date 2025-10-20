;===========================================================
; Group 3:
; Name: Barnuevo, Charles Lawrence
; Garcia, Christen Nicole 
; Ridao, Sean Ulrich
; Rosales, Azeckah Claire
; Santos, Ferdinan Alexandr 
; Solomon, Margarette Ashly
; Description: "Ctrl-Alt-Defeat" – Hangman-style game 
; 
;===========================================================

.model small
.stack 100h
.data

intro db "=== Ctrl-Alt-Defeat ===",0Dh,0Ah
       db "You are Mr.Robot, the AI defender of UMBRELLA.",0Dh,0Ah
       db "Stop ELMON.exe by guessing programming terms!",0Dh,0Ah,"$"

menu db 0Dh,0Ah,"Choose difficulty:",0Dh,0Ah
     db "1 - Easy",0Dh,0Ah
     db "2 - Medium",0Dh,0Ah
     db "3 - Hard",0Dh,0Ah,"$"

easyWord  db "CODE$"
easyMask  db "____$"
easyHint  db "Hint: Basic unit of programming.$"

mediumWord db "ARRAY$"
mediumMask db "_____$"
mediumHint db "Hint: Stores multiple values of same type.$"

hardWord  db "ALGORITHM$"
hardMask  db "_________$"
hardHint  db "Hint: Step-by-step process to solve a problem.$"

tries db 6
guessMsg db 0Dh,0Ah,"Enter a letter: $"
wrongMsg db 0Dh,0Ah,"Incorrect! System integrity weakening...$"
rightMsg db 0Dh,0Ah,"Node repaired! Good work.$"
winMsg   db 0Dh,0Ah,0Dh,0Ah,"SYSTEM RESTORED. UMBRELLA SAFE!$"
loseMsg  db 0Dh,0Ah,0Dh,0Ah,"FIREWALL BREACHED! UMBRELLA INFECTED.$"
maskLabel db 0Dh,0Ah,"Current Word: $"
hintLabel db 0Dh,0Ah,"$"
newline db 0Dh,0Ah,"$"

.code
main proc
    mov ax,@data
    mov ds,ax

    ; Intro
    mov ah,09h
    mov dx, OFFSET intro
    int 21h

    ; Menu
    mov ah,09h
    mov dx, OFFSET menu
    int 21h

    ; Get choice
    mov ah,01h
    int 21h
    sub al,'0'

    cmp al,1
    je level_easy
    cmp al,2
    je level_medium
    cmp al,3
    je level_hard
    jmp exit_game

;===================== LEVEL EASY =====================
level_easy:
    mov si, OFFSET easyWord
    mov di, OFFSET easyMask
    mov dx, OFFSET easyHint
    jmp start_level

;===================== LEVEL MEDIUM ===================
level_medium:
    mov si, OFFSET mediumWord
    mov di, OFFSET mediumMask
    mov dx, OFFSET mediumHint
    jmp start_level

;===================== LEVEL HARD =====================
level_hard:
    mov si, OFFSET hardWord
    mov di, OFFSET hardMask
    mov dx, OFFSET hardHint
    jmp start_level

;===================== GAME LOGIC =====================
start_level:
    ; print hint label
    mov ah,09h
    mov dx, OFFSET hintLabel
    int 21h
    ; print the actual hint (DX was set in level selection)
    mov ah,09h
    int 21h

    ; set tries = 6
    mov al, 6
    mov [tries], al

game_loop:
    ; show "Current Word:"
    mov ah,09h
    mov dx, OFFSET maskLabel
    int 21h

    
    mov ah,09h
    mov dx, di
    int 21h

    ; prompt
    mov ah,09h
    mov dx, OFFSET guessMsg
    int 21h

    ; read a char
    mov ah,01h
    int 21h
    mov bl, al

    ; convert lowercase to uppercase
    cmp bl,'a'
    jb skip_case
    cmp bl,'z'
    ja skip_case
    sub bl,32
skip_case:

    ; search through word and update mask
    push si
    push di
    mov dl,0            ; found flag = 0

check_letters:
    mov al, [si]
    cmp al, '$'
    je done_check
    cmp al, bl
    jne next_char
    mov [di], al
    mov dl, 1
next_char:
    inc si
    inc di
    jmp check_letters
done_check:
    pop di
    pop si

    cmp dl,1
    je correct_guess

    
    mov ah,09h
    mov dx, OFFSET wrongMsg
    int 21h
    
    mov al, [tries]
    dec al
    mov [tries], al
    cmp al, 0
    jle game_over
    jmp cont_game

correct_guess:
    mov ah,09h
    mov dx, OFFSET rightMsg
    int 21h

cont_game:
  
    mov bx, di
check_mask:
    mov al, [bx]
    cmp al, '_'
    je not_complete
    cmp al, '$'
    je win_level
    inc bx
    jmp check_mask

not_complete:
    jmp game_loop

win_level:
    mov ah,09h
    mov dx, OFFSET winMsg
    int 21h
    jmp exit_game

game_over:
    mov ah,09h
    mov dx, OFFSET loseMsg
    int 21h

exit_game:
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    mov ax,4C00h
    int 21h
main endp
end main
