/*============================================================================
	Aznable OS - System interface functions

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.2
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

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>

#include "sys.h"

// Character map
const unsigned char chram_cols = 64;
const unsigned char chram_rows = 32;
unsigned short chram_size;

// Hardware inputs
bool hsync;
bool hsync_last;
bool vsync;
bool vsync_last;
bool hblank;
bool hblank_last;
bool vblank;
bool vblank_last;

// Helper functions
unsigned char rand_uchar(unsigned char lower, unsigned char upper)
{
	return (rand() % (upper - lower + 1)) + lower;
}

unsigned short rand_ushort(unsigned short lower, unsigned short upper)
{
	return (rand() % (upper - lower + 1)) + lower;
}

signed char rand_schar(signed char lower, signed char upper)
{
	return (rand() % (upper - lower + 1)) + lower;
}
