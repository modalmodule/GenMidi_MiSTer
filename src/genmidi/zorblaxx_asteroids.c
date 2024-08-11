
/*============================================================================
	Aznable OS - Zorblaxx demo application - Asteroid routines

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
#include "zorblaxx_asteroids.h"

#define const_asteroids_max 16
unsigned char asteroids_max = const_asteroids_max;
unsigned short asteroids_x[const_asteroids_max];
unsigned short asteroids_y[const_asteroids_max];
signed char asteroids_xs[const_asteroids_max];
signed char asteroids_ys[const_asteroids_max];
unsigned char asteroids_timer[const_asteroids_max];
unsigned short asteroids_y_max;
unsigned char asteroid_spawn_y = 0;
unsigned char asteroids_active;
unsigned char asteroids_active_max;
unsigned char asteroids_difficulty;
unsigned char asteroids_difficulty_speedspread;
unsigned short asteroids_evaded = 0;

unsigned char get_asteroid_timer()
{
	unsigned char min_wait = asteroids_difficulty < 30 ? 30 - asteroids_difficulty : 0;
	unsigned char max_wait = asteroids_difficulty < 120 ? 120 - asteroids_difficulty : 0;
	unsigned char random = rand_uchar(min_wait, max_wait);
	return random;
}

void setup_asteroids()
{
	asteroids_y_max = 272 * y_divisor;

	for (unsigned char m = 0; m < asteroids_max; m++)
	{
		asteroids_x[m] = rand_ushort(32, 320) * x_divisor;
		asteroids_y[m] = asteroid_spawn_y;
		asteroids_xs[m] = rand_schar(-asteroids_difficulty_speedspread, asteroids_difficulty_speedspread);
		asteroids_ys[m] = rand_uchar(4, 16 + asteroids_difficulty);
		asteroids_timer[m] = get_asteroid_timer();

		unsigned char sprite = asteroids_sprite_first + m;
		spr_index[sprite] = sprite_index_asteroids_first + rand_uchar(0, sprite_index_asteroids_count - 1);
		enable_sprite(sprite, sprite_palette_asteroids, sprite_size_asteroids, true);
		spr_on[sprite] = false;
		set_sprite_position(sprite, asteroids_x[m] / x_divisor, 0);
	}
}

void handle_asteroids(unsigned char spawn_enabled)
{
	asteroids_active = 0;
	for (unsigned char m = 0; m < asteroids_max; m++)
	{
		unsigned char sprite = asteroids_sprite_first + m;
		if (m < asteroids_active_max)
		{
			if (asteroids_timer[m] > 0)
			{
				if (spawn_enabled == 1)
				{
					asteroids_timer[m]--;
					if (asteroids_timer[m] == 0)
					{
						spr_index[sprite] = rand_uchar(sprite_index_asteroids_first, sprite_index_asteroids_last);
						spr_on[sprite] = 1;
					}
				}
			}
			else
			{
				asteroids_active++;
				asteroids_x[m] += asteroids_xs[m];
				if (asteroids_x[m] < x_h_min)
				{
					asteroids_x[m] = x_h_max;
				}
				else if (asteroids_x[m] > x_h_max)
				{
					asteroids_x[m] = x_h_min;
				}
				if (asteroids_y[m] >= asteroids_y_max)
				{
					spr_on[sprite] = 0;
					asteroids_x[m] = rand_ushort(32, 320) * x_divisor;
					asteroids_y[m] = asteroid_spawn_y * y_divisor;
					set_sprite_position(sprite, asteroids_x[m] / x_divisor, asteroid_spawn_y);
					asteroids_xs[m] = rand_schar(-asteroids_difficulty_speedspread, asteroids_difficulty_speedspread);
					asteroids_ys[m] = rand_uchar(4, 16 + asteroids_difficulty);
					asteroids_timer[m] = get_asteroid_timer();
					asteroids_evaded++;
				}
				else
				{
					asteroids_y[m] += asteroids_ys[m] + scroll_speed;
					set_sprite_position(sprite, asteroids_x[m] / x_divisor, asteroids_y[m] / y_divisor);
				}
			}
		}
	}
}