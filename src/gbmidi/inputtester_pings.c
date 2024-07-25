/*============================================================================
	Input Test - Mouse ping animations

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-12-22

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
#include "../shared/sprite.h"
#include "sprite_images.h"
#include "inputtester_pings.h"

#define const_ping_max 8
unsigned char ping_max = const_ping_max;
unsigned char ping_sprite_first = 0;
unsigned char ping_timer[const_ping_max];
unsigned char ping_frame[const_ping_max];
unsigned char ping_type[const_ping_max];
const unsigned char ping_lifespan = 2;
#define ping_frame_count 7
#define ping_type_count 2

void setup_pings()
{
	for (int e = ping_sprite_first; e < ping_sprite_first + ping_max; e++)
	{
		enable_sprite(e, sprite_palette_pings, sprite_size_pings, false);
		spr_on[e] = false;
	}
}

void add_ping(unsigned type, unsigned short x, unsigned short y)
{
	for (unsigned char e = 0; e < ping_max; e++)
	{
		if (ping_timer[e] == 0)
		{
			ping_timer[e] = ping_lifespan;
			ping_frame[e] = 0;
			type = 0;
			// ping_type[e] = type;
			unsigned char sprite = ping_sprite_first + e;
			enable_sprite(sprite, sprite_palette_pings, sprite_size_pings, 0);
			spr_index[sprite] = sprite_index_pings_first + (type * ping_frame_count);
			set_sprite_position(sprite, x, y);
			return;
		}
	}
}

void handle_pings()
{
	for (unsigned char t = 0; t < ping_max; t++)
	{
		if (ping_timer[t] > 0)
		{
			ping_timer[t]--;
			if (ping_timer[t] == 0)
			{
				unsigned char sprite = ping_sprite_first + t;
				spr_index[sprite]++;
				ping_frame[t]++;
				if (ping_frame[t] == ping_frame_count)
				{
					spr_on[sprite] = false;
				}
				else
				{
					ping_timer[t] = ping_lifespan;
				}
			}
		}
	}
}