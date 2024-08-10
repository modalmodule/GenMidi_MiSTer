/*============================================================================
	Aznable OS - PS/2 interface functions

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
	Date: 2021-10-20

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/
#ifndef PS2_H
#define PS2_H

// COMMAND KEYS
extern const char KEY_TAB;
extern const char KEY_CAPSLOCK;
extern const char KEY_ENTER;
extern const char KEY_BACKSPACE;
extern const char KEY_ESC;
extern const char KEY_LEFTSHIFT;
extern const char KEY_RIGHTSHIFT;
extern const char KEY_ALT;
extern const char KEY_CTRL;

// USEFUL KEYS
extern const char KEY_1;
extern const char KEY_SPACE;

// UNMAPPED COMMAND KEYS
// 	0x7c, //55  KEY_KPASTERISK
// 	0x05, //59  KEY_F1
// 	0x06, //60  KEY_F2
// 	0x04, //61  KEY_F3
// 	0x0c, //62  KEY_F4
// 	0x03, //63  KEY_F5
// 	0x0b, //64  KEY_F6
// 	0x83, //65  KEY_F7
// 	0x0a, //66  KEY_F8
// 	0x01, //67  KEY_F9
// 	0x09, //68  KEY_F10
// 	0x6c, //71  KEY_KP7
// 	0x75, //72  KEY_KP8
// 	0x7d, //73  KEY_KP9
// 	0x7b, //74  KEY_KPMINUS
// 	0x6b, //75  KEY_KP4
// 	0x73, //76  KEY_KP5
// 	0x74, //77  KEY_KP6
// 	0x79, //78  KEY_KPPLUS
// 	0x69, //79  KEY_KP1
// 	0x72, //80  KEY_KP2
// 	0x7a, //81  KEY_KP3
// 	0x70, //82  KEY_KP0
// 	0x71, //83  KEY_KPDOT
// 	0x61, //86  KEY_102ND
// 	0x78, //87  KEY_F11
// 	0x07, //88  KEY_F12

// EXTENSION KEYS
extern const char KEY_UP;
extern const char KEY_LEFT;
extern const char KEY_RIGHT;
extern const char KEY_DOWN;

// UNMAPPED EXTENSION KEYS
// 	EXT | 0x5a, //96  KEY_KPENTER
// 	EXT | 0x4a, //98  KEY_KPSLASH
// 	EXT | 0x6c, //102 KEY_HOME
// 	EXT | 0x7d, //104 KEY_PAGEUP
// 	EXT | 0x69, //107 KEY_END
// 	EXT | 0x7a, //109 KEY_PAGEDOWN
// 	EXT | 0x70, //110 KEY_INSERT
// 	EXT | 0x71, //111 KEY_DELETE

extern char kbd_shift_left;
extern char kbd_shift_right;
extern char kbd_scan;
extern char kbd_pressed;
extern char kbd_extend;
extern char kbd_scan2;
extern char kbd_scan3;
extern char kbd_scan4;
extern char kbd_scan5;
extern char kbd_scan6;
extern char kbd_scan7;
extern char kbd_scan8;
extern char kbd_scan9;
extern char kbd_scan10;
extern char kbd_pressed2;
extern char kbd_pressed3;
extern char kbd_pressed4;
extern char kbd_pressed5;
extern char kbd_pressed6;
extern char kbd_pressed7;
extern char kbd_pressed8;
extern char kbd_pressed9;
extern char kbd_pressed10;
extern char kbd_extend2;
extern char kbd_scan_poly[16];
extern char kbd_ascii;
extern char* kbd_asciis;
extern char* kbd_asciis2;
extern char* kbd_asciis3;
extern char* kbd_asciis4;
extern char* kbd_asciis5;
extern char* kbd_asciis6;
extern char* kbd_asciis7;
extern char* kbd_asciis8;
extern char* kbd_asciis9;
extern char* kbd_asciis10;
extern char* kbd_asciis_poly[16];
const extern char* off;

extern bool mse_changed;
extern signed char mse_x;
extern signed char mse_y;
extern signed char mse_w;
extern char mse_button1;
extern char mse_button2;

extern char kbd_buffer[128];
extern char kbd_buffer_len;
extern bool kbd_down[256];


extern void get_ascii();

extern void handle_fm0();
extern void handle_fm1();
extern void handle_fm2();
extern void handle_fm3();
extern void handle_fm4();
extern void handle_fm5();
extern void handle_psg0();
extern void handle_psg1();
extern void handle_psg2();
extern void handle_noise();
extern void handle_poly();

#endif