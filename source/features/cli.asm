; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
; GMU OS derivative learning edition: GM University, Davanagere, 2026
;
; COMMAND LINE INTERFACE
; ==================================================================


os_command_line:
	call os_clear_screen

	mov si, version_msg
	call os_print_string
	mov si, help_text
	call os_print_string


get_cmd:				; Main processing loop
	mov di, command			; Clear single command buffer
	mov cx, 32
	rep stosb

	mov si, prompt			; Main loop; prompt for input
	call os_print_string

	mov ax, input			; Get command string from user
	mov bx, 64
	call os_input_string

	call os_print_newline

	mov ax, input			; Remove trailing spaces
	call os_string_chomp

	mov si, input			; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

	mov si, input			; Separate out the individual command
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Store location of full parameters

	mov si, input			; Store copy of command for later modifications
	mov di, command
	call os_string_copy



	; First, let's check to see if it's an internal command...

	mov ax, input
	call os_string_uppercase

	mov si, input
	mov ax, input
	call os_string_length
	cmp ax, 2
	jb near .normal_dispatch
	mov si, input
	add si, ax
	cmp byte [si-1], '?'
	jne near .normal_dispatch
	cmp byte [si-2], '/'
	jne near .normal_dispatch
	mov byte [si-2], 0

	mov si, input
	mov di, dir_string
	call os_string_compare
	jc .dir_help
	mov di, list_string
	call os_string_compare
	jc .ls_help
	mov di, copy_string
	call os_string_compare
	jc .copy_help
	mov di, ren_string
	call os_string_compare
	jc .ren_help
	mov di, del_string
	call os_string_compare
	jc .del_help
	mov di, cat_string
	call os_string_compare
	jc .cat_help
	mov di, size_string
	call os_string_compare
	jc .size_help
	mov di, cls_string
	call os_string_compare
	jc .cls_help
	mov di, help_string
	call os_string_compare
	jc .help_help
	mov di, about_string
	call os_string_compare
	jc .about_help
	mov di, time_string
	call os_string_compare
	jc .time_help
	mov di, date_string
	call os_string_compare
	jc .date_help
	mov di, ver_string
	call os_string_compare
	jc .ver_help
	mov di, exit_string
	call os_string_compare
	jc .exit_help
	jmp total_fail

.dir_help:
	mov si, dir_help_text
	jmp print_command_help
.ls_help:
	mov si, ls_help_text
	jmp print_command_help
.copy_help:
	mov si, copy_help_text
	jmp print_command_help
.ren_help:
	mov si, ren_help_text
	jmp print_command_help
.del_help:
	mov si, del_help_text
	jmp print_command_help
.cat_help:
	mov si, cat_help_text
	jmp print_command_help
.size_help:
	mov si, size_help_text
	jmp print_command_help
.cls_help:
	mov si, cls_help_text
	jmp print_command_help
.help_help:
	mov si, help_help_text
	jmp print_command_help
.about_help:
	mov si, about_help_text
	jmp print_command_help
.time_help:
	mov si, time_help_text
	jmp print_command_help
.date_help:
	mov si, date_help_text
	jmp print_command_help
.ver_help:
	mov si, ver_help_text
	jmp print_command_help
.exit_help:
	mov si, exit_help_text
	jmp print_command_help

.normal_dispatch:
	mov si, input

	mov di, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov di, help_string		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov di, about_string		; 'ABOUT' entered?
	call os_string_compare
	jc near print_about

	mov di, cls_string		; 'CLS' entered?
	call os_string_compare
	jc near clear_screen

	mov di, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near list_directory

	mov di, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_ver

	mov di, time_string		; 'TIME' entered?
	call os_string_compare
	jc near print_time

	mov di, date_string		; 'DATE' entered?
	call os_string_compare
	jc near print_date

	mov di, cat_string		; 'CAT' entered?
	call os_string_compare
	jc near cat_file

	mov di, del_string		; 'DEL' entered?
	call os_string_compare
	jc near del_file

	mov di, copy_string		; 'COPY' entered?
	call os_string_compare
	jc near copy_file

	mov di, ren_string		; 'REN' entered?
	call os_string_compare
	jc near ren_file

	mov di, size_string		; 'SIZE' entered?
	call os_string_compare
	jc near size_file

	mov di, list_string		; 'LS' entered?
	call os_string_compare
	jc dir_list


	; If the user hasn't entered any of the above commands, then we
	; need to check for an executable file -- .BIN or .BAS, and the
	; user may not have provided the extension

	mov ax, command
	call os_string_uppercase
	call os_string_length


	; If the user has entered, say, MEGACOOL.BIN, we want to find that .BIN
	; bit, so we get the length of the command, go four characters back to
	; the full stop, and start searching from there

	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		; Is there a .BIN extension?
	call os_string_compare
	jc bin_file

	mov di, bas_extension		; Or is there a .BAS extension?
	call os_string_compare
	jc bas_file

	mov di, pcx_extension		; Or is there a .PCX extension?
	call os_string_compare
	jc total_fail

	jmp no_extension


bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov si, command
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc no_kernel_allowed

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Call the external program

	jmp get_cmd			; When program has finished, start again



bas_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	mov ax, 32768
	mov word si, [param_list]
	call os_run_basic

	jmp get_cmd



no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bas_ext

	jmp execute_bin


try_bas_ext:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax
	sub si, 4

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0

	jmp bas_file



total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd


no_kernel_allowed:
	mov si, kern_warn_msg
	call os_print_string

	jmp get_cmd


; ------------------------------------------------------------------

print_help:
	mov si, help_text
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

print_command_help:
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

print_about:
	mov si, about_text
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

clear_screen:
	call os_clear_screen
	jmp get_cmd


; ------------------------------------------------------------------

print_time:
	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_date:
	mov si, [param_list]
	cmp si, 0
	je .show_current

	; DATE arguments must use the form dd/mm/yyyy.
	mov ax, si
	call os_string_length
	cmp ax, 10
	jne .invalid_date
	cmp byte [si+2], '/'
	jne .invalid_date
	cmp byte [si+5], '/'
	jne .invalid_date

	mov bx, 0
.check_digits:
	mov al, [si+bx]
	cmp bx, 2
	je .skip_separator
	cmp bx, 5
	je .skip_separator
	cmp al, '0'
	jb .invalid_date
	cmp al, '9'
	ja .invalid_date
.skip_separator:
	inc bx
	cmp bx, 10
	jb .check_digits

	; A four-digit year is a leap year when it is divisible by four.
	mov bx, 0
	mov di, si
	add di, 6
	mov cx, 4
.read_year_digit:
	mov ax, bx
	mov dx, 10
	mul dx
	mov bx, ax
	xor ax, ax
	mov al, [di]
	sub al, '0'
	add bx, ax
	inc di
	loop .read_year_digit
	mov ax, bx
	xor dx, dx
	mov bx, 4
	div bx
	cmp dx, 0
	je .leap_year

	mov si, not_leap_msg
	call os_print_string
	jmp get_cmd

.leap_year:
	mov si, leap_msg
	call os_print_string
	jmp get_cmd

.invalid_date:
	mov si, invalid_date_msg
	call os_print_string
	jmp get_cmd

.show_current:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_ver:
	mov si, version_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

list_directory:
	mov cx,	0			; Counter

	mov ax, dirlist			; Get list of files on disk
	call os_get_file_list

	mov si, dirlist

.set_column:
	; Put the cursor in the correct column.
	call os_get_cursor_pos

	mov ax, cx
	and al, 0x03
	mov bl, 20
	mul bl

	mov dl, al
	call os_move_cursor

	mov ah, 0Eh			; BIOS teletype function
.next_char:
	lodsb

	cmp al, ','
	je .next_filename

	cmp al, 0
	je .done

	int 10h
	jmp .next_char

.next_filename:
	inc cx

	mov ax, cx
	and ax, 03h

	cmp ax, 0			; New line every 4th filename.
	jne .set_column

	call os_print_newline
	jmp .set_column

.done:
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

cat_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		; Check if file exists
	jc .not_found

	mov cx, 32768			; Load file into second 32K
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			; Nothing in the file?
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			; int 10h teletype function
.loop:
	lodsb				; Get byte from loaded file

	cmp al, 0Ah			; Move to start of line if we get a newline char
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				; Display it
	dec bx				; Count down file size
	cmp bx, 0			; End of file?
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

del_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Deleted file: ', 0
	.failure_msg	db 'Could not delete file - does not exist or write protected', 13, 10, 0


; ------------------------------------------------------------------

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_get_file_size
	jc .failure

	mov si, .size_msg
	call os_print_string

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd


.failure:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


	.size_msg	db 'Size (in bytes) is: ', 0


; ------------------------------------------------------------------

copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			; Store first filename temporarily
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd


	.tmp		dw 0
	.success_msg	db 'File copied successfully', 13, 10, 0


; ------------------------------------------------------------------

ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			; Store first filename temporarily
	mov ax, bx			; Get destination
	call os_file_exists		; Check to see if it exists
	jnc .already_exists

	mov ax, cx			; Get first filename back
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'File renamed successfully', 13, 10, 0
	.failure_msg	db 'Operation failed - file not found or invalid filename', 13, 10, 0


; =====================================================================

ParaPerEntry	equ 2			; 32 bytes/entry => 2 paragraphs

dir_list:
	push es
	pusha

	call disk_read_root_dir
	jnc .cont1
	mov si, .readfail_msg
	call os_print_string
	jmp short .done

  .cont1:
;	mov di, bx			; ES:DI points to directory buffer
	mov di, disk_buffer		; ES:DI points to directory buffer

  .outer_loop:
	mov si, .header_msg
	call os_print_string
	mov cx, 20

  .page_loop:
	mov al, [es:di+11]		; get attributes
	cmp al, 0x0f			; Win marker
	je .next_entry

	test al, 0x18			; directory or volume label => skip
	jnz .next_entry

	mov al, [es:di]			; first char of name
	cmp al, 0			; first unused, should be unused here to end
	je .done

	cmp al, 0x5e			; skip deleted
	je .next_entry

	cmp al, ' '			; skip if starts with space or control (Win UTF-8?)
	jle .next_entry

	cmp al, '~'			; skip if not normal 7-bit ASCII
	jae .next_entry

	cmp al, '.'			; skip if '.' or '..'
	je .next_entry

	call dir_entry_dump		; ES:DI points to entry
	dec cx

  .next_entry:
	mov dx, es
	add dx, ParaPerEntry
	mov es, dx

	cmp cx, 0
	jne .page_loop

  .cont2:
	mov si, .footer_msg
	call os_print_string
	call os_wait_for_key
	cmp al, 27			; was key <esc>?
	je .done
	call os_clear_screen
	jmp .outer_loop

  .done:
	call os_print_newline
	popa
	pop es
	jmp get_cmd


	.readfail_msg	db 'Unable to read disk directory', 0
	.header_msg	db '    Name         attr         created          last write      first     bytes', 13, 10, 0
	.footer_msg	db 'Press key for next page', 0


; ---------------------------------------------------------------------
; listing helper subroutines

; ------------------------------------------------------------------
; dir_entry_dump -- print out the contents of a directory entry
;   output must correspond to header (above)
; IN: ES:DI = points to directory entry
; OUT: no changes

dir_entry_dump:
	pusha

	call type_name
	call os_get_cursor_pos		; line up columns
	mov dl, 15
	call os_move_cursor

	mov bh, [es:di+11]		; display attributes
	mov ax, 0x0e2e			; '.'
	test bh, 0x80			; reserved (should not be set)
	jz .attr1
	mov al, '*'
  .attr1:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x40			; internal only (should not be set)
	jz .attr2
	mov al, '*'
  .attr2:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x20
	jz .attr3
	mov al, 'A'			; archive
  .attr3:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x10
	jz .attr4
	mov al, 'D'			; subdirectory
  .attr4:
	int 10h
	mov ax, 0x0e2e
	test bh, 8
	jz .attr5
	mov al, 'V'			; volume ID
  .attr5:
	int 10h
	mov ax, 0x0e2e
	test bh, 4
	jz .attr6
	mov al, 'S'			; system
  .attr6:
	int 10h
	mov ax, 0x0e2e
	test bh, 2
	jz .attr7
	mov al, 'H'			; hidden
  .attr7:
	int 10h
	mov ax, 0x0e2e
	test bh, 1
	jz .attr8
	mov al, 'R'			; read only
  .attr8:
	int 10h
	call os_print_space
	call os_print_space		; at column 25?

	mov dx, [es:di+16]		; created date & time (US and 24-hr format)
	call type_date
	call os_print_space
	mov dx, [es:di+14]
	call type_time
	call os_print_space
	call os_print_space		; at column 44?

	mov dx, [es:di+24]		; last written date & time (US and 24-hr format)
	call type_date
	call os_print_space
	mov dx, [es:di+22]
	call type_time			; at column 61?

	mov ax, [es:di+26]		; starting cluster
	call os_int_to_string
	mov si, ax
	call os_string_length
	neg ax
	add ax, 7			; 2 space separation + 5 characters, max.
	mov cx, ax
	jle .cluster_left
  .loop1:
	call os_print_space
	loop .loop1
  .cluster_left:
	call os_print_string

	mov dx, [es:di+30]		; file size (bytes)
	mov ax, [es:di+28]
	push es
	push ds
	pop es				; ES = DS = program seg
	push di
	mov bx, 10
	mov di, .number
	call os_long_int_to_string
	mov si, di
	mov ax, di
	call os_string_length
	neg ax
	add ax, 10			; 2 space separation + 8 characters, max.
	mov cx, ax
	jle .size_left
  .loop2:
	call os_print_space
	loop .loop2
  .size_left:
	call os_print_string
	call os_print_newline
	pop di
	pop es				; ES = directory seg

	popa
	ret

	.number		times 13 db 0

; ---------------------------------------------------------------------
; Type directory format time and print in 24-hr format (hh:mm:ss)
; There is a normal 2 second granularity
; IN: DX = time number
type_time:
	pusha

	mov ax, dx
	shr ax, 11			; 11 (start in word)
	cmp al, 10			; always 'hh'
	jae .hh
	push ax
	mov ax, 0x0e30			; '0'
	int 10h
	pop ax
  .hh:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e3a			; ':'
	int 10h

	mov ax, dx
	shr ax, 5			; 5 bits for seconds/2
	and ax, 0x3f			; 6 bits for minutes
	cmp al, 10
	jae .mm
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .mm:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e3a
	int 10h

	mov ax, dx
	and ax, 0x1f			; 5 bits for seconds/2
	shl ax, 1
	cmp al, 10
	jae .ss
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .ss:
	call os_int_to_string
	mov si, ax
	call os_print_string

	popa
	ret

; DOS format directory entry
; IN: DX = date number
; Uses USA date output format mm/dd/yy
type_date:
	pusha
	mov ax, dx		; separate out month
	shr ax, 5
	and ax, 0x0F
	cmp al, 1
	jl .mon_00
	cmp al, 12
	jbe .month
  .mon_00:
	mov al, 0
  .month:
	cmp al,10		; always 'mm'
	jge .mm
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .mm:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e2f		; '/'
	int 10h

	mov ax,dx		; separate out day
	and ax,0x1F
	cmp al, 10		; always 'dd'
	jae .dd
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .dd:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e2f
	int 10h

	mov ax,dx		; separate out year
	shr ax,9
	and ax,0x3F
	add ax,1980
	xor dx, dx
	mov bx, 100
	div bx
	mov ax, dx
	cmp al, 10
	jae .yy
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .yy:
	call os_int_to_string
	mov si, ax
	call os_print_string

	popa
	ret

; type a DOS format (short, 8.3) file name
; based on ASCII-7 file string (no UTF)
; allows a few more characters then PCDOS (ignores control, space, <del> and graphics)
; IN: ES:DI points to name in directory entry
type_name:
	pusha
	mov bx, di
	mov cx, 8
	add bx, cx		; point to extension

  .name_str1:
	mov al, [es:di]
	inc di
	cmp al,' '		; must be between '!' and '~'
	je .q_extend		; <space> is an unused slot
	jle .name_end		; 0 = entry not used, control not allowed
	cmp al,'~'		; no <del>, bit 8 set on delete (should be ASCII-7)
	ja .name_end
	mov ah, 0x0e
	int 10h
	loop .name_str1

  .q_extend:
	mov al,'.'		; output only if valid extension
	cmp byte [es:bx],' '	; space => no extension
	jle .name_end
	mov ah, 0x0e
	int 10h
	mov di, bx
	mov cx,3

  .name_str2:
	mov al, [es:di]
	inc di
	cmp al,' '		; must be between '!' and '~'
	jle .name_end
	cmp al,'~'		; no <del> or above
	ja .name_end
	mov ah, 0x0e
	int 10h
	loop .name_str2

  .name_end:
	popa
	ret


; =====================================================================

exit:
	ret


; =====================================================================

	input			times 64 db 0
	command			times 32 db 0

	dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	bin_extension		db '.BIN', 0
	bas_extension		db '.BAS', 0
	pcx_extension		db '.PCX', 0

	prompt			db 'GMUOS-T3> ', 0

	help_text	db 13, 10, '              GMU-SHELL', 13, 10
				db '========================================', 13, 10
				db 'Command       | Description', 13, 10
				db '--------------+-------------------------', 13, 10
				db 'DIR           | List files in directory', 13, 10
				db 'LS            | List files in directory', 13, 10
				db 'COPY          | Copy a file', 13, 10
				db 'REN           | Rename a file', 13, 10
				db 'DEL           | Delete a file', 13, 10
				db 'CAT           | Display a text file', 13, 10
				db 'SIZE          | Show file size', 13, 10
				db 'CLS           | Clear the screen', 13, 10
				db 'HELP          | Show this command table', 13, 10
				db 'ABOUT         | Show GM University information', 13, 10
				db 'TIME          | Show the current time', 13, 10
				db 'DATE          | Show the current date', 13, 10
				db 'VER           | Show GMU-OS version', 13, 10
				db 'EXIT          | Leave the command shell', 13, 10, 13, 10, 0
	dir_help_text	db 'DIR: List files in directory', 13, 10, 'eg: DIR', 13, 10, 0
	ls_help_text	db 'LS: List files in directory', 13, 10, 'eg: LS', 13, 10, 0
	copy_help_text	db 'COPY: Copy a file', 13, 10, 'eg: COPY SOURCE.TXT DEST.TXT', 13, 10, 0
	ren_help_text	db 'REN: Rename a file', 13, 10, 'eg: REN OLD.TXT NEW.TXT', 13, 10, 0
	del_help_text	db 'DEL: Delete a file', 13, 10, 'eg: DEL OLD.TXT', 13, 10, 0
	cat_help_text	db 'CAT: Display a text file', 13, 10, 'eg: CAT README.TXT', 13, 10, 0
	size_help_text	db 'SIZE: Show file size', 13, 10, 'eg: SIZE README.TXT', 13, 10, 0
	cls_help_text	db 'CLS: Clear the screen', 13, 10, 'eg: CLS', 13, 10, 0
	help_help_text	db 'HELP: Show the command table', 13, 10, 'eg: HELP', 13, 10, 0
	about_help_text	db 'ABOUT: Show GM University information', 13, 10, 'eg: ABOUT', 13, 10, 0
	time_help_text	db 'TIME: Show the current time', 13, 10, 'eg: TIME', 13, 10, 0
	date_help_text	db 'DATE: Show the current date', 13, 10, 'eg: DATE', 13, 10, 0
	ver_help_text	db 'VER: Show GMU-OS version', 13, 10, 'eg: VER', 13, 10, 0
	exit_help_text	db 'EXIT: Leave the command shell', 13, 10, 'eg: EXIT', 13, 10, 0
	about_text	db 13, 10, 'GMU-OS', 13, 10, 13, 10
				db 'Igniting Innovation, Inspiring Transformation ...', 13, 10, 13, 10
				db 'Welcome to GMU-OS - A hub for Academic progress', 13, 10
				db 'and personal growth, cultivating innovation and', 13, 10
				db 'futuristic-thinkers.', 13, 10, 13, 10, 0
	invalid_msg		db 'No such command or program', 13, 10, 0
	nofilename_msg		db 'No filename or not enough filenames', 13, 10, 0
	notfound_msg		db 'File not found', 13, 10, 0
	writefail_msg		db 'Could not write file. Write protected or invalid filename?', 13, 10, 0
	exists_msg		db 'Target file already exists!', 13, 10, 0
	finished_msg		db '>>> Program finished, press any key to continue...', 0
	leap_msg		db 'Leap year', 13, 10, 0
	not_leap_msg		db 'Not a leap year', 13, 10, 0
	invalid_date_msg	db 'Use DATE dd/mm/yyyy', 13, 10, 0

	version_msg		db 'GMU-OS ', MIKEOS_VER, 13, 10, 0

	exit_string		db 'EXIT', 0
	help_string		db 'HELP', 0
	about_string		db 'ABOUT', 0
	cls_string		db 'CLS', 0
	dir_string		db 'DIR', 0
	time_string		db 'TIME', 0
	date_string		db 'DATE', 0
	ver_string		db 'VER', 0
	cat_string		db 'CAT', 0
	del_string		db 'DEL', 0
	ren_string		db 'REN', 0
	copy_string		db 'COPY', 0
	size_string		db 'SIZE', 0
	list_string		db 'LS', 0

	kern_file_string	db 'KERNEL', 0
	kern_warn_msg		db 'Cannot execute kernel file!', 13, 10, 0


; ==================================================================

