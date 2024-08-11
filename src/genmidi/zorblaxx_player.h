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

#pragma once

// Player
extern const signed char player_max_speed;
extern const unsigned char player_accel;
extern const unsigned char player_trail_frequency;
extern const unsigned char player_trail_speed;
extern const unsigned char player_trail_lifespan;
extern unsigned short player_x;
extern unsigned short player_y;
extern signed char player_xs;
extern signed char player_ys;
extern unsigned short player_x_min;
extern unsigned short player_x_max;
extern unsigned short player_y_min;
extern unsigned short player_y_max;
extern const unsigned char player_speed_min;
extern const unsigned char player_speed_max;
extern const unsigned char player_speed_warp;
extern unsigned char player_speed;
extern signed char player_trail_timer;

extern unsigned char player_lives;
extern unsigned char player_lives_changed;
extern const unsigned char player_invincible_timeout;
extern const unsigned char player_respawn_timeout;
extern unsigned char player_hit;

extern unsigned char player_ready;
extern unsigned char player_ready_x;
extern unsigned char player_ready_y;

extern unsigned short player_x_target;
extern unsigned short player_y_target;
extern signed short player_x_diff;
extern signed short player_y_diff;

extern void set_player_target(unsigned short x, unsigned short y, unsigned char divider, unsigned char maxspeed);
extern void move_player_to_target();

extern void setup_player(unsigned short x, unsigned short y, unsigned char lives);
extern void handle_player(bool allow_control);