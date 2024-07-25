/*============================================================================
	Aznable OS - Credits

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-01-05

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
#include "../shared/sprite.h"
#include "../shared/music.h"
#include "../shared/tilemap.h"
#include "../shared/starfield.h"
#include "credits.h"
#include "inputtester_sys.h"

const char *credits_text = "CODE AND GFX_-_JIMMYSTONES___MUSIC_-_DARRIN CARDANI___TESTING_-_PORKCHOP EXPRESS_SORGELIG_M WALRUS___EXTRA THANKS_-_ALANSWX_SORGELIG___";
unsigned char credits_pos = 0;
unsigned short credits_entry_pos = (16 * 32);

void app_credits()
{
	clear_chars(0);
	clear_sprites();
	clear_tilemap();
	stop_music();

	enable_starfield();
	set_starfield_speed_x(0);
	set_starfield_speed_y(-16);

	tilemap_offset_x = 0;
	tilemap_offset_y = 0;

	char credits_line[22];
	credits_pos = 0;

	while (1)
	{
		vblank = CHECK_BIT(input0, INPUT_VBLANK);

		if (VBLANK_RISING)
		{
			if (tilemap_offset_y >= 16)
			{
				tilemap_offset_y -= 16;
				update_tilemap_offset();

				scroll_tilemap_up();

				unsigned char d;
				unsigned char c;
				unsigned char credits_line_len = 0;
				for (d = 0; d < 22; d++)
				{
					c = credits_text[credits_pos];
					credits_pos++;
					if (c == '_' || c == 0)
					{
						break;
					}
					else
					{
						credits_line[d] = c;
						credits_line_len++;
					}
					if (credits_pos >= strlen(credits_text) - 1)
					{
						credits_pos = 0;
						break;
					}
				}
				signed char credits_line_pre = (22 - credits_line_len) / 2;
				for (d = 0; d < 22; d++)
				{
					c = 0;
					signed char i = d - credits_line_pre;
					if (i >= 0 && i < credits_line_len)
					{
						c = (credits_line[i] != '-') ? (credits_line[i] - 45) : 1;
					}
					tilemapram[credits_entry_pos + d] = c;
				}
			}
			else
			{
				update_tilemap_offset();
			}
		}

		if (VBLANK_FALLING)
		{
			//handle_ps2();
			basic_input();
			if (input_a || input_b || input_select || input_start)
			{
				break;
			}
			signed dir = 1;
			tilemap_offset_y += 2;
			if (input_up)
			{
				tilemap_offset_y += 4;
			}
		}

		vblank_last = vblank;
	}

	clear_chars(0);
	clear_sprites();
	clear_tilemap();
	stop_music();

	disable_starfield();

	state = defaultstate;
}