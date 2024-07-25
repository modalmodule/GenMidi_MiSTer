/*============================================================================
	Aznable OS - Music engine (YM player)

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
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
#include "../shared/music.h"

#define const_music_track_max 32
unsigned char music_track_max = const_music_track_max;

unsigned char music_last_played = 255;

#include myPATH(../PROJECT_NAME/,music_tracks.h) // Include auto generated track array

void play_music(unsigned char track, unsigned char loop)
{
	// Write track start address (3 bytes)
	musicram[1] = (unsigned char)(music_track_address[track] >> 16);
	musicram[2] = music_track_address[track] >> 8;
	musicram[3] = music_track_address[track];
	// Write start track instruction (2 for looping, 1 for single play)
	musicram[0] = loop ? 2 : 1;
	music_last_played = track;
}

void play_music_if(unsigned char track, unsigned char loop)
{
	if (musicram[0] == 0 || music_last_played != track)
	{
		play_music(track, loop);
	}
}

void stop_music()
{
	// Send stop command
	musicram[0] = 3;
	// Reset last played track
	music_last_played = 255;
}