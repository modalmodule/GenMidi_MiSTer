/*============================================================================
	Aznable OS - User interface functions

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
	Date: 2021-07-15

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
#ifndef UI_H
#define UI_H

extern char asc_0;
extern char asc_1;

#define transparent_char 0b11000111

#define char_corner_round_tl 149
#define char_corner_round_tr 137
#define char_corner_round_bl 138
#define char_corner_round_br 139
#define char_line_h 131
#define char_line_v 130
#define char_t_up 177
#define char_dot 27
#define char_cross 155

// Set all character RAM to specified character
extern void clear_chars(char c);

// Set area of character RAM to specified character
extern void clear_char_area(char c, unsigned char tx, unsigned char ty, unsigned char bx, unsigned char by);

// Set all character background colours to specified
extern void clear_bgcolor(char color);

// Write string to character RAM
extern void write_string(const char *string, char color, unsigned char x, unsigned char y);

// Write formatted string to character RAM (signed char data)
extern void write_stringfs(const char *format, char color, unsigned char x, unsigned char y, signed char data);

// Write formatted string to character RAM (unsigned char data)
extern void write_stringf(const char *format, char color, unsigned char x, unsigned char y, unsigned char data);

// Write formatted string to character RAM (unsigned short data)
extern void write_stringf_ushort(const char *format, char color, unsigned char x, unsigned char y, unsigned short data);

// Write formatted string to character RAM (signed short data)
extern void write_stringf_short(const char *format, char color, unsigned char x, unsigned char y, signed short data);

// Write formatted string to character RAM (unsigned long data)
extern void write_stringf_ulong(const char *format, char color, unsigned char x, unsigned char y, unsigned long data);

// Write single char to character RAM and colour RAM
extern void write_char(unsigned char c, char color, unsigned char x, unsigned char y);

// Write row of consecutive chars to character RAM and colour RAM
extern void write_char_row(unsigned char c, char color, unsigned char x, unsigned char y, unsigned char count);

// Set colour of single char
extern void set_fgcolour(char color, char x, char y);

// Set background colour of single char
extern void set_bgcolour(char color, char x, char y);

// Write row of consecutive chars to character RAM and colour RAM
extern void write_bgcol_row(char color, unsigned char x, unsigned char y, unsigned char count);

// Write grouped bits to character RAM
extern void write_bits(char bits[], char multi, unsigned char first, unsigned char length, char color, unsigned char x, unsigned char y);

// Draw box outline with specified character
extern void box(unsigned char tx, unsigned char ty, unsigned char bx, unsigned char by, char c, char color);

// Draw UI panel
extern void panel(char tx, char ty, char bx, char by, char color);

// Shaded panel
extern void panel_shaded(char tx, char ty, char bx, char by, char color_high, char color1, char color2);

extern void fill(char tx, char ty, char bx, char by, char c, char color);

extern void fill_bgcol(char tx, char ty, char bx, char by, char color);

// Draw page border
extern void page_border(char color);

extern void draw_charactermap();

#endif