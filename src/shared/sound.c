/*============================================================================
	Aznable OS - Sound engine (M5205 sample player)

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-12-20

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
#include "sound.h"

#define const_sound_sample_max 32
unsigned char sound_sample_max = const_sound_sample_max;	
#include myPATH(../PROJECT_NAME/,sound_samples.h) // Include auto generated track array

void play_sound(unsigned char sample)
{
	// Write sample start address (2 bytes)
	sndram[1] = sound_sample_address[sample] >> 8;
	sndram[0] = sound_sample_address[sample];
	// Write sample length (2 bytes)
	unsigned short end = sound_sample_address[sample] + sound_sample_length[sample];
	sndram[5] = end >> 8;
	sndram[4] = end;
	// Write play instruction
	sndram[8] = 1;
}

void set_sound_volume(unsigned char volume)
{
	// Write sample volume
	sndram[12] = volume;
}