/*============================================================================
	Game Boy Midi Core - Vibrato generator module

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

module vibrato_gen
(
    input        en,
    input        clk,
    input        note_on,
    input        note_repeat,
    input  [6:0] note_start,
    output [8:0] vib_out,
    output vib_start
);

reg note_repeat_reg;
reg [6:0] note_reg;
reg [8:0] vib_out_reg = 'd12;
reg [23:0] delay_timer = 'b1; //24
reg started;
reg vib_start_reg;
reg [17:0] step_timer; //18
reg [4:0] max = 'd24;
reg flip;

assign vib_out = vib_out_reg;
assign vib_start = vib_start_reg;

always @ (posedge clk) begin
    if (en) begin
        if ((note_reg != note_start || note_repeat_reg) && note_on && !started) begin
            started <= 1;
            note_repeat_reg <= 0;
            note_reg <= note_start;
            vib_start_reg <= 0;
            delay_timer <= 'b1;
            step_timer <= 0;
            flip <= 0;
            vib_out_reg <= 'd12;
        end
        if (started) begin
            if (!vib_start_reg) delay_timer <= delay_timer + 'b1;
            else delay_timer <= 0;
            if (!delay_timer) begin
                vib_start_reg <= 1;
                step_timer <= step_timer + 'b1;
                if (!step_timer) begin
                    case(flip)
                        'd0: begin
                            if (vib_out_reg < max) vib_out_reg <= vib_out_reg + 'b1;
                            else flip <= 'd1;
                        end
                        'd1: begin
                            if (vib_out_reg > 0) vib_out_reg <= vib_out_reg - 'b1;
                            else flip <= 'd0;
                        end
                    endcase
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
    else vib_out_reg <= 'd12;
end

endmodule