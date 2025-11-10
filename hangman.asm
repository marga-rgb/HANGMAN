; ==========================================================
; CTRL-ALT-DEFEAT - Hangman style game with ROBOT CORRUPTION
; TASM / MASM compatible (16-bit DOS)
; Modified: fixed jump out of range errors
; ==========================================================

.model small
.stack 100h
.data

; ---------- UI & Strings ----------
titleArt db 0Dh,0Ah
         db "  ____  _______ _   _    _    _    _   _ _____  ______ ",0Dh,0Ah
         db " / ___|| ____\ \ | |  / \  | |  | | | | |  ___||  ____|",0Dh,0Ah
         db "| |    |  _|  \ \| | / _ \ | |  | | | | | |_   | |__   ",0Dh,0Ah
         db "| |___ | |___  \   |/ ___ \| |__| |_| |_|  _|  |  __|  ",0Dh,0Ah
         db " \____||_____|  |_/_/   \_\_____\___/|_|_|    |_|     ",0Dh,0Ah
         db "                     CTRL - ALT - DEFEAT               ",0Dh,0Ah
         db "                 A HANGMAN ADVENTURE                   ",0Dh,0Ah
         db 0Dh,0Ah,"Press Z to Continue...$"

menu db 0Dh,0Ah,"Choose difficulty:",0Dh,0Ah
     db "1 - Easy (10 words)",0Dh,0Ah
     db "2 - Medium (5 words)",0Dh,0Ah
     db "3 - Hard (5 words)",0Dh,0Ah
     db "Q - Quit",0Dh,0Ah,"$"

newline db 0Dh,0Ah,"$"

maskLabel db 0Dh,0Ah,"Current Word: $"
guessedLabel db 0Dh,0Ah,"Guessed letters: $"
triesLabel db 0Dh,0Ah,"Remaining tries: $"
hintLabel db 0Dh,0Ah,"Hint: $"
scoreLabel db 0Dh,0Ah,"Score: $"
streakLabel db " | Streak: $"
statsLabel db 0Dh,0Ah,"Wins: $"
lossesLabel db " | Losses: $"

guessPrompt db 0Dh,0Ah,"Enter a letter (or '?' for hint): $"
alreadyMsg db 0Dh,0Ah,"You already guessed that letter!$"
wrongMsg db 0Dh,0Ah,"Incorrect! System integrity weakening...$"
rightMsg db 0Dh,0Ah,"Node repaired! +10 points!$"
reviveMsg db 0Dh,0Ah,"SYSTEM REBOOTING... ROBOT RESTORED!$"
winMsg   db 0Dh,0Ah,0Dh,0Ah,"SYSTEM RESTORED. UMBRELLA SAFE!$"
bonusMsg db 0Dh,0Ah,"Bonus points: $"
loseMsg  db 0Dh,0Ah,0Dh,0Ah,"FIREWALL BREACHED! UMBRELLA INFECTED.$"

; ---------- Win / Lose ASCII ----------
winArt db 0Dh,0Ah
       db "  ____  _   _ _   _ ___ _   _  ",0Dh,0Ah
       db " / ___|| | | | \ | |_ _| \ | | ",0Dh,0Ah
       db " \___ \| | | |  \| || ||  \| | ",0Dh,0Ah
       db "  ___) | |_| | |\  || || |\  | ",0Dh,0Ah
       db " |____/ \___/|_| \_|___|_| \_| ",0Dh,0Ah,"$"

loseArt db 0Dh,0Ah
       db "  _                      _     _ ",0Dh,0Ah
       db " | |    ___   __ _  __ _| | __| |",0Dh,0Ah
       db " | |   / _ \ / _` |/ _` | |/ _` |",0Dh,0Ah
       db " | |__| (_) | (_| | (_| | | (_| |",0Dh,0Ah
       db " |_____\___/ \__, |\__,_|_|\__,_|",0Dh,0Ah
       db "             |___/                ",0Dh,0Ah,"$"

; ---------- Word pools & hints ----------
easy1   db "CODE$"
easy1h  db "Basic unit of programming.$"
easy2   db "LOOP$"
easy2h  db "Repeats a block until condition.$"
easy3   db "JAVA$"
easy3h  db "Object-oriented language often used on JVM.$"
easy4   db "BUG$"
easy4h  db "An error in a program.$"
easy5   db "CLASS$"
easy5h  db "Blueprint for objects in OOP.$"
easy6   db "ARRAY$"
easy6h  db "Stores multiple values of same type.$"
easy7   db "LOGIC$"
easy7h db "Reasoning behind program decisions.$"
easy8   db "INPUT$"
easy8h db "Data received by the program.$"
easy9   db "OUTPUT$"
easy9h db "Data produced by the program.$"
easy10  db "STACK$"
easy10h db "LIFO data structure.$"

easyPtrs dw OFFSET easy1, OFFSET easy2, OFFSET easy3, OFFSET easy4, OFFSET easy5
        dw OFFSET easy6, OFFSET easy7, OFFSET easy8, OFFSET easy9, OFFSET easy10
easyHintsPtrs dw OFFSET easy1h, OFFSET easy2h, OFFSET easy3h, OFFSET easy4h, OFFSET easy5h
             dw OFFSET easy6h, OFFSET easy7h, OFFSET easy8h, OFFSET easy9h, OFFSET easy10h

medium1 db "POINTER$"
medium1h db "Variable storing an address.$"
medium2 db "METHOD$"
medium2h db "Function associated with an object.$"
medium3 db "STRING$"
medium3h db "Sequence of characters.$"
medium4 db "MODULE$"
medium4h db "A self-contained unit of code.$"
medium5 db "SYNTAX$"
medium5h db "Rules defining valid code.$"

mediumPtrs dw OFFSET medium1, OFFSET medium2, OFFSET medium3, OFFSET medium4, OFFSET medium5
mediumHintsPtrs dw OFFSET medium1h, OFFSET medium2h, OFFSET medium3h, OFFSET medium4h, OFFSET medium5h

hard1 db "ALGORITHM$"
hard1h db "Step-by-step method to solve a problem.$"
hard2 db "ENCAPSULATION$"
hard2h db "Hiding internal object details.$"
hard3 db "INHERITANCE$"
hard3h db "Acquiring traits from a parent class.$"
hard4 db "COMPILER$"
hard4h db "Translates source to executable.$"
hard5 db "POLYMORPHISM$"
hard5h db "Same interface, different implementations.$"

hardPtrs dw OFFSET hard1, OFFSET hard2, OFFSET hard3, OFFSET hard4, OFFSET hard5
hardHintsPtrs dw OFFSET hard1h, OFFSET hard2h, OFFSET hard3h, OFFSET hard4h, OFFSET hard5h

; ---------- Game buffers & state ----------
maskBuf db 128 dup('$')
wordPtr dw 0
hintPtr dw 0

guessedLetters db 26 dup(0)
guessCount db 0

tries db 6
hintUsed db 0

; ---------- Game stats ----------
score dw 0
streak db 0
totalWins dw 0
totalLosses dw 0

charBuf db 3

; ---------- ANSI Color codes ----------
colorReset db 27,"[0m$"
colorGreen db 27,"[32m$"
colorYellow db 27,"[33m$"
colorRed db 27,"[31m$"

; ---------- Borders ----------
borderTop db "============================================================$"
borderBottom db "============================================================$"

; ============================================================
; ROBOT STAGES - Full body, one definition each (ANSI colors embedded)
; robotN = N wrong guesses (tries = 6 - N)
; NOTE: color is NOT reset at the end
; ============================================================

; Stage 0 (0 wrong) - Healthy (Green)
robot0 db 27,"[32m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((O ))--((O ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  ____________  :_",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (_) (_) (_) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |        ||        |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; Stage 1 (1 wrong) - slight glitch (yellow)
robot1 db 27,"[33m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((O ))--((O ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  ____________  :_",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             | | ||::  .   ::|| | |",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (_) (_) (_) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |        ||        |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; Stage 2 (2 wrongs) - eyes flicker (yellow)
robot2 db 27,"[33m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((X ))--((O ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  ____________  :_",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             | | ||::  X   ::|| | |",0Dh,0Ah
       db "             | | ||::::::::::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (_) (_) (_) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |        ||        |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; Stage 3 (3 wrongs) - arm/torso glitch (red)
robot3 db 27,"[31m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((X ))--((X ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  _X_________X_  :_",0Dh,0Ah
       db "             | | ||::####::::|| | |",0Dh,0Ah
       db "             | | ||::  X   ::|| | |",0Dh,0Ah
       db "             | | ||::####::::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .--ERROR--. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (_) (_) (_) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |   X    ||   X    |",0Dh,0Ah
       db "              '---X----''---X----'",0Dh,0Ah
       db "$"

; Stage 4 (4 wrongs) - heavy corruption (red)
robot4 db 27,"[31m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((# ))--((X ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  ######ERROR### :_",0Dh,0Ah
       db "             | | ||::######::|| | |",0Dh,0Ah
       db "             | | ||::  X   ::|| | |",0Dh,0Ah
       db "             | | ||::######::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (XXXXX)(XXX)|| |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |  XXXXXX||  XXXXX |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; Stage 5 (5 wrongs) - near-dead (red)
robot5 db 27,"[31m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((# ))--((# ))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  ###########  :_",0Dh,0Ah
       db "             | | ||:########::|| | |",0Dh,0Ah
       db "             | | ||::  X   ::|| | |",0Dh,0Ah
       db "             | | ||:########::|| | |",0Dh,0Ah
       db "             |_| |/__________\| |_|",0Dh,0Ah
       db "               |________________|",0Dh,0Ah
       db "            __..-'            `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\______________/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  __  __  || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (XXXX)(XXX) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (___ X_)(X ___ )",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "              |  XXXXXXX|| XXXXX |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; Stage 6 (6 wrongs) - fully corrupted (red)
robot6 db 27,"[31m",0Dh,0Ah
       db "   ,--.    ,--.",0Dh,0Ah
       db "                 ((X ))--(( X))",0Dh,0Ah
       db "               ,'_`--'____`--'_`.",0Dh,0Ah
       db "              _:  XXXXXXXXXXXX  :_",0Dh,0Ah
       db "             | | ||XXXXXXXX::|| | |",0Dh,0Ah
       db "             | | ||::  X X ::|| | |",0Dh,0Ah
       db "             | | ||XXXXXXXX::|| | |",0Dh,0Ah
       db "             |_| |/XXXXXXXXXX\| |_|",0Dh,0Ah
       db "               |___  _   ____  |",0Dh,0Ah
       db "               |__ CORRUPTED __|",0Dh,0Ah
       db "            __..-'  SYSTEM FAIL  `-..__",0Dh,0Ah
       db "         .-| : .----------------. : |-.",0Dh,0Ah
       db "       ,\ || | |\__   XXXX   ___/| | || /.",0Dh,0Ah
       db "      /`.\:| | ||  __  XX  __ || | |;/,'\",0Dh,0Ah
       db "     :`-._\;.| || '--''--''--' || |,:/_.-':",0Dh,0Ah
       db "     |    :  | || .----------. || |  :    |",0Dh,0Ah
       db "     |    |  | || '----SSt---' || |  |    |",0Dh,0Ah
       db "     |    |  | ||   _   _   _  || |  |    |",0Dh,0Ah
       db "     :,--.;  | ||  (XXXX)(XXX) || |  :,--.;",0Dh,0Ah
       db "     (`-'|)  | ||______________|| |  (|`-')",0Dh,0Ah
       db "      `--'   | |/______________\| |   `--'",0Dh,0Ah
       db "             |____________________|",0Dh,0Ah
       db "              `.________________,'",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "               (_______)(_______)",0Dh,0Ah
       db "                /   X    X   \ ",0Dh,0Ah
       db "               |  XXXXXXXXXXXX |",0Dh,0Ah
       db "              '--------''--------'",0Dh,0Ah
       db "$"

; pointer table for robot stages
robotStages dw OFFSET robot0, OFFSET robot1, OFFSET robot2, OFFSET robot3
           dw OFFSET robot4, OFFSET robot5, OFFSET robot6

; ---------- End of data ----------
.code
start:
    mov ax,@data
    mov ds,ax

    call show_title
    call main_menu

    ; exit
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    mov ax,4C00h
    int 21h

; ---------- Title ----------
show_title proc
    mov ah,09h
    mov dx, OFFSET titleArt
    int 21h
waitZ:
    mov ah,01h
    int 21h
    cmp al,'Z'
    je clearTitle
    cmp al,'z'
    je clearTitle
    jmp waitZ
clearTitle:
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    ret
show_title endp

; ---------- Menu ----------
main_menu proc
menu_loop:
    ; display stats
    mov ah,09h
    mov dx, OFFSET statsLabel
    int 21h
    mov ax, [totalWins]
    call print_number
    mov ah,09h
    mov dx, OFFSET lossesLabel
    int 21h
    mov ax, [totalLosses]
    call print_number
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    
    mov ah,09h
    mov dx, OFFSET menu
    int 21h
    mov ah,01h
    int 21h
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    cmp al,'1'
    je do_easy
    cmp al,'2'
    je do_medium
    cmp al,'3'
    je do_hard
    cmp al,'Q'
    je menu_quit
    cmp al,'q'
    je menu_quit
    jmp menu_loop

do_easy:
    call start_easy
    jmp menu_loop
do_medium:
    call start_medium
    jmp menu_loop
do_hard:
    call start_hard
    jmp menu_loop

menu_quit:
    ret
main_menu endp

; ---------- Random index via INT 1Ah ----------
get_random_index proc
    push cx
    push bx
    mov ah,0
    int 1Ah
    mov bl, dl
    mov cl, al   ; input pool size
    cmp cl,0
    je gi_zero
gi_mod_loop:
    cmp bl, cl
    jb gi_done
    sub bl, cl
    jmp gi_mod_loop
gi_done:
    mov al, bl
    pop bx
    pop cx
    ret
gi_zero:
    xor al, al
    pop bx
    pop cx
    ret
get_random_index endp

; ---------- Select pointer from table ----------
; inputs: BX=index, SI=offset table
; output: DX=pointer to string
select_from_table proc
    push ax
    push si
    mov ax, bx
    shl ax,1
    add si, ax
    mov dx, [si]
    pop si
    pop ax
    ret
select_from_table endp

; ---------- Start easy ----------
start_easy proc
    mov al,10
    call get_random_index
    mov bx, ax
    mov si, OFFSET easyPtrs
    call select_from_table
    mov wordPtr, dx
    mov si, OFFSET easyHintsPtrs
    call select_from_table
    mov hintPtr, dx
    mov byte ptr [tries], 6
    mov byte ptr [hintUsed], 1
    call setup_round
    ret
start_easy endp

; ---------- Start medium ----------
start_medium proc
    mov al,5
    call get_random_index
    mov bx, ax
    mov si, OFFSET mediumPtrs
    call select_from_table
    mov wordPtr, dx
    mov si, OFFSET mediumHintsPtrs
    call select_from_table
    mov hintPtr, dx
    mov byte ptr [tries], 6
    mov byte ptr [hintUsed], 0
    call setup_round
    ret
start_medium endp

; ---------- Start hard ----------
start_hard proc
    mov al,5
    call get_random_index
    mov bx, ax
    mov si, OFFSET hardPtrs
    call select_from_table
    mov wordPtr, dx
    mov si, OFFSET hardHintsPtrs
    call select_from_table
    mov hintPtr, dx
    mov byte ptr [tries], 6
    mov byte ptr [hintUsed], 0
    call setup_round
    ret
start_hard endp

; ---------- Setup round ----------
setup_round proc
    push cx
    push di
    push si
    
    mov cx,26
    lea di, guessedLetters
clearG:
    mov byte ptr [di],0
    inc di
    loop clearG
    mov byte ptr [guessCount],0

    ; build mask from word
    mov si, wordPtr
    lea di, maskBuf
maskloop:
    mov al, [si]
    cmp al,'$'
    je maskdone
    mov byte ptr [di],'_'
    inc si
    inc di
    jmp maskloop
maskdone:
    mov byte ptr [di], '$'

    ; if easy, show hint
    cmp byte ptr [hintUsed],1
    je skip_hint_check
    jmp skip_hint
skip_hint_check:
    mov ah,09h
    mov dx, OFFSET hintLabel
    int 21h
    mov ah,09h
    mov dx, hintPtr
    int 21h
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
skip_hint:
    call game_loop
    
    pop si
    pop di
    pop cx
    ret
setup_round endp

; ---------- Show robot stage ----------
; input: AL = current tries (0..6)
; computes idx = 6 - AL and prints robotStages[idx]
show_robot_stage proc
    push ax
    push bx
    push si
    push dx
    mov bl, al        ; bl = tries
    mov al,6
    sub al, bl        ; al = idx (0..6)
    xor ah, ah
    mov bx, ax
    shl bx,1
    mov si, OFFSET robotStages
    add si, bx
    mov dx, [si]
    mov ah,09h
    int 21h
    ; newline
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    pop dx
    pop si
    pop bx
    pop ax
    ret
show_robot_stage endp

; ---------- Display colored border ----------
; Input: AL = current tries (0..6)
show_border proc
    push ax
    push dx
    
    ; determine color based on tries
    cmp al, 5
    jae border_green    ; 5-6 tries = green
    cmp al, 3
    jae border_yellow   ; 3-4 tries = yellow
    jmp border_red      ; 0-2 tries = red
    
border_green:
    mov ah, 09h
    mov dx, OFFSET colorGreen
    int 21h
    jmp display_border
    
border_yellow:
    mov ah, 09h
    mov dx, OFFSET colorYellow
    int 21h
    jmp display_border
    
border_red:
    mov ah, 09h
    mov dx, OFFSET colorRed
    int 21h
    
display_border:
    ; display top border
    mov ah, 09h
    mov dx, OFFSET borderTop
    int 21h
    mov dx, OFFSET newline
    int 21h
    
    pop dx
    pop ax
    ret
show_border endp

; ---------- Close border ----------
close_border proc
    push ax
    push dx
    
    ; get current tries for color
    mov al, [tries]
    cmp al, 5
    jae close_green
    cmp al, 3
    jae close_yellow
    
    mov ah, 09h
    mov dx, OFFSET colorRed
    int 21h
    jmp do_close
    
close_yellow:
    mov ah, 09h
    mov dx, OFFSET colorYellow
    int 21h
    jmp do_close
    
close_green:
    mov ah, 09h
    mov dx, OFFSET colorGreen
    int 21h
    
do_close:
    mov ah, 09h
    mov dx, OFFSET borderBottom
    int 21h
    mov dx, OFFSET colorReset
    int 21h
    mov dx, OFFSET newline
    int 21h
    
    pop dx
    pop ax
    ret
close_border endp

; ---------- Sound effects ----------
play_beep proc
    ; Input: AL = frequency (1=low, 2=mid, 3=high)
    push ax
    push bx
    push cx
    
    cmp al, 1
    je beep_low
    cmp al, 2
    je beep_mid
    jmp beep_high
    
beep_low:
    mov bx, 800    ; lower frequency
    jmp do_beep
beep_mid:
    mov bx, 1200   ; mid frequency
    jmp do_beep
beep_high:
    mov bx, 2000   ; higher frequency
    
do_beep:
    in al, 61h
    or al, 00000011b
    out 61h, al
    
    mov cx, bx
beep_loop:
    loop beep_loop
    
    in al, 61h
    and al, 11111100b
    out 61h, al
    
    pop cx
    pop bx
    pop ax
    ret
play_beep endp

; ---------- Print number ----------
; Input: AX = number to print
print_number proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne divide_loop
    
print_digits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

; ---------- Game loop ----------
game_loop proc
game_start:
    ; show colored border
    mov al, [tries]
    call show_border
    
    ; show robot according to current tries
    mov al, [tries]
    call show_robot_stage

    ; print mask
    mov ah,09h
    mov dx, OFFSET maskLabel
    int 21h
    mov ah,09h
    mov dx, OFFSET maskBuf
    int 21h

    ; remaining tries
    mov ah,09h
    mov dx, OFFSET triesLabel
    int 21h
    mov al, [tries]
    add al,'0'
    mov byte ptr [charBuf], al
    mov byte ptr [charBuf+1],'$'
    mov ah,09h
    mov dx, OFFSET charBuf
    int 21h

    mov ah,09h
    mov dx, OFFSET newline
    int 21h

    ; show score and streak
    mov ah,09h
    mov dx, OFFSET scoreLabel
    int 21h
    mov ax, [score]
    call print_number
    mov ah,09h
    mov dx, OFFSET streakLabel
    int 21h
    mov al, [streak]
    xor ah, ah
    call print_number

    ; guessed letters
    mov ah,09h
    mov dx, OFFSET guessedLabel
    int 21h

    mov cl, [guessCount]
    mov ch, 0
    cmp cl, 0
    je no_guessed
    xor si, si

print_gl:
    mov dl, [guessedLetters+si]
    mov ah,02h
    int 21h

    ; increment index and check if we reached the count
    inc si
    cmp si, cx
    je after_pg

    mov dl, ','
    mov ah,02h
    int 21h
    mov dl, ' '
    mov ah,02h
    int 21h
    jmp print_gl

after_pg:
    jmp post_guessed

no_guessed:
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
post_guessed:
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    
    ; close colored border
    call close_border

    ; prompt
    mov ah,09h
    mov dx, OFFSET guessPrompt
    int 21h

    mov ah,01h
    int 21h
    mov bl, al          ; save character in BL instead
    mov ah,09h
    mov dx, OFFSET newline
    int 21h

    ; uppercase
    mov al, bl
    cmp al,'a'
    jb skip_case
    cmp al,'z'
    ja skip_case
    sub al,32
    mov bl, al      ; save uppercase character back to BL
skip_case:

    ; check hint request '?'
    cmp bl,'?'
    je check_hint
    jmp not_hint
    
check_hint:
    cmp byte ptr [hintUsed],0
    je give_hint
    jmp hint_used

give_hint:
    mov ah,09h
    mov dx, OFFSET hintLabel
    int 21h
    mov ah,09h
    mov dx, hintPtr
    int 21h
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    mov byte ptr [hintUsed],1
    jmp game_start

hint_used:
    jmp game_start

not_hint:
    mov al, bl
    cmp al,'A'
    jb skip_to_invalid
    cmp al,'Z'
    ja skip_to_invalid
    jmp valid_letter
skip_to_invalid:
    jmp game_start
valid_letter:
    ; repeated check
    mov cl, [guessCount]
    mov ch, 0
    xor si, si
    cmp cl,0
    je not_repeat

repeat_loop:
    mov al, [guessedLetters+si]
    cmp al, bl
    je already
    inc si
    cmp si, cx
    jb repeat_loop
    jmp not_repeat

already:
    mov ah,09h
    mov dx, OFFSET alreadyMsg
    int 21h
    jmp game_start

not_repeat:
    ; store guessed letter
    mov al, [guessCount]
    xor ah, ah
    mov si, ax
    mov byte ptr [guessedLetters+si], bl
    inc byte ptr [guessCount]

    ; search and reveal
    mov dl, bl          ; save character in DL for comparison
    mov si, wordPtr
    lea di, maskBuf
    mov bl, 0           ; BL = flag (0 = not found, 1 = found)
scan_loop:
    mov al, [si]
    cmp al,'$'
    je scan_done
    cmp al, dl          ; compare with saved character in DL
    jne scan_next
    mov byte ptr [di], al
    mov bl, 1           ; mark as found
scan_next:
    inc si
    inc di
    jmp scan_loop
scan_done:
    cmp bl,1
    je right
    ; wrong
    mov al, 1          ; play low beep
    call play_beep
    mov ah,09h
    mov dx, OFFSET wrongMsg
    int 21h
    mov byte ptr [streak], 0   ; reset streak
    mov al, [tries]
    dec al
    mov byte ptr [tries], al
    cmp al, 0
    jle jump_to_lost
    jmp game_start
    
jump_to_lost:
    jmp lost

right:
    mov al, 3          ; play high beep
    call play_beep
    mov ah,09h
    mov dx, OFFSET rightMsg
    int 21h
    ; add points
    mov ax, [score]
    add ax, 10
    mov [score], ax
    ; increase streak
    inc byte ptr [streak]

    ; check if mask complete
    lea si, maskBuf
ckmask:
    mov al, [si]
    cmp al, '$'
    je win
    cmp al, '_'
    je cont
    inc si
    jmp ckmask
cont:
    jmp game_start

win:
    mov al, 3          ; victory sound
    call play_beep
    call play_beep
    
    ; RESET ROBOT COLOR TO GREEN!
    mov ah,09h
    mov dx, OFFSET colorGreen
    int 21h
    mov ah,09h
    mov dx, OFFSET reviveMsg
    int 21h
    
    ; show healthy robot
    mov al, 6          ; full health
    call show_robot_stage
    
    ; calculate bonus (tries * 20)
    mov al, [tries]
    xor ah, ah
    mov bx, 20
    mul bx
    add [score], ax
    
    mov ah,09h
    mov dx, OFFSET winMsg
    int 21h
    mov ah,09h
    mov dx, OFFSET bonusMsg
    int 21h
    mov al, [tries]
    xor ah, ah
    mov bx, 20
    mul bx
    call print_number
    mov ah,09h
    mov dx, OFFSET winArt
    int 21h
    
    ; update stats
    inc word ptr [totalWins]
    
    mov ah,09h
    mov dx, OFFSET statsLabel
    int 21h
    mov ax, [totalWins]
    call print_number
    mov ah,09h
    mov dx, OFFSET lossesLabel
    int 21h
    mov ax, [totalLosses]
    call print_number
    
    ; reset colors
    mov ah,09h
    mov dx, OFFSET colorReset
    int 21h
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    ret

lost:
    mov al, 1          ; defeat sound
    call play_beep
    
    ; show final corrupted robot and lose text
    mov ah,09h
    mov dx, OFFSET loseMsg
    int 21h
    mov al, 0
    call show_robot_stage ; will show stage 6 because tries=0 -> idx=6
    mov ah,09h
    mov dx, OFFSET loseArt
    int 21h
    
    ; update stats
    inc word ptr [totalLosses]
    
    mov ah,09h
    mov dx, OFFSET statsLabel
    int 21h
    mov ax, [totalWins]
    call print_number
    mov ah,09h
    mov dx, OFFSET lossesLabel
    int 21h
    mov ax, [totalLosses]
    call print_number
    
    ; reset colors
    mov ah,09h
    mov dx, OFFSET colorReset
    int 21h
    mov ah,09h
    mov dx, OFFSET newline
    int 21h
    ret

game_loop endp

end start