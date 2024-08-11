;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler 
; Version 4.4.0 #14620 (MINGW64)
;--------------------------------------------------------
	.module os
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _app_main
	.globl _app_credits
	.globl _fadein
	.globl _fadeout
	.globl _snek_attract
	.globl _snek_gameplay
	.globl _start_snek_gameplay
	.globl _start_snek_attract
	.globl _app_zorblaxx
	.globl _menu
	.globl _start_menu
	.globl _gunsight
	.globl _btntest
	.globl _inputtester_advanced
	.globl _inputtester_analog
	.globl _start_gunsight
	.globl _start_btntest
	.globl _start_inputtester_advanced
	.globl _start_inputtester_analog
	.globl _loader
	.globl _musicram
	.globl _sndram
	.globl _tilemapram
	.globl _tilemapctl
	.globl _spritecollisionram
	.globl _spriteram
	.globl _bgcolram
	.globl _fgcolram
	.globl _chram
	.globl _poly_en
	.globl _system_menu
	.globl _system_pause
	.globl _starfield3
	.globl _starfield2
	.globl _starfield1
	.globl _patch_display
	.globl _noise
	.globl _psg2
	.globl _psg1
	.globl _psg0
	.globl _fm5
	.globl _fm4
	.globl _fm3
	.globl _fm2
	.globl _fm1
	.globl _fm0
	.globl _spinner
	.globl _analog_l
	.globl _joystick
	.globl _video_ctl
	.globl _input0
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_input0	=	0x8000
_video_ctl	=	0x8001
_joystick	=	0x8100
_analog_l	=	0x8200
_spinner	=	0x8500
_fm0	=	0x8600
_fm1	=	0x8700
_fm2	=	0x8800
_fm3	=	0x8900
_fm4	=	0x8902
_fm5	=	0x8904
_psg0	=	0x8906
_psg1	=	0x8908
_psg2	=	0x890a
_noise	=	0x890c
_patch_display	=	0x890e
_starfield1	=	0x8a00
_starfield2	=	0x8a10
_starfield3	=	0x8a20
_system_pause	=	0x8a30
_system_menu	=	0x8a31
_poly_en	=	0x8a32
_chram	=	0x9800
_fgcolram	=	0xa000
_bgcolram	=	0xa800
_spriteram	=	0xb000
_spritecollisionram	=	0xb400
_tilemapctl	=	0x8c00
_tilemapram	=	0x8c10
_sndram	=	0x8b00
_musicram	=	0x8b10
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;os.c:33: void app_main()
;	---------------------------------
; Function app_main
; ---------------------------------
_app_main::
;os.c:35: chram_size = chram_cols * chram_rows;
	ld	a, (_chram_rows+0)
	ld	e, a
	ld	a, (_chram_cols+0)
	ld	h, a
;	spillPairReg hl
;	spillPairReg hl
	ld	l, #0x00
	ld	d, l
	ld	b, #0x08
00275$:
	add	hl, hl
	jr	NC, 00276$
	add	hl, de
00276$:
	djnz	00275$
	ld	(_chram_size), hl
;os.c:36: while (1)
00124$:
;os.c:38: hsync = input0 & 0x80;
	ld	a, (_input0+0)
	rlca
	and	a, #0x01
	ld	c, a
	xor	a, a
	cp	a, c
	rla
	ld	(_hsync+0), a
;os.c:39: vsync = input0 & 0x40;
	ld	a, (_input0+0)
	rlca
	rlca
	and	a, #0x01
	ld	c, a
	xor	a, a
	cp	a, c
	rla
	ld	(_vsync+0), a
;os.c:40: hblank = CHECK_BIT(input0, INPUT_HBLANK);
	ld	a, (_input0+0)
	rlca
	rlca
	rlca
	and	a, #0x01
	ld	c, a
	xor	a, a
	cp	a, c
	rla
	ld	(_hblank+0), a
;os.c:41: vblank = CHECK_BIT(input0, INPUT_VBLANK);
	ld	a, (_input0+0)
	rrca
	rrca
	rrca
	rrca
	and	a, #0x01
	ld	c, a
	xor	a, a
	cp	a, c
	rla
	ld	(_vblank+0), a
;os.c:42: switch (state)
	ld	a, (_state+0)
	dec	a
	jp	Z,00101$
	ld	a, (_state+0)
	sub	a, #0x02
	jp	Z,00102$
	ld	a, (_state+0)
	sub	a, #0x03
	jp	Z,00103$
	ld	a, (_state+0)
	sub	a, #0x04
	jp	Z,00104$
	ld	a, (_state+0)
	sub	a, #0x05
	jp	Z,00105$
	ld	a, (_state+0)
	sub	a, #0x06
	jp	Z,00106$
	ld	a, (_state+0)
	sub	a, #0x07
	jr	Z, 00107$
	ld	a, (_state+0)
	sub	a, #0x08
	jr	Z, 00108$
	ld	a, (_state+0)
	sub	a, #0x09
	jr	Z, 00109$
	ld	a, (_state+0)
	sub	a, #0x0a
	jr	Z, 00110$
	ld	a, (_state+0)
	sub	a, #0x0b
	jr	Z, 00111$
	ld	a, (_state+0)
	sub	a, #0x0c
	jr	Z, 00112$
	ld	a, (_state+0)
	sub	a, #0x14
	jr	Z, 00113$
	ld	a, (_state+0)
	sub	a, #0x16
	jr	Z, 00114$
	ld	a, (_state+0)
	sub	a, #0x1e
	jr	Z, 00115$
	ld	a, (_state+0)
	sub	a, #0x1f
	jr	Z, 00116$
	ld	a, (_state+0)
	sub	a, #0x28
	jr	Z, 00118$
	ld	a, (_state+0)
	sub	a, #0x29
	jr	Z, 00119$
	ld	a, (_state+0)
	sub	a, #0x2a
	jr	Z, 00117$
	ld	a, (_state+0)
	sub	a, #0x2b
	jr	Z, 00120$
	jr	00121$
;os.c:44: case STATE_START_INPUTTESTER:
00101$:
;os.c:45: start_inputtester_advanced();//start_inputtester_digital();
	call	_start_inputtester_advanced
;os.c:46: break;
	jp	00122$
;os.c:47: case STATE_INPUTTESTER:
00102$:
;os.c:48: inputtester_advanced();//inputtester_digital();
	call	_inputtester_advanced
;os.c:49: break;
	jr	00122$
;os.c:51: case STATE_START_INPUTTESTERADVANCED:
00103$:
;os.c:52: start_inputtester_advanced();
	call	_start_inputtester_advanced
;os.c:53: break;
	jr	00122$
;os.c:54: case STATE_INPUTTESTERADVANCED:
00104$:
;os.c:55: inputtester_advanced();
	call	_inputtester_advanced
;os.c:56: break;
	jr	00122$
;os.c:58: case STATE_START_INPUTTESTERANALOG:
00105$:
;os.c:59: start_inputtester_analog();
	call	_start_inputtester_analog
;os.c:60: break;
	jr	00122$
;os.c:61: case STATE_INPUTTESTERANALOG:
00106$:
;os.c:62: inputtester_analog();
	call	_inputtester_analog
;os.c:63: break;
	jr	00122$
;os.c:65: case STATE_START_BTNTEST:
00107$:
;os.c:66: start_btntest();
	call	_start_btntest
;os.c:67: break;
	jr	00122$
;os.c:68: case STATE_BTNTEST:
00108$:
;os.c:69: btntest();
	call	_btntest
;os.c:70: break;
	jr	00122$
;os.c:72: case STATE_START_GUNSIGHT:
00109$:
;os.c:73: start_gunsight();
	call	_start_gunsight
;os.c:74: break;
	jr	00122$
;os.c:75: case STATE_GUNSIGHT:
00110$:
;os.c:76: gunsight();
	call	_gunsight
;os.c:77: break;
	jr	00122$
;os.c:79: case STATE_START_MENU:
00111$:
;os.c:80: start_menu();
	call	_start_menu
;os.c:81: break;
	jr	00122$
;os.c:82: case STATE_MENU:
00112$:
;os.c:83: menu();
	call	_menu
;os.c:84: break;
	jr	00122$
;os.c:86: case STATE_FADEOUT:
00113$:
;os.c:87: fadeout();
	call	_fadeout
;os.c:88: break;
	jr	00122$
;os.c:89: case STATE_FADEIN:
00114$:
;os.c:90: fadein();
	call	_fadein
;os.c:91: break;
	jr	00122$
;os.c:93: case STATE_START_ATTRACT:
00115$:
;os.c:94: state = 0;
	ld	hl, #_state
	ld	(hl), #0x00
;os.c:95: loader("SNEK.AZN");
	ld	hl, #___str_0
	call	_loader
;os.c:96: start_snek_attract();
	call	_start_snek_attract
;os.c:97: break;
	jr	00122$
;os.c:98: case STATE_ATTRACT:
00116$:
;os.c:99: snek_attract();
	call	_snek_attract
;os.c:100: break;
	jr	00122$
;os.c:101: case STATE_START_CREDITS:
00117$:
;os.c:102: app_credits();
	call	_app_credits
;os.c:103: break;
	jr	00122$
;os.c:105: case STATE_START_GAME_SNEK:
00118$:
;os.c:106: start_snek_gameplay();
	call	_start_snek_gameplay
;os.c:107: break;
	jr	00122$
;os.c:108: case STATE_GAME_SNEK:
00119$:
;os.c:109: snek_gameplay();
	call	_snek_gameplay
;os.c:110: break;
	jr	00122$
;os.c:111: case STATE_START_ZORBLAXX:
00120$:
;os.c:112: state = 0;
	ld	hl, #_state
	ld	(hl), #0x00
;os.c:113: loader("ZORBLAXX.AZN");
	ld	hl, #___str_1
	call	_loader
;os.c:114: app_zorblaxx();
	call	_app_zorblaxx
;os.c:115: break;
	jr	00122$
;os.c:117: default:
00121$:
;os.c:122: loader("INPUTTESTER.AZN");
	ld	hl, #___str_2
	call	_loader
;os.c:124: start_inputtester_advanced();
	call	_start_inputtester_advanced
;os.c:128: }
00122$:
;os.c:130: hsync_last = hsync;
	ld	a, (_hsync+0)
	ld	(_hsync_last+0), a
;os.c:131: vsync_last = vsync;
	ld	a, (_vsync+0)
	ld	(_vsync_last+0), a
;os.c:132: hblank_last = hblank;
	ld	a, (_hblank+0)
	ld	(_hblank_last+0), a
;os.c:133: vblank_last = vblank;
	ld	a, (_vblank+0)
	ld	(_vblank_last+0), a
;os.c:135: }
	jp	00124$
___str_0:
	.ascii "SNEK.AZN"
	.db 0x00
___str_1:
	.ascii "ZORBLAXX.AZN"
	.db 0x00
___str_2:
	.ascii "INPUTTESTER.AZN"
	.db 0x00
;os.c:138: void main()
;	---------------------------------
; Function main
; ---------------------------------
_main::
;os.c:140: app_main();
;os.c:141: }
	jp	_app_main
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
