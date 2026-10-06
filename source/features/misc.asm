; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
;
; MISCELLANEOUS ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_get_api_version -- Return current version of MikeOS API
; IN: Nothing; OUT: AL = API version number

os_get_api_version:
	mov al, MIKEOS_API_VER
	ret


; ------------------------------------------------------------------
; os_get_boot_device -- Return BIOS drive number used to boot the OS
; IN: Nothing; OUT: AX = BIOS drive number (e.g. 00h floppy, 80h hard disk)

os_get_boot_device:
	movzx ax, byte [bootdev]
	ret


; ------------------------------------------------------------------
; os_get_memory_size -- Return conventional/base memory size
; IN: Nothing; OUT: AX = conventional memory size in KB

os_get_memory_size:
	int 12h
	ret


; ------------------------------------------------------------------
; os_get_video_mode -- Return the active BIOS video mode
; IN: Nothing; OUT: AX = BIOS video mode number

os_get_video_mode:
	mov ah, 0Fh
	int 10h
	movzx ax, al			; INT 10h also returns columns/page in AH/BH
	ret


; ------------------------------------------------------------------
; os_init_uptime -- Initialize elapsed BIOS tick accounting at boot

os_init_uptime:
	push ax
	push bx
	push cx
	push dx
	mov ah, 00h
	int 1Ah				; CX:DX = BIOS ticks since midnight
	mov [uptime_last_tick], dx
	mov [uptime_last_tick+2], cx
	mov dword [uptime_elapsed_ticks], 0
	pop dx
	pop cx
	pop bx
	pop ax
	ret


; ------------------------------------------------------------------
; os_get_uptime -- Return elapsed BIOS clock ticks since OS startup
; IN: Nothing; OUT: EAX = elapsed ticks (approximately 18.2 ticks/second)
; Call periodically; BIOS time-of-day ticks wrap at midnight.

os_get_uptime:
	push bx
	push cx
	push dx
	mov ah, 00h
	int 1Ah				; CX:DX = BIOS ticks since midnight
	movzx eax, cx
	shl eax, 16
	mov ax, dx
	mov [uptime_current_tick], eax

	mov ebx, [uptime_last_tick]
	cmp eax, ebx
	jb .midnight_wrap
	sub eax, ebx
	jmp .add_elapsed

.midnight_wrap:
	add eax, 0x1800B0		; BIOS ticks in a 24-hour day
	sub eax, ebx

.add_elapsed:
	add [uptime_elapsed_ticks], eax
	mov eax, [uptime_current_tick]
	mov [uptime_last_tick], eax
	mov eax, [uptime_elapsed_ticks]
	pop dx
	pop cx
	pop bx
	ret


; ------------------------------------------------------------------
; os_bios_hardware_flag -- Return BIOS equipment-list flags
; IN: Nothing; OUT: AX = equipment-list word from BIOS INT 11h

os_bios_hardware_flag:
	int 11h
	ret


	uptime_last_tick	dd 0
	uptime_current_tick	dd 0
	uptime_elapsed_ticks	dd 0


; ------------------------------------------------------------------
; os_pause -- Delay execution for specified 110ms chunks
; IN: AX = 100 millisecond chunks to wait (max delay is 32767,
;     which multiplied by 55ms = 1802 seconds = 30 minutes)

os_pause:
	pusha
	cmp ax, 0
	je .time_up			; If delay = 0 then bail out

	mov cx, 0
	mov [.counter_var], cx		; Zero the counter variable

	mov bx, ax
	mov ax, 0
	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; Multiply by number of 110ms chunks required 
	mov [.orig_req_delay], ax	; Save it

	mov ah, 0
	int 1Ah				; Get tick count	

	mov [.prev_tick_count], dx	; Save it for later comparison

.checkloop:
	mov ah,0
	int 1Ah				; Get tick count again

	cmp [.prev_tick_count], dx	; Compare with previous tick count

	jne .up_date			; If it's changed check it
	jmp .checkloop			; Otherwise wait some more

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Inc counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; Is counter_var = required delay?
	jge .time_up			; Yes, so bail out

	mov [.prev_tick_count], dx	; No, so update .prev_tick_count 

	jmp .checkloop			; And go wait some more


	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0


; ------------------------------------------------------------------
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location

os_fatal_error:
	mov bx, ax			; Store string location for now

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	pusha
	mov ah, 09h			; Draw red bar at top
	mov bh, 0
	mov cx, 240
	mov bl, 01001111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	mov si, .msg_inform		; Inform of fatal error
	call os_print_string

	mov si, bx			; Program-supplied error message
	call os_print_string

	jmp $				; Halt execution

	
	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0


; ==================================================================
