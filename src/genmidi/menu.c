/*============================================================================
	Aznable OS - Popup menu functions

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-07-13

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
#include "../shared/sys.h"
#include "../shared/ui.h"
#include "../shared/ps2.h"
#include "menu.h"
#include "inputtester_sys.h"

// Menu variables
unsigned char menu_timer = 0;
unsigned char menu_index = 2;
unsigned char menu_dirty = 0;
unsigned char menu_ready = 0;
char *menu_string[] = {
	"Digital",
	"Analog",
	"Advanced",
	"Gunsight",
	"Button test",
	"Credits"};

// Initialise menu state
void start_menu()
{
	state = STATE_MENU;
	menu_timer = 0;
	menu_ready = 0;
}

// Menu state
void menu()
{
	// // Handle PS/2 inputs whenever possible to improve latency
	//handle_ps2();

	// Check inputs at end of each scanline.  Is this too much?!
	if (HBLANK_RISING)
	{
		basic_input();
		if (input_up && !input_up_last) // up
		{
			menu_index--;
			if (menu_index > 128)
			{
				menu_index = menu_count - 1;
			}
			menu_dirty = true;
		}
		if (input_down && !input_down_last) // down
		{
			menu_index++;
			if (menu_index == menu_count)
			{
				menu_index = 0;
			}
			menu_dirty = true;
		}
		if ((!input_start && input_start_last) || (!input_a && input_a_last) || (!input_b && input_b_last))
		{
			// Clear menu flag to avoid double trigger
			system_menu = 0;
			switch (menu_index)
			{
			case 0:
				state = STATE_START_INPUTTESTER;
				break;
			case 1:
				state = STATE_START_INPUTTESTERANALOG;
				break;
			case 2:
				state = STATE_START_INPUTTESTERADVANCED;
				break;
			case 3:
				state = STATE_START_GUNSIGHT;
				break;
			case 4:
				state = STATE_START_BTNTEST;
				break;
			case 5:
				state = STATE_START_CREDITS;
				break;
			}
		}
	}

	// As soon as vsync is detected start drawing screen updates
	if (VBLANK_RISING)
	{
		//char maxsize = (menu_count * 3) + 1 + (menu_count % 2);
		char maxsize = (menu_count * 3) + 2;

		if (menu_timer < maxsize)
		{
			char oy1 = ((menu_timer) / 2);
			char oy2 = oy1 + ((menu_count % 2) ? 0 : 1);
			char my = menu_my;
			panel_shaded(menu_tx, my - oy1, menu_bx, my + oy2, menu_panel_outline_high, menu_panel_outline_mid, menu_panel_outline_low);
			if (oy1 > 1)
			{
				fill(menu_tx + 1, my - (oy1 - 1), menu_bx - 1, my + (oy2 - 1), 0, 0);
				fill_bgcol(menu_tx + 1, my - (oy1 - 1), menu_bx - 1, my + (oy2 - 1), menu_panel_back);
			}
			menu_timer++;
			if (menu_timer == maxsize)
			{
				menu_dirty = true;
			}
		}
		else
		{
			if (menu_dirty)
			{
				char ty = menu_my - ((menu_count * 3) / 2);
				if((menu_count % 2)==0) ty++;
				for (char m = 0; m < menu_count; m++)
				{
					if (menu_index == m)
					{
						panel_shaded(menu_tx + 1, ty, menu_bx - 1, ty + 2, menu_sel_outline_high, menu_sel_outline_mid, menu_sel_outline_low);
						write_string(menu_string[m], menu_sel_text, menu_tx + 2, ty + 1);
					}
					else
					{
						panel_shaded(menu_tx + 1, ty, menu_bx - 1, ty + 2, menu_outline_high, menu_outline_mid, menu_outline_low);
						write_string(menu_string[m], menu_text, menu_tx + 2, ty + 1);
					}
					ty += 3;
				}
				menu_dirty = false;
				menu_ready = true;
			}
		}
	}
}
