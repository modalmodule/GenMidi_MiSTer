/*============================================================================
	Aznable OS - Zorblaxx demo application - Player routines

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
#include "../shared/sound.h"
#include "sprite_images.h"
#include "sound_samples.h"
#include "zorblaxx_app.h"
#include "zorblaxx_player.h"
#include "zorblaxx_trails.h"
#include "zorblaxx_asteroids.h"
#include "zorblaxx_explosions.h"

// Player
const signed char player_max_speed = 20;
const unsigned char player_accel = 3;
const unsigned char player_trail_frequency = 10;
const unsigned char player_trail_speed = 3;
const unsigned char player_trail_lifespan = 5;
unsigned short player_x;
unsigned short player_y;
signed char player_xs = 0;
signed char player_ys = 0;
unsigned short player_x_min;
unsigned short player_x_max;
unsigned short player_y_min;
unsigned short player_y_max;
const unsigned char player_speed_min = 12;
const unsigned char player_speed_max = 32;
const unsigned char player_speed_warp = 64;
unsigned char player_speed;
signed char player_trail_timer = 1;

unsigned char player_lives;
unsigned char player_lives_changed;
unsigned char player_invincible_timer = 0;
unsigned char player_invincible_flash = 0;
const unsigned char player_invincible_timeout = 120;
unsigned char player_respawn_timer = 0;
const unsigned char player_respawn_timeout = 120;
unsigned char player_hit = 0;

unsigned char player_ready;
unsigned char player_ready_x;
unsigned char player_ready_y;
unsigned short player_x_target;
unsigned short player_y_target;
signed short player_x_diff;
signed short player_y_diff;
unsigned char player_target_divider = 6;
unsigned char player_target_maxspeed = 28;

void set_player_target(unsigned short x, unsigned short y, unsigned char divider, unsigned char maxspeed)
{
	player_ready = 0;
	player_ready_x = 0;
	player_ready_y = 0;
	player_x_target = x;
	player_y_target = y;
	player_target_divider = divider;
	player_target_maxspeed = maxspeed;
}

void move_player_to_target()
{
	if (player_y != player_y_target)
	{
		player_y_diff = (((signed short)player_y_target - (signed short)player_y)) / (signed char)player_target_divider;
		if (player_y_diff == 0)
		{
			player_y = player_y_target;
		}
		else
		{
			if (player_y_diff > player_target_maxspeed)
			{
				player_y_diff = player_target_maxspeed;
			}
			else
			{
				if (player_y_diff < -player_target_maxspeed)
				{
					player_y_diff = -player_target_maxspeed;
				}
			}
			player_y += player_y_diff;
		}
		unsigned short y = player_y / y_divisor;
		spr_y_h[player_sprite] = y >> 8;
		spr_y_l[player_sprite] = (unsigned char)y;
	}
	else
	{
		player_ready_y = 1;
	}
	if (player_x != player_x_target)
	{
		player_x_diff = (((signed short)player_x_target - (signed short)player_x)) / (signed short)player_target_divider;
		if (player_x_diff == 0)
		{
			player_x = player_x_target;
		}
		else
		{
			if (player_x_diff > player_target_maxspeed)
			{
				player_x_diff = player_target_maxspeed;
			}
			else
			{
				if (player_x_diff < -player_target_maxspeed)
				{
					player_x_diff = -player_target_maxspeed;
				}
			}
			player_x += player_x_diff;
		}
		set_sprite_position_x(player_sprite, player_x / x_divisor);
	}
	else
	{
		player_ready_x = 1;
	}
	player_ready = player_ready_x && player_ready_y;
}

// Player
void setup_player(unsigned short x, unsigned short y, unsigned char lives)
{
	// Player bounds
	player_x_min = 32 * x_divisor;
	player_x_max = 336 * x_divisor;
	player_y_min = 32 * y_divisor;
	player_y_max = 244 * y_divisor;

	// Player initial position
	player_x = x * x_divisor;
	player_y = y * y_divisor;
	player_speed = player_speed_min;
	player_xs = 0;
	player_ys = 0;

	player_hit = false;
	player_lives = lives;
	player_lives_changed = true;
	player_respawn_timer = 0;
	player_invincible_timer = 0;
	player_invincible_flash = 0;

	// Initialise player sprite
	spr_index[player_sprite] = sprite_index_player_first;
	enable_sprite(player_sprite, sprite_palette_player, sprite_size_player, true);

	set_sprite_position(player_sprite, x, y);

	// Trails
	player_trail_timer = player_trail_frequency;
}

void player_destroyed()
{
	play_sound(const_sound_player_explode);
	add_explosion(0, 1);
	add_explosion(1, 2);
	spr_on[player_sprite] = false;
	player_lives_changed = true;
	if (player_lives > 0)
	{
		player_lives--;
		player_respawn_timer = player_respawn_timeout;
	}
}

void handle_player(bool allow_control)
{
	// If player is currently dead and a respawn is scheduled
	if (player_respawn_timer > 0)
	{
		player_hit = false;

		// Decelerate player speed to minimum
		if (player_speed > player_speed_min)
		{
			player_speed--;
		}
		// Decrement respawn timer
		player_respawn_timer--;
		// Respawn the player when timer reaches 0
		if (player_respawn_timer == 0)
		{
			// Set player to spawn position
			setup_player(player_spawn_x, player_spawn_y, player_lives);
			// Enable invincibility and set timer
			enable_sprite(player_sprite, sprite_palette_player, sprite_size_player, false);
			player_invincible_timer = player_invincible_timeout;
		}
		return;
	}

	// If player is currently invincible
	if (player_invincible_timer > 0)
	{
		// Ignore any collisions
		player_hit = false;
		// Decrement invincibility timer
		player_invincible_timer--;
		// Wait for invincibility timer to expire
		if (player_invincible_timer == 0)
		{
			// Re-enable collision when invincibility runs out
			enable_sprite(player_sprite, sprite_palette_player, sprite_size_player, true);
		}
		else
		{
			// Increment flash timer
			player_invincible_flash++;
			// Wait for invincibility flash timer to roll over
			if (player_invincible_flash == 4)
			{
				// Reset timer
				player_invincible_flash = 0;
				// Flip player sprite visibility
				spr_on[player_sprite] = !spr_on[player_sprite];
			}
		}
	}
	else
	{
		// If player is hit then destroy player
		if (player_hit)
		{
			player_hit = false;
			player_destroyed();
		}
	}

	// Gradually reduce player move speed to zero
	if (player_xs > 0)
	{
		player_xs--;
	}
	else if (player_xs < 0)
	{
		player_xs++;
	}
	if (player_ys > 0)
	{
		player_ys--;
	}
	else if (player_ys < 0)
	{
		player_ys++;
	}

	// Is player control activated?
	if (allow_control)
	{
		// Use player directional inputs to increase/decrease velocity, enforcing max speed limits
		if (CHECK_BIT(joystick[0], 0) && player_xs < player_max_speed)
		{
			player_xs += player_accel;
		}
		if (CHECK_BIT(joystick[0], 1) && player_xs > -player_max_speed)
		{
			player_xs -= player_accel;
		}
		if (CHECK_BIT(joystick[0], 2) && player_ys < player_max_speed)
		{
			player_ys += player_accel;
		}
		if (CHECK_BIT(joystick[0], 3) && player_ys > -player_max_speed)
		{
			player_ys -= player_accel;
		}

		// Use player boost input to increase/decrease player flight speed, enforcing max speed limits
		if (CHECK_BIT(joystick[0], 4))
		{
			if (player_speed < player_speed_max)
			{
				player_speed++;
			}
		}
		else
		{
			if (player_speed > player_speed_min)
			{
				player_speed--;
			}
		}
	}

	// Set player sprite image
	spr_index[player_sprite] = (player_xs < -2 ? sprite_index_player_first + 2 : player_xs > 2 ? sprite_index_player_first + 3
																							   : sprite_index_player_first);

	// Integrate player move velocity
	player_x += player_xs;
	player_y += player_ys;

	// Enforce player position limits when player is in control (disabled when not to allow ship to animate off screen)
	if (allow_control)
	{
		// Enforce X minimum (left)
		if (player_x < player_x_min)
		{
			player_x = player_x_min;
			if (player_xs < 0)
			{
				player_xs = 0;
			}
		}
		// Enforce X maximum (right)
		else if (player_x > player_x_max)
		{
			player_x = player_x_max;
			if (player_xs > 0)
			{
				player_xs = 0;
			}
		}

		// Enforce Y minimum (top)
		if (player_y < player_y_min)
		{
			player_y = player_y_min;
			if (player_ys < 0)
			{
				player_ys = 0;
			}
		}
		// Enforce Y maximum (bottom)
		else if (player_y > player_y_max)
		{
			player_y = player_y_max;
			if (player_ys > 0)
			{
				player_ys = 0;
			}
		}
	}

	// Set sprite position with low res coordinates
	set_sprite_position(player_sprite, player_x / x_divisor, player_y / y_divisor);

	// Decrease player trail timer
	player_trail_timer--;
	// Spawn player trail when timer expires
	if (player_trail_timer <= 0)
	{
		// Generate next particle timer (emission rate)
		unsigned char reduce = (player_speed / 8) + rand_uchar(0, 6);
		player_trail_timer = player_trail_frequency - reduce;
		if (player_trail_timer <= 0)
		{
			player_trail_timer = 0;
		}
		// Spawn a player trail entity
		add_player_trail();
	}
}