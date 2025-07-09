IDEAL
p386
MODEL large
STACK 100h
DATASEG
	
;==========================================================================================================
;---------------------------------------------DATA-variables-----------------------------------------------
;==========================================================================================================

;----------------------------color 
colors db 0
savedcolor db 3
currentColor db 6
col db 0
colorg db 23 dup(?) 
;------------------------------ x ,y
x dw 0           
y dw 0
centerX DW 160    
centerY DW 100    
 x_pos DW 0
 y_pos DW 0	
savethisx dw 0
savethisy dw 0	
lastx dw 0
lasty dw 0
;----------------------------- Draw until
until dw 50
untilcw dw 50
;----------------------------- Msg 	
msg db 'Enter a color please (num)',10,13,'$' 
mrad db 'Enter the brushs size: ',10,13,'$'
MsgFile1 db  'Enter the name of the picture , make ',10,13,'sure to add ".bmp" after the file name, with no space:',10,13,'ATTENTION: the "starting color" might be ',10,13,'different so press twice the key "m" ',10,13,'$';
msgersize db 'Enter the size of the eraser: ',10,13,'$'
SaveMsgWarning db 'ATTENTION!',10,13,'The image will be saved in C:\tasm\bin',10,13,'If theres any image named saved.bmp the new pic will ovveride it! ',10,13,10,13,10,13,'-Press any key to continue-','$'
SaveMsg db 'Image Saved!',10,13,10,13,'-Press any key to continue-$'
;---------------------------- Image Files
filename db 'tmp.bmp',0
filename1 db 'Menu.bmp',0
filename2 db 'KeyBinds.bmp',0
filename3 db 'Colorks.bmp',0
filename4 db 23 dup(?)
filename5 db 'Delay.bmp',0
filename6 db 'tool.bmp',0
saveFilename db 'saved.bmp', 0
ErrorMsg db 'Error',10,13,'$'
;---------------------------- Radius\size 
rad dw 23 dup(?)
radius  DW 3     
savedradius dw 3
eraserradius dw 3
erasize dw 23 dup(?)
;---------------------------- Tool 
mode db 0 ; 0 for brush size , 1 for eraser size 
tool db 0;0 for brush , 1 for eraser
;---------------------------- Main loop 
options db 0 ; 0-lobby, 1 - menu , 2 -keybinds ,3-color, 4 canvas
lastclick dw 0
loopnum dw 1
countkey db 0
savebx dw 0
savedx dw 0
;---------------------------- Circle 
decision DW 0
screenWidth DW 320
screenHeight DW 200
;---------------------------- String/Acsii
numStr    DB 6 DUP(0)  ; Max 5 digits + 1 for '$' terminator
tempBuf   DB 5 DUP(?)  ; Temporary buffer for digits 
;---------------------------- Files
ScrLine db 320 dup (0)
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
;---------------------------- Timer
Clock equ es:6Ch
;---------------------------- Undo Proc 
undoAvailable dw 0    
;---------------------------- Screen Arrays      
FARDATA
pixelArray DB 64000 DUP(246)  
ends

segment FARDATA2
undoBuffer DB 64000 DUP(246) 

CODESEG
	
;==========================================================================================================
;--------------------------------------------------Code---------------------------------------------------
;==========================================================================================================

start:
;-------------------------------  Set up segments
	mov ax, @data
	mov ds, ax
	
	mov ax, SEG pixelArray
	mov es, ax
	
	mov ax,seg undoBuffer
	mov fs ,ax 
;------------------------------- 1st screen -Starter 
	mov [options],0
	call  far ptr GraphicsMode
    call  far ptr OpenFile
    call far ptr ShowImage		
;------------------------------- Set up the Mouse 
	
	mov ax,0h   
	int 33h
	mov ax,1h  
	int 33h
		
;==========================================================================================================
;------------------------------------------------Main-Loop-------------------------------------------------
;==========================================================================================================
	MouseLocation:       
	mov ax , 3h
	int 33h
	mov [savebx], bx
	mov bx,2
	mov ax, cx
	mov [savedx],dx
	mov dx ,0
	div bx
	mov bx, [savebx]
	mov dx, [savedx]
	
	mov [centerx],ax
	mov [centery], dx
	
	;priorotize keyboard
	 mov ah, 1
    int 16h
	jz checkmouse
    mov ah, 0
    int 16h
	cmp ah,1h
	jne afterexit
	
  MOV AX, 0003h
    INT 10h
    mov ax, 4c00h
	int 21h
	
	
	afterexit:
	 cmp ah, 32h   ; m key
    jne  checkK
	cmp [options],2
	je  checkK
	cmp [options],0
	je checkmouse
	cmp [countkey],0
	jne nextstage
	
	call  far ptr HideMouse
	call  far ptr SaveScreenToArray
	

	call  far ptr ShowMouse
	mov [options],1
	inc [countkey]
	jmp setscree
     nextstage:
	call far ptr HideMouse
	  mov [loopnum],1
	  call far ptr CloseFile
	  call far ptr PicDelay
	  call far ptr CloseFile
	  call far ptr CopyPal
	   mov [options],4
	   call  far ptr PrintArrayToScreen
	   call  far ptr ShowMouse
	  mov [countkey],0
	  jmp MouseLocation
	 setscree:
    call far ptr PicDelay
	  call far ptr CloseFile
	   mov [options], 1
    call  far ptr OpenFile
   call far ptr ShowImage	
   jmp MouseLocation
CheckK:
    cmp [options],2
	je ck
	cmp [options],4
	jne MouseLocation
	ck:
    cmp ah, 25h      ; K key
    jne CheckUndo
	
	cmp [countkey],0
	jne nextstages
	call  far ptr HideMouse
	call  far ptr SaveScreenToArray
	 call  far ptr ShowMouse
	mov [options],2
	inc [countkey]
	jmp setscre
     nextstages:
	  mov [options],4
	 call far ptr CopyPal
	 mov [loopnum],1
	 call far ptr HideMouse
	   call  far ptr PrintArrayToScreen
	   call  far ptr ShowMouse
	  mov [countkey],0
	 jmp MouseLocation
	  setscre:
    mov [options], 2
    call  far ptr CloseFile  
   call far ptr  OpenFile
   call far ptr ShowImage	
	jmp MouseLocation
	CheckUndo:
	cmp [options],4
	jne MouseLocation
    cmp ah, 16h      ; U key 
    jne MouseLocation
    
	call far ptr HideMouse
    call FAR PTR undo 
	call far ptr PrintArrayToScreen
	call far ptr ShowMouse
	mov [loopnum],1
	
	jmp MouseLocation
	checkmouse:
	cmp [savebx],1 
	je printpixel
	mov [lastclick],0
	jmp MouseLocation
	printpixel:
	cmp [options],4
	jne lobbycheck
	cmp [loopnum],1
	jne justprint
	mov cx ,[centerx]
	mov [lastx],cx
	mov cx ,[centery]
	mov [lasty],cx
	justprint:
	cmp [lastclick],0
	jne crcle

	call far ptr Save_Undo
	crcle:
	CALL  far ptr DrawFilledCircle
	mov cx, [centerx]
	mov [savethisx],cx
	mov cx, [centery]
	mov [savethisy],cx  
	
	mov cx, [lastx]
	mov [centerx], cx
	mov cx, [lasty]
	mov [centery], cx
	CALL  far ptr DrawFilledCircle
	
	
	mov cx, [savethisx]
	mov [lastx],cx
	mov cx, [savethisy]
	mov [lasty],cx
	
	lastc:
	mov [lastclick],1
	inc [loopnum]
	jmp MouseLocation
	
	lobbycheck:
	cmp [options],0
	jne menus
	
	cmp [centery],64
	jl MouseLocation ; no  more buttons
	cmp [centery],108
	jg ImportImage
	cmp [centerx],71
	jl MouseLocation
	cmp[centerx],244
	jg MouseLocation
	;new project button
	
	
	call far ptr CloseFile
	call far ptr PicDelay
	call far ptr CloseFile  
	call far ptr CopyPal
	call far ptr HideMouse
	call far ptr PrintArrayToScreen
    call far ptr ShowMouse
	mov [options],4
	jmp MouseLocation
	ImportImage:
	;Import an image button
	cmp [centery],115
	jl MouseLocation
	cmp [centery],159
	jg MouseLocation
	cmp [centerx],71
	jl MouseLocation
	cmp [centerx],244
	jg MouseLocation
 
	call far ptr CloseFile
	call far ptr TextMode
call far ptr GraphicsMode
	mov dx, offset MsgFile1 ; Console.WriteLine
	mov ah , 9h
	int 21h
	
	mov dx,offset filename4  
	call far ptr ReadLine
	  
	
	  mov bx, dx                
        mov al, [bx+1]            
        mov ah, 0                
        add bx, ax               
        add bx, 2               
        mov [byte ptr bx], 0      
	
	call far ptr CloseFile
	call far ptr PicDelay
	call far ptr CloseFile
	
	mov [options],5
   call far ptr  OpenFile
   call far ptr ShowMouse
   jc prnt
   call far ptr ShowImage	
   mov [options],4
   jmp MouseLocation
   prnt:
	mov [options],4
	call far ptr CopyPal
	call far ptr HideMouse
	call far ptr PrintArrayToScreen

	 call far ptr ShowMouse
	jmp MouseLocation
	menus:
	cmp [options],1
	jne keys
	
	;check for select tool
	cmp [centery],39
	jl MouseLocation
	cmp [centery],101
	jg ToolSize
	cmp [centerx],7 ;71
	jl MouseLocation
    cmp [centerx],71
    jg CheckEraser
	
	mov [tool],0
	mov al, [savedcolor]
    mov [currentColor],al
	mov ax, [savedradius]
	mov [radius],ax
	
	call far ptr CloseFile
	call far ptr PicDelay
	mov [countkey],1
	jmp far ptr nextstages
	jmp MouseLocation
	CheckEraser:
	cmp [centerx],119
	jl MouseLocation
	cmp [centerx],184
	jg SAVEIM

	er:
	cmp [tool],1
	je nextstage
	mov ax, [radius]
	mov [savedradius],ax
	mov ax , [eraserradius]
	mov [radius],ax
	setcolor:
	mov al ,[currentColor]
	mov [savedcolor],al
		mov [currentColor],246
	mov [tool],1
	j:
	call far ptr CloseFile
	call far ptr PicDelay
	mov [countkey],1
	jmp far ptr nextstages
	ToolSize:
	cmp [centery],110 
	jl MouseLocation
	cmp [centery],137
	jg ChooseAColor
	cmp [centerx],107 ;brush size 
	jg ErSize
	call far ptr CloseFile
	call far ptr PicDelay
	call far ptr CloseFile
	mov [options],8
	 call far ptr  OpenFile
    call far ptr ShowImage	

	mov ax, [savedradius]
	mov [untilcw],ax
		  CALL far ptr ConvertToASCII	   
  call far ptr PrintCenter
     MOV AH, 09h
    MOV DX, OFFSET numStr
    INT 21h
	
	mov ax, [savedradius]
	add ax,32
	mov [until],ax
	call far ptr DrawUntil
	mov [mode],0
	jmp MouseLocation
	ErSize:
	cmp [centerx],119
	jl MouseLocation
	cmp [centerx] ,194
	jg MouseLocation
	call far ptr CloseFile
	call far ptr PicDelay
	call far ptr CloseFile
	
	mov [options],8
	 call far ptr  OpenFile
    call far ptr ShowImage	
  
   mov ax, [eraserradius]
	mov [untilcw],ax
		  CALL far ptr ConvertToASCII
	 call far ptr PrintCenter
   
     MOV AH, 09h
    MOV DX, OFFSET numStr
    INT 21h
	
	mov ax, [eraserradius]
	add ax,32
	mov [until],ax
	call far ptr DrawUntil
	mov [mode],1
	jmp MouseLocation
	ChooseAColor:
	cmp [centery],145
	jl MouseLocation
	cmp [centery],175
	jg MouseLocation
	cmp [centerx],132
	jg MouseLocation
	call far ptr CloseFile
	call far ptr PicDelay
	
	
	call far ptr CloseFile
	mov [options],3
	 call far ptr  OpenFile
  call far ptr ShowImage	
   
   
	;;buttons and actions....
	jmp MouseLocation
	SAVEIM:
	cmp [centerx],212
	jl MouseLocation
	cmp [centerx],278
	jg MouseLocation
	
	call far ptr TextMode
	call Far ptr GraphicsMode
	
	 MOV AH, 09h
    MOV DX, OFFSET SaveMsgWarning
    INT 21h
	
	mov ah,1
	int 21h
	
	call far ptr SaveToBMP
	call far ptr TextMode
	call far ptr GraphicsMode
	
	 MOV AH, 09h
    MOV DX, OFFSET SaveMsg
    INT 21h
	
	mov ah,1
	int 21h
	call far ptr CloseFile
	 call far ptr  OpenFile
	 call far ptr ShowImage	
	
	jmp MouseLocation
	keys:
	cmp [options],2
	jne colorss
	;;buttons and actions....
	jmp MouseLocation
	colorss:
	cmp [options],3
	jne canvascolorchecker
	
	cmp [centery],169
	jl CheckColor
	
	cmp [centerx], 100
	jg CanvasColor
	call far ptr CloseFile
	
	
	mov [options],1
	 call far ptr  OpenFile
   call far ptr ShowImage	
	
	jmp mous
	CanvasColor:
	cmp [centerx],140
	jg CustomColor
	call far ptr CloseFile
	call far ptr PicDelay
	mov [options],7
	call far ptr CloseFile
	call far ptr CopyPal
	call far ptr HideMouse
	call far ptr PrintArrayToScreen

	call far ptr ShowMouse
	jmp  MouseLocation
	jmpmous:
	jmp mous
	CustomColor:
	call far ptr CloseFile
	call far ptr TextMode
	call far ptr GraphicsMode
	
	
	
	mov dx, offset msg ; Console.WriteLine
	mov ah , 9h
	int 21h
	mov dx, offset colorg  ; Console.ReadLine (in order to choose a color)
	call  far ptr ReadLine
	
	
	mov si, offset colorg ; get color and convert to a num
	add si,2
	call far ptr ConvertStringToNum

	mov [savedcolor], al
    cmp[tool],0
	jne setupscreen
    mov [currentColor],al	
	
	setupscreen:
	 call far ptr  OpenFile
   call far ptr ShowImage	
	call far ptr ShowMouse
	jmp MouseLocation
	CheckColor:
	dec [centerx]
	dec [centery]
	call far ptr GetColor
	;mov [savecolor],al 
	
	cmp al,0
	je coords
	mov [savedcolor],al
	cmp [tool],0
	jne gobacktomenu
	mov [currentColor],al
	jmp gobacktomenu
	coords:
	cmp [centery],129 
	jl MouseLocation
	cmp [centery],145
	jg MouseLocation
	cmp [centerx],162
	jl MouseLocation
	cmp [centerx],178
	jg MouseLocation
	mov [savedcolor],al
	cmp [tool],0
	jne gobacktomenu
	mov [currentColor],al
	;;buttons and actions....
	
	gobacktomenu:
	call far ptr CloseFile
	call far ptr PicDelay
	
	call far ptr CloseFile
	mov [options],1
	 call far ptr  OpenFile
    call far ptr ShowImage	
   jmp mous
   canvascolorchecker:
   cmp [options],7
   jne RadiusSelector
   mov ax,320
   imul [centery]
   add ax,[centerx]
   ; index in arr : (320*centery)+centerx
   mov si ,ax 
  mov al ,[es:si]
   mov [savedcolor],al
	cmp [tool],0
	jne scrs
	mov [currentColor],al
	call far ptr PicDelay
	scrs:
	mov [options],3
	 call far ptr  OpenFile
    call far ptr ShowImage	
   jmp mous
   
   RadiusSelector:
   cmp [centery],165
	jl runtil
	cmp [centery],182
	jg MouseLocation
	cmp [centerx],89
	jg customval
	cmp [centerx],21
	jl MouseLocation
	call far ptr CloseFile
	call far ptr PicDelay
	call far ptr CloseFile
	mov [options],1 
	 call far ptr  OpenFile
  call far ptr ShowImage	
   
	jmp mous
	customval:
	cmp [centerx],184
	jl MouseLocation
	cmp [centerx],308
	jg MouseLocation
	call far ptr CloseFile
	call far ptr TextMode
	call far ptr GraphicsMode
	
	cmp [mode],0
	jne erasercustom
	mov dx, offset mrad ; Console.WriteLine
	mov ah , 9h
	int 21h
	
	mov dx, offset rad
	call far ptr ReadLine
		
	xor si,si
	mov si,offset rad
	add si,2
	call far ptr  ConvertStringToNum
	mov dl,al
	xor ax,ax
	xor ah,ah
	mov al,dl
	mov [savedradius], ax
	
	cmp [tool],0
	jne fin
	mov [radius],ax
	
	fin:
	 call far ptr  OpenFile
   call far ptr ShowImage	
    
    mov ax,[savedradius]
    mov [untilcw],ax
    CALL far ptr ConvertToASCII
	call far ptr PrintCenter
   
     MOV AH, 09h
   MOV DX, OFFSET numStr
    INT 21h
	
	mov ax, [savedradius]
	add ax,32
	mov [until],ax
	mov [col],154
	call far ptr DrawUntil
	call far ptr ShowMouse
	
	jmp mous
	
	erasercustom:
	mov dx, offset msgersize; Console.WriteLine
	mov ah , 9h
	int 21h
	
	mov dx,offset rad
	call far ptr ReadLine
	
 
	xor si,si
    mov si,offset rad 
	add si,2
	call far ptr  ConvertStringToNum
	mov dl,al
	xor ax,ax
	xor ah,ah
	mov al,dl
	mov [eraserradius], ax
	
	cmp [tool],1
	jne loadpicafterreadline
	mov [radius],ax
	
	
	loadpicafterreadline:
	 call far ptr  OpenFile
   call far ptr ShowImage	
   
   mov ax,[eraserradius]
   mov [untilcw],ax
     CALL far ptr ConvertToASCII
     call far ptr PrintCenter
   
     MOV AH, 09h
    MOV DX, OFFSET numStr
    INT 21h
	
	mov ax, [eraserradius]
	mov [until],ax
	inc [until]
	mov [col],154
	call far ptr DrawUntil
	call far ptr ShowMouse
	
	  CALL far ptr ConvertToASCII
	call far ptr PrintCenter
     MOV AH, 09h
    MOV DX, OFFSET numStr
    INT 21h
	jmp mous
	runtil:
	cmp [centery],90  
	jl MouseLocation
	cmp [centery],119
	jg MouseLocation
	cmp [centerx],32
	jl MouseLocation
	cmp [centerx],290 
	jg MouseLocation
	
	call far ptr HideMouse
	call far ptr CloseFile
	  call  far ptr OpenFile
   call far ptr ShowImage	
    call far ptr PrintCenter
    MOV DX, OFFSET numStr
    INT 21h
	mov ax, [centerx]
	mov [until],ax
	inc [until]
	mov [col],154
	call far ptr DrawUntil
	call far ptr ShowMouse
	
	mov ax ,[until]
	mov [untilcw],ax
	sub [untilcw],32
	
	cmp [mode],0
	jne updateeraser
	
	mov ax,[untilcw]
	mov [savedradius],ax
	cmp [tool],0
	jne endd
	mov [radius],ax
	
	jmp endd
	updateeraser:
	mov ax,[untilcw]
	mov [eraserradius],ax
	cmp [tool],1 
	jne endd
	mov [radius],ax
	
	endd:
	call far ptr CloseFile
	  call  far ptr OpenFile
   call far ptr ShowImage	
	mov ax, [centerx]
	mov [until],ax
	mov [col],154
	call far ptr DrawUntil
	call far ptr ShowMouse
	
	mov ax,[centerx]
	 mov [untilcw],ax
	 sub [untilcw],32
	  CALL far ptr ConvertToASCII
	 
	  call far ptr PrintCenter
   
     MOV AH, 09h
    MOV DX, OFFSET numStr
    INT 21h
mous:
	jmp MouseLocation
	
	
;==========================================================================================================
;--------------------------------------------------Procs---------------------------------------------------
;==========================================================================================================

;------------------------- Undo Feature

proc Undo Far
push bp
mov bp ,sp

mov di,0
mov cx ,64000
Undoloop:
mov al, [fs:di]
mov [es:di],al
inc di 
loop Undoloop
mov [undoAvailable],0

pop bp 
ret
endp Undo
proc Save_Undo far 
push bp 
mov bp,sp

call far ptr HideMouse
call far ptr SaveScreenToArray
call far ptr ShowMouse


mov di,0
mov cx ,64000
StrtSave:
mov al , [es:di]
mov [fs:di],al
inc di 
loop StrtSave

mov [undoAvailable],1

pop bp 
ret 
endp save_Undo

;------------------------- Pixels 
proc DrawUntil far
	push bp
	mov bp,sp
	
	mov [y],91
	mov [x],32
	drw:	
	call far ptr PrintPixelss
mov ax, [until]
inc [x]
cmp [x], ax
jg checkyyy

jmp drw 
checkyyy:
mov [x],32
inc [y]
cmp [y],120
jg finsh
jmp drw
finsh:
	pop bp
	ret 
	endp DrawUntil
	proc GetColor far
push bp
mov bp,sp 

mov bh,0h
   mov cx,[centerx]
   mov dx,[centery]
    mov ah,0Dh
    int 10h 
pop bp
ret 
endp GetColor
	proc PrintPixelss far 
	push bp 
mov bp,sp
	mov bh,0h
mov cx,[x]
mov dx,[y]
mov al,[col]
mov ah,0ch
int 10h
	pop bp
	ret
	endp PrintPixelss
;----------------------------String / Ascii
proc PrintCenter far 

  MOV DH, 17
    MOV DL, 19
    MOV BH, 0
    MOV AH, 02h
    INT 10h

ret
endp PrintCenter
proc ConvertStringToNum far  
	   xor ax,ax
	   xor cx,cx
	   xor bx,bx 
	   mov cx, 10
	   
	   convert:
	   mov bl ,[si]
	   cmp bl,13
	   je finish
	   
	   sub bl, '0'
	   mul cx
	   add ax, bx
	   
	   cmp ax ,255
	   jbe storeinal
	   mov ax,255
	   
	   storeinal:
	   mov al,al
	   inc si
	   jmp convert
	   finish:
	ret
	endp ConvertStringToNum
	
	proc ConvertToASCII far
    PUSH AX BX CX DX SI DI

    MOV AX, [untilcw]     
    MOV CX, 0             
    MOV SI, OFFSET tempBuf 
ConvertLoop:
    XOR DX, DX            
    MOV BX, 10
    DIV BX              
    ADD DL, '0'           
    MOV [SI], DL
    INC SI
    INC CX
    CMP AX, 0
    JNZ ConvertLoop

   
    MOV DI, OFFSET numStr
    MOV SI, SI            
    DEC SI

ReverseLoop:
    MOV AL, [SI]
    MOV [DI], AL
    INC DI
    DEC SI
    LOOP ReverseLoop

    MOV [BYTE PTR DI], '$' 

    POP DI SI DX CX BX AX
    RET
endp ConvertToASCII 

proc ReadLine far
	mov bx, dx
	mov [byte ptr bx],21
	mov ah ,0Ah
	int 21h
	ret
	endp ReadLine

	
	
;-------------------------- Delay 
proc PicDelay Far
push bp
mov bp,sp
push es 


	mov [options] ,7

	 call  far ptr OpenFile
   call far ptr ShowImage	
	call far ptr OneSecDelay 

pop es 
pop bp
retf
endp PicDelay

proc OneSecDelay Far
push bp
mov bp,sp

mov ax, 40h
mov es, ax
mov ax, [Clock]
FirstTick :
cmp ax, [Clock]
je FirstTick
mov cx, 3
DelayLoop:
mov ax, [Clock]
Tick :
cmp ax, [Clock]
je Tick
loop DelayLoop

pop bp
ret
endp OneSecDelay

;-------------------------------------- Circle 


 
PROC DrawFilledCircle far
    ; Save registers
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Initialize variables
    MOV [x_pos], 0
    MOV AX, [radius]
    MOV [y_pos], AX
    
    ; Initial decision parameter for Bresenham's circle algorithm
    MOV AX, 3
    SUB AX, [radius]
    SUB AX, [radius]
    MOV [decision], AX
    
CircleLoop:
    ; Draw horizontal lines across the circle
    CALL  far ptr FillCircleLines
    
    ; Update variables based on Bresenham's algorithm
    MOV AX, [decision]
    CMP AX, 0
    JGE DecisionGE0
    
    ; Decision < 0
    MOV AX, [decision]
    ADD AX, [x_pos]
    ADD AX, [x_pos]
    ADD AX, 4
    MOV [decision], AX
    JMP IncrementX
    
DecisionGE0:
    ; Decision >= 0
    MOV AX, [decision]
    ADD AX, 4
    SUB AX, [y_pos]
    SUB AX, [y_pos]
    ADD AX, [x_pos]
    ADD AX, [x_pos]
    MOV [decision], AX
    
    ; Decrement y
    DEC [y_pos]
    
IncrementX:
    ; Increment x
    INC [x_pos]
    
    ; Continue while x <= y
    MOV AX, [x_pos]
    CMP AX, [y_pos]
    JLE CircleLoop
    
    ; Restore registers and return
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP DrawFilledCircle
PROC FillCircleLines far
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Draw horizontal line at y=centerY+y from x=centerX-x to x=centerX+x
    MOV DX, [centerY]
    ADD DX, [y_pos]    ; y = centerY+y
    MOV BX, [x_pos]
    CALL  far ptr DrawHorizontalLine
    
    ; Draw horizontal line at y=centerY-y from x=centerX-x to x=centerX+x
    MOV DX, [centerY]
    SUB DX, [y_pos]    ; y = centerY-y
    MOV BX, [x_pos]
    CALL  far ptr DrawHorizontalLine
    
    ; Draw horizontal line at y=centerY+x from x=centerX-y to x=centerX+y
    MOV DX, [centerY]
    ADD DX, [x_pos]    ; y = centerY+x
    MOV BX, [y_pos]
    CALL  far ptr DrawHorizontalLine
    
    ; Draw horizontal line at y=centerY-x from x=centerX-y to x=centerX+y
    MOV DX, [centerY]
    SUB DX, [x_pos]    ; y = centerY-x
    MOV BX, [y_pos]
    CALL  far ptr DrawHorizontalLine
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP FillCircleLines
PROC DrawHorizontalLine far
    ; Check if Y is within screen bounds
    CMP DX, 0
    JL DontDrawLine    ; Y < 0, skip drawing
    CMP DX, [screenHeight]
    JGE DontDrawLine   ; Y >= screenHeight, skip drawing
    
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Calculate left endpoint (centerX - offset)
    MOV CX, [centerX]
    SUB CX, BX
    
    ; Check if left endpoint is within screen bounds
    CMP CX, 0
    JGE LeftInBounds
    MOV CX, 0          ; Clip to left edge of screen
    
LeftInBounds:
    ; Calculate right endpoint (centerX + offset)
    MOV SI, [centerX]
    ADD SI, BX
    
    ; Check if right endpoint is within screen bounds
    CMP SI, [screenWidth]
    JL RightInBounds
    MOV SI, [screenWidth]
    DEC SI             ; Clip to right edge of screen (width-1)
    
RightInBounds:
    ; If left > right after clipping, don't draw
    CMP CX, SI
    JG EndDrawLine
    
    ; Draw the line
    MOV AL, [currentColor]    
    MOV AH, 0Ch             
    MOV BH, 0                 
    
LineLoop:
    ; Save current position
    PUSH CX
    PUSH DX
    

    INT 10h
    
    ; Update pixel array
    PUSH AX
    PUSH BX
    
    ; Calculate array offset: Y*320 + X
    MOV AX, 320
    MUL DX              ; AX = 320 * Y
    ADD AX, CX          ; AX = 320 * Y + X
    MOV DI, AX          ; DI = offset in array (using DI for ES segment addressing)
    
    ; Store color in array - make sure to use ES for large model
    MOV AL, [currentColor]
    MOV [ES:DI], AL     ; Use ES:DI for far addressing
    
    POP BX
    POP AX
    
    ; Restore position and move to next pixel
    POP DX
    POP CX
    INC CX
    
    ; Continue until end of line
    CMP CX, SI
    JLE LineLoop
    
EndDrawLine:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    
DontDrawLine:
    RET
ENDP DrawHorizontalLine
;------------------------------- Mouse 
proc ShowMouse far
push bp 
mov bp,sp

mov ax,1h
int 33h

pop bp
ret
endp ShowMouse
proc HideMouse far
push bp 
mov bp,sp

mov ax,2h
int 33h

pop bp
ret
endp HideMouse
;----

;-----------------------------Arrays 

PROC PrintArrayToScreen far
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    
    MOV DX, 0      
    MOV SI, 0      
    
YLoopPrint:
    MOV CX, 0      
    
XLoopPrint:
   
    MOV AL, [ES:SI]
    
    ; Draw pixel
    MOV AH, 0Ch     
    MOV BH, 0    
    INT 10h
    
   
    INC SI
    INC CX
    CMP CX, 320
    JNE XLoopPrint
    
    INC DX
    CMP DX, 200
    JNE YLoopPrint
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP PrintArrayToScreen


PROC SaveScreenToArray far
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    
    MOV DX, 0      
    
YLoop:
    MOV CX, 0      
    
XLoop:
    ; Calculate array index (Y*320 + X)
    PUSH AX
    PUSH CX
    PUSH DX
    
    MOV AX, 320
    MUL DX          ; AX = 320 * Y
    ADD AX, CX      ; AX = 320 * Y + X
    MOV DI, AX      ; DI = offset in array (using DI for ES segment addressing)
    
    POP DX
    POP CX
       
    MOV AH, 0Dh     
    MOV BH, 0     
    INT 10h         ; 
    
    MOV [ES:DI], AL
    
    POP AX
    
    INC CX
    CMP CX, 320
    JNE XLoop
    
    INC DX
    CMP DX, 200
    JNE YLoop
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP SaveScreenToArray
;------------------------------------------------ Graphics
proc TextMode far
push bp
mov bp, sp

mov ah, 0
mov al, 2
int 10h


pop bp
ret
endp TextMode
proc GraphicsMode far
push bp
mov bp, sp

mov ax,13h  ;המרה למצב גרפי
int 10h
	
pop bp
ret
endp GraphicsMode
;--------------------------------------image files and saving 
proc ShowImage Far
push bp
mov bp,sp
call far ptr HideMouse
 call  far ptr ReadHeader
    call  far ptr ReadPalette
   call  far ptr CopyPal
    call  far ptr CopyBitmap
	call far ptr ShowMouse
	
pop bp
ret
endp ShowImage

 proc CloseFile far
    mov ah, 3Eh
    mov bx, [filehandle]
    int 21h
    ret
endp CloseFile
proc OpenFile far
mov ah, 3Dh
xor al, al
cmp [options],0
jne Menu
mov dx, offset filename
int 21h
jmp aft
Menu:
cmp [options],1
jne Key
mov dx, offset filename1
int 21h
jmp aft
Key:
cmp [options],2
jne colorrr
mov dx, offset filename2
int 21h
jmp aft
colorrr:
cmp [options],3
jne readl
mov dx, offset filename3
int 21h
jmp aft 
readl:
cmp [options],5
jne waitanothersec
mov dx, offset filename4+2
int 21h
jmp aft 
waitanothersec:
cmp [options],7
jne toolsizeselector
mov dx, offset filename5
int 21h
jmp aft 
toolsizeselector:
mov dx, offset filename6
int 21h
aft:
jc openerror
mov [filehandle], ax
ret
openerror :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile
proc ReadHeader far
; Read BMP file header, 54 bytes
mov ah,3fh
mov bx, [filehandle]
mov cx,54
mov dx,offset Header
int 21h
ret
endp ReadHeader
proc ReadPalette far
; Read BMP file color palette, 256 colors * 4 bytes (400h)
mov ah,3fh
mov cx,400h
mov dx,offset Palette
int 21h
ret
endp ReadPalette
proc CopyPal far
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
mov si,offset Palette
mov cx,256
mov dx,3C8h
mov al,0
; Copy starting color to port 3C8h
out dx,al
; Copy palette itself to port 3C9h
inc dx
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB .
mov al,[si+2] ; Get red value .
shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
out dx,al ; Send it .
mov al,[si+1] ; Get green value .
shr al,2
out dx,al ; Send it .
mov al,[si] ; Get blue value .
shr al,2
out dx,al ; Send it .
add si,4 ; Point to next color .
; (There is a null chr. after every color.)
loop PalLoop
ret
endp CopyPal
proc CopyBitmap far
; BMP graphics are saved upside-down .
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
PUSH ES
mov ax, 0A000h
mov es, ax
mov cx,200
PrintBMPLoop :
push cx
; di = cx*320, point to the correct screen line
mov di,cx
shl cx,6
shl di,8
add di,cx
; Read one line
mov ah,3fh
mov cx,320
mov dx,offset ScrLine
int 21h
; Copy one line into video memory
cld ; Clear direction flag, for movsb
mov cx,320
mov si,offset ScrLine
rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code :
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
 ;loop until cx=0
pop cx
loop PrintBMPLoop
POP ES
ret
endp CopyBitmap

PROC SaveToBMP FAR
   
    push ds
    mov ax, @data
    mov ds, ax
    
   
    mov [byte ptr Header], 'B'
    mov [byte ptr Header+1], 'M'
    
    mov [dword ptr Header+2], 65078
    
    
    mov [word ptr Header+6], 0
    mov [word ptr Header+8], 0
    
    mov [dword ptr Header+10], 1078
    
    mov [dword ptr Header+14], 40
    
    mov [dword ptr Header+18], 320
    
    mov [dword ptr Header+22], -200
    
    mov [word ptr Header+26], 1
    
    mov [word ptr Header+28], 8
    
    mov [dword ptr Header+30], 0
    
    mov [dword ptr Header+34], 64000
    
    mov [dword ptr Header+38], 3780
    
    mov [dword ptr Header+42], 3780
    
    mov [dword ptr Header+46], 0
    
    mov [dword ptr Header+50], 0
    

    call  far ptr CopyPal
	
    xor bx, bx      ; BX = color index (0-255)
    mov si, offset Palette
    mov cx,256
mov dx,3C8h
mov al,0
out dx,al
inc dx
InitPalette:
   
    mov al, bl
  
    
	mov al,[si+2] ; Get red value .
shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
out dx,al ; Send it .
mov al,[si+1] ; Get green value .
shr al,2
out dx,al ; Send it .
mov al,[si] ; Get blue value .
shr al,2

    add si, 4                   
    inc bl
    cmp bl, 0                   
    jne InitPalette
    
    ; ---- Create the BMP file ----
    mov ah, 3Ch
    xor cx, cx          ; Normal file attribute
    mov dx, offset saveFilename
    int 21h
    jc ErrorSaving
    
    mov [filehandle], ax
    
    ; Write the header (54 bytes)
    mov ah, 40h
    mov bx, [filehandle]
    mov cx, 54
    mov dx, offset Header
    int 21h
    jc ErrorSaving
    
    ; Write the palette (1024 bytes)
    mov ah, 40h
    mov bx, [filehandle]
    mov cx, 1024
    mov dx, offset Palette
    int 21h
    jc ErrorSaving
    
   
    mov ax, [filehandle]
    
    ; ---  write pixel data from ES:pixelArray ---
 
    push si
    push di
    
    ; Get the file handle into BX so it's preserved across segment changes
    mov bx, ax
    
    ; Write the pixel array (64000 bytes)
    ; Must use ES:DX for the pixel data
    push ds        ; Save DS
    mov ax, es     ; We want to write from ES segment where pixelArray is
    mov ds, ax     ; Set DS to ES for INT 21h write call
    
    mov ah, 40h    ; Write file function
    ; BX already has file handle
    mov cx, 64000  ; Bytes to write
    mov dx, offset pixelArray
    int 21h        ; Do the write
    pop ds         ; Restore DS to data segment
    jc CleanupAndError
    
    ; --- Now close the file (back in data segment) ---
    mov ah, 3Eh
    ; BX still has file handle
    int 21h
    
    pop di
    pop si
    pop ds
    ret

CleanupAndError:
    ; Carry is set from failed operation
    pop di
    pop si
    ; Fall through to ErrorSaving
    
ErrorSaving:
    ; Display error message (ensure we're in data segment)
    mov ah, 9
    mov dx, offset ErrorMsg
    int 21h
    
    pop ds  ; Restore data segment before returning
    ret
    
ENDP SaveToBMP	
; --------------------------
; Your code here
; --------------------------
	
exit:
	mov ax, 4c00h
	int 21h
END start
