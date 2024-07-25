/*============================================================================
	Game Boy Midi Core - Echo Generator module

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

module echo_gen
(
    input        en,
    input        clk,
    input        note_on,
    input        note_repeat,
    input  [6:0] note_start,
    input  [6:0] vel_start,
    input  [8:0] pb_start,
    output       echo_on,
    output [6:0] echo_note,
    output [6:0] echo_vel,
    output [8:0] echo_pb
);
localparam int speed = 23;
reg note_repeat_reg;
reg[6:0] note_reg[0:15];
reg[6:0] note_temp;
//reg echo_send_reg;
reg echo_on_reg[0:15];
reg echo_on_temp;
//reg[6:0] echo_note_reg;
reg[6:0] echo_vel_reg[0:15];
reg[6:0] echo_vel_temp;
reg[8:0] echo_pb_reg[0:15];
reg[8:0] echo_pb_temp;
reg[6:0] note_send_reg;
reg echo_on_send_reg;
reg[6:0] echo_vel_send_reg;
reg[8:0] echo_pb_send_reg;
reg[speed-1:0] echo_timer = 'b1; //24
reg started;
reg echo_start;
reg[3:0] i;
reg[speed:0] t[0:15];
reg init;

//assign echo_send = echo_send_reg;
assign echo_on = echo_on_send_reg;
assign echo_note = note_send_reg;
assign echo_vel = echo_vel_send_reg;
assign echo_pb = echo_pb_send_reg;

always @ (posedge clk) begin
    if (en) begin
        if (!init) begin
            for (int ii = 0; ii < 16; ii = ii + 1) begin
                t[ii] <= 'b1<<speed;
            end
        end
        if (t[15] == 'b1<<speed) init <= 1;
        echo_timer <= echo_timer + 'b1;
        if (echo_timer == 0) echo_timer <= 'b1;
        if (echo_on_temp != note_on || note_temp != note_start || echo_vel_temp != vel_start || echo_pb_temp != pb_start) begin
            t[i] <= echo_timer;
            echo_on_reg[i] <= note_on;
            note_reg[i] <= note_start;
            //if (vel_start < 'd3) echo_vel_reg[i] <= 'b1;
            //else 
            echo_vel_reg[i] <= vel_start>>1;
            echo_pb_reg[i] <= pb_start;
            echo_on_temp <= note_on;
            note_temp <= note_start;
            echo_vel_temp <= vel_start;
            echo_pb_temp <= pb_start;
            i <= i + 'b1;
        end
        for (int ii = 0; ii < 16; ii = ii + 1) begin
            if (t[ii] == echo_timer) begin
                echo_on_send_reg <= echo_on_reg[ii];
                note_send_reg <= note_reg[ii];
                echo_vel_send_reg <= echo_vel_reg[ii];
                echo_pb_send_reg <= echo_pb_reg[ii];
                echo_on_reg[ii] <= 0;
                note_reg[ii] <= 0;
                echo_vel_reg[ii] <= 0;
                echo_pb_reg[ii] <= 0;
                t[ii] <= 'b1<<speed;
            end
        end
        /*if ((note_reg != note_start || note_repeat_reg) && !started) begin
            started <= 1;
            note_repeat_reg <= 0;
            note_reg <= note_start;
            echo_start <= 0;
            echo_timer <= 'b1;
            echo_send_reg <= 0;
            echo_on_reg <= note_on;
            //echo_note_reg <= note_start;
            echo_vel_reg <= vel_start - 'b1;
        end
        if (started) begin
            if (!echo_start) echo_timer <= echo_timer + 'b1;
            else echo_timer <= 0;
            if (!echo_timer) begin
                echo_start <= 1;
                echo_send_reg <= 1;
            end
            if (echo_send_reg) echo_send_reg <= 0;
            if (echo_start && (note_reg != note_start || note_repeat || echo_on_reg != note_on)) begin
                started <= 0;
                note_repeat_reg <= note_repeat;
            end
        end*/
        /*if (!note_on) begin
            started <= 0;
            if (note_reg == note_start) note_repeat_reg <= note_repeat;
            note_reg <= 0;
        end*/
    end
end

endmodule