/*============================================================================
	Input Test - Custom UI functions

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-07-12

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
#include <stdbool.h>
#include "../shared/sys.h"
#include "../shared/ui.h"
#include "inputtester_ui.h"

void page_frame(bool showMenuButton, bool showContinueButton)
{
	bool footer = showMenuButton || showContinueButton;
	clear_chars(0);
	write_string("Game Boy Midi Module", 0b11111111, 10, 1); //MiSTer Input Tester
	panel_shaded(0, 0, 39, 2, 0b00000111, 0b00000110, 0b00000100);
	panel_shaded(0, 3, 39, footer ? 26 : 29, 0b10100100, 0b10100100, 0b01010010);
	if (footer)
	{
		char buttons = showMenuButton && showContinueButton ? 2 : 1;
		char x1 = buttons == 1 ? 39 : 19;
		char m1 = buttons == 1 ? 20 : 10;
		panel_shaded(0, 27, x1, 29, 0b11000000, 0b10000000, 0b01000000);
		if (buttons == 2)
		{
			panel_shaded(x1 + 1, 27, 39, 29, 0b11000000, 0b10000000, 0b01000000);
		}
		if (showMenuButton)
		{
			write_string("Use OSD to Change Settings", 0b11011011, 7, 28); //m1 - 9
			m1 += 20;
		}
		if (showContinueButton)
		{
			write_string("Start: Continue", 0b11011011, m1 - 8, 28);
		}
	}
}

// Draw game pad outline
void draw_pad(char xo, char yo)
{
	// Outline
	write_char(char_corner_round_tl, color_pad_outline, xo, yo + 2);
	write_char_row(char_line_h, color_pad_outline, xo + 1, yo + 2, 25);
	write_char(char_corner_round_tr, color_pad_outline, xo + 26, yo + 2);
	for (char y = 3; y < 8; y++)
	{
		write_char(char_line_v, color_pad_outline, xo, yo + y);
		write_char(char_line_v, color_pad_outline, xo + 26, yo + y);
	}
	write_char(char_corner_round_bl, color_pad_outline, xo, yo + 8);
	write_char(char_corner_round_br, color_pad_outline, xo + 26, yo + 8);

	write_char(char_corner_round_br, color_pad_outline, xo + 8, yo + 8);
	write_char(char_corner_round_bl, color_pad_outline, xo + 18, yo + 8);
	write_char(char_corner_round_tl, color_pad_outline, xo + 8, yo + 7);
	write_char(char_corner_round_tr, color_pad_outline, xo + 18, yo + 7);

	write_char_row(char_line_h, color_pad_outline, xo + 1, yo + 8, 7);
	write_char_row(char_line_h, color_pad_outline, xo + 9, yo + 7, 9);
	write_char_row(char_line_h, color_pad_outline, xo + 19, yo + 8, 7);

	// Shoulders
	write_char(char_line_v, color_pad_outline, xo + 1, yo + 1);
	write_char(char_t_up, color_pad_outline, xo + 1, yo + 2);
	write_char(char_corner_round_tl, color_pad_outline, xo + 1, yo);
	write_char_row(char_line_h, color_pad_outline, xo + 2, yo, 3);
	write_char(char_line_v, color_pad_outline, xo + 5, yo + 1);
	write_char(char_t_up, color_pad_outline, xo + 5, yo + 2);
	write_char(char_corner_round_tr, color_pad_outline, xo + 5, yo);
	write_char(char_line_v, color_pad_outline, xo + 21, yo + 1);
	write_char(char_t_up, color_pad_outline, xo + 21, yo + 2);
	write_char(char_corner_round_tl, color_pad_outline, xo + 21, yo);
	write_char_row(char_line_h, color_pad_outline, xo + 22, yo, 3);
	write_char(char_line_v, color_pad_outline, xo + 25, yo + 1);
	write_char(char_t_up, color_pad_outline, xo + 25, yo + 2);
	write_char(char_corner_round_tr, color_pad_outline, xo + 25, yo);
}

// Draw game pad outline
void draw_analog(char xo, char yo, char xs, char ys)
{
	panel(xo, yo, xo + xs, yo + ys, 0xFF);
	fill(xo + 1, yo + 1, xo + xs - 1, yo + ys - 1, char_dot, color_analog_grid);
	char mx = xo + (xs / 2);
	char my = yo + (ys / 2);
	write_char_row(char_line_h, color_analog_grid, xo + 1, my, xs - 1);
	for (char y = yo + 1; y < yo + ys; y++)
	{
		write_char(char_line_v, color_analog_grid, mx, y);
	}
	write_char(char_cross, color_analog_grid, mx, my);
}
