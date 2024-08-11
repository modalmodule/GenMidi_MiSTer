/*============================================================================
	Aznable OS - System loader

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-01-07

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
#include "../shared/sound.h"
#include "../shared/sprite.h"
#include "../shared/starfield.h"
#include "sound_samples.h"

const char *system_title = "AZNABLE";

// Loader (aesthetic pointlessness)
void intro_text(const char *text, unsigned char start_x, unsigned char start_y, unsigned char space_x, unsigned char speed, unsigned char flash_speed)
{
	unsigned char text_timer = 0;
	unsigned char text_length = 1;
	unsigned char text_flash = 0;
	unsigned char text_flash_timer = 0;
	unsigned char text_char_count = strlen(text);

	// Speed things up in debug mode
	if (CHECK_BIT(input0, 0))
	{
		speed = 1;
		flash_speed = 1;
	}

	while (1)
	{
		vblank = CHECK_BIT(input0, INPUT_VBLANK);

		// Aznable title intro
		if (VBLANK_RISING)
		{
			unsigned char xpos = start_x + ((text_length - 1) * space_x);
			text_timer++;
			if (text_timer == speed)
			{
				write_char(text[text_length - 1], 0xFF, xpos, start_y);
				text_length++;
				if (text_length > text_char_count)
				{
					break;
				}
				text_timer = 0;
				text_flash_timer = 0;
			}
			else
			{
				text_flash_timer++;
				if (text_flash_timer == flash_speed)
				{
					text_flash++;
					if (text_flash == 2)
					{
						text_flash = 0;
					}
					if (text_flash == 1)
					{
						write_char(0, 0, xpos, start_y);
					}
					else
					{
						write_char(text[text_length - 1], 0xFF, xpos, start_y);
					}
					text_flash_timer = 0;
				}
			}
		}
		vblank_last = vblank;
	}
}
void loader(const char *title)
{

	// Set charmap area
	chram_size = chram_cols * chram_rows;
	// Clear charmap
	clear_bgcolor(transparent_char);
	clear_chars(0);
	// Reset sprites
	clear_sprites();
	update_sprites();
	// Reset starfields
	disable_starfield();

	// OS Intro
	write_char('>', 0xFF, 0, 1);
	intro_text(system_title, 2, 1, 2, 8, 1);
	write_char(' ', 0xFF, 0, 1);

	write_char('>', 0xFF, 0, 3);
	intro_text("LOAD ", 2, 3, 1, 2, 1);
	intro_text(title, 7, 3, 1, 2, 1);
	write_char(' ', 0xFF, 0, 3);

	write_char('>', 0xFF, 0, 5);
	intro_text("...", 2, 5, 1, 8, 1);

	// Clear characters
	clear_char_area(0, 1, 1, 40, 3);
}