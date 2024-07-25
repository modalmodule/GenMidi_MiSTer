/*============================================================================
	Game Boy Midi Core - Pitch Fall module

	Aruthor: ModalModule - https://github.com/modalmodule/
	Version: 0.1
	Date: 2024-02-25

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

module pitchfallW
(
    input        clk,
    input        en,
    input  [3:0] speed,
    input        note_on,
    input        note_repeat,
    input  [6:0] note_start,
    //input  [6:0] pitch_start,
    output [12:0] fall_amount
);

reg [25:0] timer = 'b1;
reg started;
reg note_repeat_reg;
reg [6:0] note_reg;
reg [12:0] fall_amount_reg;
assign fall_amount = fall_amount_reg;

always @ (posedge clk) begin
    if (en) begin
        if ((note_reg != note_start || note_repeat_reg) && note_on && !started) begin
            started <= 1;
            //adjusted_vel_reg <= vel_start;
            fall_amount_reg <= 0;
            timer <= 'b1;
            note_reg <= note_start;
            note_repeat_reg <= 0;
        end
        if (started) begin
            if (fall_amount_reg < 'd7680) begin //'d3072
                timer <= timer + (26'b1<<speed);
                if (timer > 26'd8191) begin
                    fall_amount_reg <= fall_amount_reg + 'b1;
                    timer <= 'b1;
                end
            end
            if (note_reg != note_start || note_repeat) begin
                started <= 0;
                note_repeat_reg <= note_repeat;
            end
        end
        if (!note_on) begin
            started <= 0;
            if (note_reg == note_start) note_repeat_reg <= note_repeat;
            note_reg <= 0;
        end
    end
end
endmodule