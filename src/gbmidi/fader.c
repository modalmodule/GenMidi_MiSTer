/*============================================================================
	Input Test - Fader

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-07-12

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
#include "fader.h"
#include "inputtester_sys.h"

// Fade in/out variables
unsigned char fade = 0;
unsigned char fadetimer = 0;

// Initialise fadeout state
void start_fadeout()
{
    state = STATE_FADEOUT;
    fadetimer = fadefreq;
    fade = 0;
}

// Initialise fadein state
void start_fadein()
{
    state = STATE_FADEIN;
    fadetimer = fadefreq;
    fade = 15;
}

// Fade out state
void fadeout()
{
    if (VBLANK_RISING)
    {
        fadetimer--;
        if (fadetimer == 0)
        {
            box(fade, fade, 39 - fade, 29 - fade, 127, 0b0000111);
            fadetimer = fadefreq;
            fade++;
            if (fade == 16)
            {
                start_fadein();
            }
        }
    }
}

// Fade in state
void fadein()
{
    if (VBLANK_RISING)
    {
        fadetimer--;
        if (fadetimer == 0)
        {
            box(fade, fade, 39 - fade, 29 - fade, 0, 0b0000000);
            fadetimer = fadefreq;
            fade--;
            if (fade == 0)
            {
                state = nextstate;
            }
        }
    }
}
