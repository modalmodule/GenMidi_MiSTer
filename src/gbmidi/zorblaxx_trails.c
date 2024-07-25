/*============================================================================
	Aznable OS - Zorblaxx demo application - Trail routines

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-11-27

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
#include "zorblaxx_app.h"
#include "zorblaxx_trails.h"
#include "zorblaxx_asteroids.h"
#include "zorblaxx_player.h"

#define const_trail_max 10
unsigned char trail_max = const_trail_max;
unsigned short trail_x[const_trail_max];
unsigned short trail_y[const_trail_max];
signed char trail_xs[const_trail_max];
signed char trail_ys[const_trail_max];
unsigned char trail_timer[const_trail_max];
unsigned short trail_y_max;
unsigned char trail_x_offset;
unsigned char trail_y_offset;

void setup_trails()
{
	trail_y_max = 272 * y_divisor;
	trail_x_offset = (4 * x_divisor);
	trail_y_offset = (12 * y_divisor);
	for (int t = trail_sprite_first; t < trail_sprite_first + trail_max; t++)
	{
		enable_sprite(t, sprite_palette_trails, sprite_size_trails, false);
		spr_on[t] = false;
	}
}

void add_player_trail()
{
	for (unsigned char t = 0; t < trail_max; t++)
	{
		if (trail_timer[t] == 0)
		{
			unsigned char spread = 3 + (player_speed / 8);
			trail_xs[t] = rand_schar(-spread, spread);
			trail_ys[t] = player_trail_speed;

			trail_x[t] = (player_x + trail_x_offset);
			trail_y[t] = (player_y + trail_y_offset) - (player_trail_speed + player_speed);

			trail_timer[t] = player_trail_lifespan;
			unsigned char sprite = trail_sprite_first + t;
			enable_sprite(sprite, sprite_palette_trails, sprite_size_trails, false);
			spr_index[sprite] = sprite_index_trails_first;
			return;
		}
	}
}

void handle_trails()
{
	for (unsigned char t = 0; t < trail_max; t++)
	{
		if (trail_timer[t] > 0)
		{
			unsigned char sprite = trail_sprite_first + t;
			trail_y[t] += trail_ys[t] + player_speed;
			if ((trail_y[t] > trail_y_max) > 0)
			{
				spr_on[sprite] = false;
				trail_timer[t] = 0;
				continue;
			}
			trail_timer[t]--;
			if (trail_timer[t] == 0)
			{
				spr_index[sprite]++;
				if (spr_index[sprite] > sprite_index_trails_last)
				{
					spr_on[sprite] = false;
				}
				else
				{
					trail_timer[t] = player_trail_lifespan;
				}
			}
			trail_x[t] += trail_xs[t];
			
			set_sprite_position(sprite, trail_x[t] / x_divisor, trail_y[t] / y_divisor);
		}
	}
}