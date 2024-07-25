/*============================================================================
	UART to Midi Message Translation module

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

module midi_trans
(
    input         clk,
    input         reset,
    input         midi_send,
    input   [7:0] midi_data,
    output        note_on,
    output        note_off,
    output  [3:0] mchannel,
    output  [6:0] note,
    output  [6:0] velocity,
    output        cc_send,
    output  [6:0] cc,
    output  [6:0] cc_val,
    output        pb_send,
    output [13:0] pb_val
);

reg [1:0] midi_packet;
reg note_on_reg;
reg note_off_reg;
reg [3:0] channel_reg;
reg [6:0] note_reg;
reg [6:0] velocity_reg;
reg note_on_send_reg;
reg note_off_send_reg;
reg iscc;
reg [6:0] cc_reg;
reg [6:0] cc_val_reg;
reg cc_send_reg;
reg ispb;
reg [6:0] pb_lsb;
reg [6:0] pb_msb = 7'b1000000;
reg [13:0] pb_reg;
reg pb_send_reg;
reg init;
reg [25:0] timer = 'b1;

assign mchannel = channel_reg;
assign note = note_reg;
assign velocity = velocity_reg;
assign note_on = note_on_send_reg;
assign note_off = note_off_send_reg;
assign cc_send = cc_send_reg;
assign cc = cc_reg;
assign cc_val = cc_val_reg;
assign pb_val = pb_reg;
assign pb_send = pb_send_reg;

always @ (posedge clk) begin
    if (reset) begin
        midi_packet <= 0;
        note_on_reg <= 0;
        note_off_reg <= 0;
        channel_reg <= 0;
        note_reg <= 0;
        velocity_reg <= 0;
    end
    /*if (!init) begin
        timer <= timer + 'b1;
        if (!timer) begin
            ispb <= 1;
            channel_reg <= 'd14;
            pb_reg <= 'h2000;
            midi_packet <= 2'd3;
        end
    end
    if (pb_send_reg) init <= 1;*/
    if (!midi_packet) begin
        note_on_send_reg <= 0;
        note_off_send_reg <= 0;
        note_on_reg <= 0;
        note_off_reg <= 0;
        cc_send_reg <= 0;
        iscc <= 0;
        ispb <= 0;
        pb_send_reg <= 0;
    end
    if (midi_send) begin
        case (midi_packet)
            2'd0: begin
                if (midi_data[7:4] == 4'h9 || midi_data[7:4] == 4'h8) begin //midi note-on/off
                    if (midi_data[7:4] == 4'h9) note_on_reg <= 1;
                    if (midi_data[7:4] == 4'h8) note_off_reg <= 1;
                    channel_reg <= midi_data[3:0];
                    midi_packet <= midi_packet + 1'b1;
                end
                else if (midi_data[7:4] == 4'hB) begin //midi ccs
                    iscc <= 1;
                    channel_reg <= midi_data[3:0];
                    midi_packet <= midi_packet + 1'b1;
                end
                else if (midi_data[7:4] == 4'hE) begin //midi pitch bend
                    ispb <= 1;
                    channel_reg <= midi_data[3:0];
                    midi_packet <= midi_packet + 1'b1;
                end
            end
            2'd1: begin
                if (iscc) cc_reg <= midi_data[6:0];
                else if (ispb) pb_lsb <= midi_data[6:0];
                else note_reg <= midi_data[6:0];
                midi_packet <= midi_packet + 1'b1;
            end
            2'd2: begin
                if (iscc) cc_val_reg <= midi_data[6:0];
                else if (ispb) pb_reg <= (midi_data[6:0]<<7)+pb_lsb; //pb_msb <= midi_data[6:0];
                else if (midi_data[6:0] == 0) begin
                    note_off_reg <= 1;
                    note_on_reg <= 0;
                end
                else velocity_reg <= midi_data[6:0];
                midi_packet <= midi_packet + 1'b1;
            end
        endcase
    end
    if (midi_packet >= 2'd3) begin
        midi_packet <= 0;
        note_on_send_reg <= note_on_reg;
        note_off_send_reg <= note_off_reg;
        cc_send_reg <= iscc;
        //pb_reg <= (pb_msb<<7)+pb_lsb;
        pb_send_reg <= ispb;
    end
end

endmodule