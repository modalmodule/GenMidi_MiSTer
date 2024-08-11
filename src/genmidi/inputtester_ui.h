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
#ifndef INPUTTESTER_UI_H
#define INPUTTESTER_UI_H

#define color_pad_outline 0xFE
#define color_analog_grid 0x23

extern void page_frame(bool showMenuButton, bool showContinueButton);

// Draw game pad outline
extern void draw_pad(char xo, char yo);

// Draw game pad outline
extern void draw_analog(char xo, char yo, char xs, char ys);

#endif