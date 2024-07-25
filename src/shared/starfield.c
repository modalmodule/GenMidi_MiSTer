/*============================================================================
	Aznable OS - Moroboshi (starfield)

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
#include "sys.h"

void enable_starfield()
{
	starfield1[0] = 1;
	starfield2[0] = 1;
	starfield3[0] = 1;
}
void disable_starfield()
{
	starfield1[0] = 0;
	starfield2[0] = 0;
	starfield3[0] = 0;
}

void set_starfield_speed_x(signed short speed)
{
	unsigned char dir = (speed < 0) << 7;
	unsigned short mag = (unsigned short)abs(speed);
	starfield3[1] = dir | mag >> 8;
	starfield3[2] = (unsigned char)mag;
	mag = mag << 1;
	starfield2[1] = dir | mag >> 8;
	starfield2[2] = (unsigned char)mag;
	mag = mag << 1;
	starfield1[1] = dir | mag >> 8;
	starfield1[2] = (unsigned char)mag;
}

void set_starfield_speed_y(signed short speed)
{
	unsigned char dir = (speed < 0) << 7;
	unsigned short mag = (unsigned short)abs(speed);
	starfield3[3] = dir | mag >> 8;
	starfield3[4] = (unsigned char)mag;
	mag = mag << 1;
	starfield2[3] = dir | mag >> 8;
	starfield2[4] = (unsigned char)mag;
	mag = mag << 1;
	starfield1[3] = dir | mag >> 8;
	starfield1[4] = (unsigned char)mag;
}