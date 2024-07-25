/*============================================================================
	Game Boy Midi Core - Duty switch module

	Aruthor: ModalModule - https://github.com/modalmodule/
	Version: 0.1
	Date: 2024-02-19

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

module duty_switch
(
    input        en,
    input        clk,
    input        note_on,
    input        note_repeat,
    input  [6:0] note_start,
    output [1:0] duty_out
);

reg note_repeat_reg;
reg[6:0] note_reg;
reg[1:0] duty_out_reg = 'd12;
reg[19:0] duty_timer = 'b1; //24
reg started;
reg switch_start;

assign duty_out = duty_out_reg;

always @ (posedge clk) begin
    if (en) begin
        if ((note_reg != note_start || note_repeat_reg) && note_on && !started) begin
            duty_out_reg <= 2;
            started <= 1;
            note_repeat_reg <= 0;
            note_reg <= note_start;
            switch_start <= 0;
            duty_timer <= 'b1;
        end
        if (started) begin
            if (!switch_start) duty_timer <= duty_timer + 'b1;
            else duty_timer <= 0;
            if (!duty_timer) begin
                switch_start <= 1;
                duty_out_reg <= 1;
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