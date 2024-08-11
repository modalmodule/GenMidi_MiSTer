/*============================================================================
	Input Test - Snek mini-game

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
#include "../shared/sprite.h"
#include "snek_app.h"
#include "inputtester_sys.h"
#include "fader.h"

// SNEK variables
unsigned char movefreqdectimer = 0;
unsigned char movefreq = 0;
unsigned char movetimer = 0;
signed int x = 20;
signed int y = 15;
signed char xd = 0;
signed char yd = 1;
signed char nxd = 0;
signed char nyd = 1;
unsigned int length = 0;

// Attract mode variables
unsigned char attractstate = 0;

// Initialise attract state and draw static elements
void start_snek_attract()
{
    state = STATE_ATTRACT;
    attractstate = 0;
    clear_chars(0);
    page_border(0b00000111);
    write_string("SNEK", 0b00000111, 18, 0);
    movefreq = 5;
    movetimer = 1;
}

// Initialise attract state and draw static elements
void start_snek_gameplay()
{
    state = STATE_GAME_SNEK;
    length = 0;
    x = 20;
    y = 15;
    xd = 0;
    yd = 1;
    nxd = 0;
    nyd = 1;
    clear_chars(0);
    page_border(0b00000111);
    write_string("SNEK", 0b00000111, 18, 0);
    write_char(playerchar, 0xFF, x, y);

    movefreq = movefreqinit;
    movefreqdectimer = movefreqdecfreq;
    movetimer = movefreq;
}

// SNEK - gameplay state
void snek_gameplay()
{

    if (HBLANK_RISING)
    {
        if (yd != 1 && joystick[0] & 0b00001000) // up
        {
            nyd = -1;
            nxd = 0;
        }
        if (yd != -1 && joystick[0] & 0b00000100) // down
        {
            nyd = 1;
            nxd = 0;
        }
        if (xd != 1 && joystick[0] & 0b00000010) // left
        {
            nxd = -1;
            nyd = 0;
        }
        if (xd != -1 && joystick[0] & 0b00000001) //right
        {
            nxd = 1;
            nyd = 0;
        }

        if (CHECK_BIT(joystick[1], 2)) // select to quit
        {
            state = 0;
            return;
        }
    }

    if (VBLANK_RISING)
    {
        movetimer--;
        if (movetimer == 0)
        {
            write_char(127, 0x66, x, y);
            xd = nxd;
            yd = nyd;
            x += xd;
            y += yd;
            unsigned int p = (y * chram_cols) + x;
            if (chram[p] > 0)
            {
                nextstate = STATE_START_ATTRACT;
                start_fadeout();
                return;
            }
            length++;
            write_char(playerchar, 0xFF, x, y);
            movetimer = movefreq;
            char score[5];
            sprintf(score, "%4d", length);
            write_string(score, 0xFF, 35, 0);
        }

        movefreqdectimer--;
        if (movefreqdectimer == 0)
        {
            movefreqdectimer = movefreqdecfreq;
            if (movefreq > 3)
            {
                movefreq--;
            }
            char str_movefreq[3];
            sprintf(str_movefreq, "%4d", movefreq);
            write_string(str_movefreq, 0xFF, 35, 29);
        }
    }
}

// SNEK - attract state
void snek_attract()
{

    if (HBLANK_RISING)
    {
        if (CHECK_BIT(joystick[1], 3)) // start to start
        {
            start_snek_gameplay();
            return;
        }
        if (CHECK_BIT(joystick[1], 2)) // select to quit
        {
            state = 0;
            return;
        }
    }

    if (VBLANK_RISING)
    {
        movetimer--;
        if (movetimer == 0)
        {
            attractstate = !attractstate;
            write_string("PRESS START", attractstate == 0 ? 0x00 : 0xFF, 14, 15);
            movetimer = movefreq;
        }
    }
}
