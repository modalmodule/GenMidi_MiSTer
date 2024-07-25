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

#include "sys.h"
#include "ps2.h"

// COMMAND KEYS
const char KEY_TAB = 0x0d;
const char KEY_CAPSLOCK = 0x58;
const char KEY_ENTER = 0x5a;
const char KEY_BACKSPACE = 0x66;
const char KEY_ESC = 0x76;
const char KEY_LEFTSHIFT = 0x12;
const char KEY_RIGHTSHIFT = 0x59;
const char KEY_ALT = 0x11;	// EXT 0 = LEFT, EXT 1 = RIGHT
const char KEY_CTRL = 0x63; // EXT 0 = LEFT, EXT 1 = RIGHT

// USEFUL KEYS
const char KEY_1 = 0x16;
const char KEY_SPACE = 0x29;

// EXTENSION KEYS
const char KEY_UP = 0x75;
const char KEY_LEFT = 0x6b;
const char KEY_RIGHT = 0x74;
const char KEY_DOWN = 0x72;


const char* notenames[12] = {
	"C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#", "A ", "A#", "B "
};
const char* off = {
	"OFF"
};
char kbd_UK[256] =
{
		0, 'C0',		// 0x00
		0, 'C#0',		// 0x01
		0, 'D0',		// 0x02
		0, 'D#0',		// 0x03
		0, 'E0',		// 0x04
		0, 'F0',		// 0x05
		0, 'F#0',		// 0x06
		0, 'G0',		// 0x07
		0, 'G#0',		// 0x08
		0, 'A0',		// 0x09
		0, 'A#0',		// 0x0a
		0, 'B0',		// 0x0b
		0, 'C1',		// 0x0c
		0, 0,		// 0x0d
		'¬', '`',	// 0x0e
		0, 0,		// 0x0f
		0, 0,		// 0x10
		0, 0,		// 0x11
		0, 0,		// 0x12
		0, 0,		// 0x13
		0, 0,		// 0x14
		'Q', 'q',	// 0x15
		'!', '1',	// 0x16
		0, 0,		// 0x17
		0, 0,		// 0x18
		0, 0,		// 0x19
		'Z', 'z',	// 0x1a
		'S', 's',	// 0x1b
		'A', 'a',	// 0x1c
		'W', 'w',	// 0x1d
		'"', '2',	// 0x1e
		0, 0,		// 0x1f
		0, 0,		// 0x20
		'C', 'c',	// 0x21
		'X', 'x',	// 0x22
		'D', 'd',	// 0x23
		'E', 'e',	// 0x24
		'$', '4',	// 0x25
		'£', '3',	// 0x26
		0, 0,		// 0x27
		0, 0,		// 0x28
		' ', ' ',	// 0x29
		'V', 'v',	// 0x2a
		'F', 'f',	// 0x2b
		'T', 't',	// 0x2c
		'R', 'r',	// 0x2d
		'%', '5',	// 0x2e
		0, 0,		// 0x2f
		0, 0,		// 0x30
		'N', 'n',	// 0x31
		'B', 'b',	// 0x32
		'H', 'h',	// 0x33
		'G', 'g',	// 0x34
		'Y', 'y',	// 0x35
		'^', '6',	// 0x36
		0, 0,		// 0x37
		0, 0,		// 0x38
		0, 0,		// 0x39
		'M', 'm',	// 0x3a
		'J', 'j',	// 0x3b
		'U', 'u',	// 0x3c
		'&', '7',	// 0x3d
		'*', '8',	// 0x3e
		0, 0,		// 0x3f
		0, 0,		// 0x40
		'<', ',',	// 0x41
		'K', 'k',	// 0x42
		'I', 'i',	// 0x43
		'O', 'o',	// 0x44
		')', '0',	// 0x45
		'(', '9',	// 0x46
		0, 0,		// 0x47
		0, 0,		// 0x48
		'>', '.',	// 0x49
		'?', '/',	// 0x4a
		'L', 'l',	// 0x4b
		':', ';',	// 0x4c
		'P', 'p',	// 0x4d
		'_', '-',	// 0x4e
		0, 0,		// 0x4f
		0, 0,		// 0x50
		0, 0,		// 0x51
		'@', '\'',	// 0x52
		0, 0,		// 0x53
		'{', '[',	// 0x54
		'+', '=',	// 0x55
		0, 0,		// 0x56
		0, 0,		// 0x57
		'+', '=',	// 0x58
		0, 0,		// 0x59 (RSHIFT)
		'\n', '\n', // 0x5a (ENTER)
		'}', ']',	// 0x5b
		0, 0,		// 0x5c
		'|', '\\',	// 0x5d
		0, 0,		// 0x5e
		0, 0,		// 0x5f
		0, 0,		// 0x60
		0, 0,		// 0x61
		0, 0,		// 0x62
		0, 0,		// 0x63
		0, 0,		// 0x64
		0, 0,		// 0x65
		'\b', '\b', // 0x66
		0, 0};
	/*{
		0, 0,		// 0x00
		0, 0,		// 0x01
		0, 0,		// 0x02
		0, 0,		// 0x03
		0, 0,		// 0x04
		0, 0,		// 0x05
		0, 0,		// 0x06
		0, 0,		// 0x07
		0, 0,		// 0x08
		0, 0,		// 0x09
		0, 0,		// 0x0a
		0, 0,		// 0x0b
		0, 0,		// 0x0c
		0, 0,		// 0x0d
		'¬', '`',	// 0x0e
		0, 0,		// 0x0f
		0, 0,		// 0x10
		0, 0,		// 0x11
		0, 0,		// 0x12
		0, 0,		// 0x13
		0, 0,		// 0x14
		'Q', 'q',	// 0x15
		'!', '1',	// 0x16
		0, 0,		// 0x17
		0, 0,		// 0x18
		0, 0,		// 0x19
		'Z', 'z',	// 0x1a
		'S', 's',	// 0x1b
		'A', 'a',	// 0x1c
		'W', 'w',	// 0x1d
		'"', '2',	// 0x1e
		0, 0,		// 0x1f
		0, 0,		// 0x20
		'C', 'c',	// 0x21
		'X', 'x',	// 0x22
		'D', 'd',	// 0x23
		'E', 'e',	// 0x24
		'$', '4',	// 0x25
		'£', '3',	// 0x26
		0, 0,		// 0x27
		0, 0,		// 0x28
		' ', ' ',	// 0x29
		'V', 'v',	// 0x2a
		'F', 'f',	// 0x2b
		'T', 't',	// 0x2c
		'R', 'r',	// 0x2d
		'%', '5',	// 0x2e
		0, 0,		// 0x2f
		0, 0,		// 0x30
		'N', 'n',	// 0x31
		'B', 'b',	// 0x32
		'H', 'h',	// 0x33
		'G', 'g',	// 0x34
		'Y', 'y',	// 0x35
		'^', '6',	// 0x36
		0, 0,		// 0x37
		0, 0,		// 0x38
		0, 0,		// 0x39
		'M', 'm',	// 0x3a
		'J', 'j',	// 0x3b
		'U', 'u',	// 0x3c
		'&', '7',	// 0x3d
		'*', '8',	// 0x3e
		0, 0,		// 0x3f
		0, 0,		// 0x40
		'<', ',',	// 0x41
		'K', 'k',	// 0x42
		'I', 'i',	// 0x43
		'O', 'o',	// 0x44
		')', '0',	// 0x45
		'(', '9',	// 0x46
		0, 0,		// 0x47
		0, 0,		// 0x48
		'>', '.',	// 0x49
		'?', '/',	// 0x4a
		'L', 'l',	// 0x4b
		':', ';',	// 0x4c
		'P', 'p',	// 0x4d
		'_', '-',	// 0x4e
		0, 0,		// 0x4f
		0, 0,		// 0x50
		0, 0,		// 0x51
		'@', '\'',	// 0x52
		0, 0,		// 0x53
		'{', '[',	// 0x54
		'+', '=',	// 0x55
		0, 0,		// 0x56
		0, 0,		// 0x57
		'+', '=',	// 0x58
		0, 0,		// 0x59 (RSHIFT)
		'\n', '\n', // 0x5a (ENTER)
		'}', ']',	// 0x5b
		0, 0,		// 0x5c
		'|', '\\',	// 0x5d
		0, 0,		// 0x5e
		0, 0,		// 0x5f
		0, 0,		// 0x60
		0, 0,		// 0x61
		0, 0,		// 0x62
		0, 0,		// 0x63
		0, 0,		// 0x64
		0, 0,		// 0x65
		'\b', '\b', // 0x66
		0, 0};*/

char kbd_in[2];
char kbd_in2[2];
char kbd_in3[2];
char kbd_in4[2];
char kbd_in_poly[2][16];
char kbd_lastclock = 0;
char kbd_lastclock2 = 0;
char kbd_lastclock3 = 0;
char kbd_lastclock4 = 0;
char kbd_lastclock_poly[16];
char kbd_shift_left = 0;
char kbd_shift_right = 0;
char kbd_scan = 0;
char kbd_scan2 = 0;
char kbd_scan3 = 0;
char kbd_scan4 = 0;
char kbd_scan_poly[16];
char kbd_pressed;
char kbd_pressed2;
char kbd_pressed3;
char kbd_pressed4;
char kbd_extend;
char kbd_ascii = 0;
char* kbd_asciis;
char* kbd_asciis2;
char* kbd_asciis3;
char* kbd_asciis4;
char* kbd_asciis_poly[16];


char mse_lastclock = 0;
bool mse_changed = 1;
signed char mse_x;
signed char mse_y;
signed char mse_w;
char mse_button1;
char mse_button2;

char kbd_buffer[128];
char kbd_buffer_len = 0;
bool kbd_down[256];


/*void get_ascii()
{
	kbd_asciis = notenames[kbd_scan % 12];
}

void get_ascii2()
{
	kbd_asciis2 = notenames[kbd_scan2 % 12];
}

void get_ascii3()
{
	kbd_asciis3 = notenames[kbd_scan3 % 12];
}

void get_ascii_poly(int i)
{
	kbd_asciis_poly[i] = notenames[kbd_scan_poly[i] % 12];
}*/

void handle_sq1()
{
	char kbd_clock = sq1[0];
		for (char k = 0; k < 2; k++)
		{
			kbd_in[k] = sq1[k];
		}
		kbd_pressed = CHECK_BIT(kbd_in[1], 1) > 0;
		kbd_scan = kbd_in[0];
		if (kbd_pressed)
		{
			if (kbd_clock != kbd_lastclock || !strcmp(kbd_asciis,off)) { 
				kbd_asciis = notenames[kbd_scan % 12];
			}
		}
		else
		{
			kbd_asciis = off;
		}
	kbd_lastclock = kbd_clock;
}

void handle_sq2()
{
	char kbd_clock2 = sq2[0];
		for (char k = 0; k < 2; k++)
		{
			kbd_in2[k] = sq2[k];
		}
		kbd_pressed2 = CHECK_BIT(kbd_in2[1], 1) > 0;
		kbd_scan2 = kbd_in2[0];
		if (kbd_pressed2)
		{
			if (kbd_clock2 != kbd_lastclock2 || !strcmp(kbd_asciis2,off)) {
				kbd_asciis2 = notenames[kbd_scan2 % 12];
			}
		}
		else
		{
			kbd_asciis2 = off;
		}
	kbd_lastclock2 = kbd_clock2;
}

void handle_wav()
{
	char kbd_clock3 = wav[0];
		for (char k = 0; k < 2; k++)
		{
			kbd_in3[k] = wav[k];
		}
		kbd_pressed3 = CHECK_BIT(kbd_in3[1], 1) > 0;
		kbd_scan3 = kbd_in3[0];
		if (kbd_pressed3)
		{
			if (kbd_clock3 != kbd_lastclock3 || !strcmp(kbd_asciis3,off)) {
				kbd_asciis3 = notenames[kbd_scan3 % 12];
			}
		}
		else
		{
			kbd_asciis3 = off;
		}
	kbd_lastclock3 = kbd_clock3;
}

void handle_noi()
{
	char kbd_clock4 = noi[0];
		for (char k = 0; k < 2; k++)
		{
			kbd_in4[k] = noi[k];
		}
		kbd_pressed4 = CHECK_BIT(kbd_in4[1], 1) > 0;
		kbd_scan4 = kbd_in4[0];
		if (kbd_pressed4)
		{
			if (kbd_clock4 != kbd_lastclock4 || !strcmp(kbd_asciis4,off)) {
				kbd_asciis4 = notenames[kbd_scan4 % 12];
			}
		}
		else
		{
			kbd_asciis4 = off;
		}
	kbd_lastclock4 = kbd_clock4;
}

void handle_poly()
{
	for (int i = 0; i < 16; i++) {
		char kbd_clock_poly = analog_l[i+i];
			for (char k = 0; k < 2; k++)
			{
				kbd_in_poly[k][i] = analog_l[i+i+k];
			}
			//kbd_extend2 = CHECK_BIT(kbd_in2[1], 0) > 0;
			bool kbd_pressed_poly = CHECK_BIT(kbd_in_poly[1][i], 1) > 0;
			kbd_scan_poly[i] = kbd_in_poly[0][i];
			if (kbd_pressed_poly)
			{
				if (kbd_clock_poly != kbd_lastclock_poly[i] || !strcmp(kbd_asciis_poly[i],off)) {
					kbd_asciis_poly[i] = notenames[kbd_scan_poly[i] % 12];
				}
			}
			else
			{
				kbd_asciis_poly[i] = off;
			}
		kbd_lastclock_poly[i] = kbd_clock_poly;
	}
}