/*============================================================================
	Game Boy Midi Core - poly_disp module

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

module poly_disp
(
    input          clk,
    input          sq1_no_in,
    input          sq2_no_in,
    input    [6:0] sq1_n_in,
    input    [6:0] sq2_n_in,
    input    [7:0] ii_in,
    input  [255:0] pd_in,
    output [255:0] pd_out
);

reg [255:0] pd_delay;

always @(posedge clk) begin
	pd_delay <= pd_in + (sq2_no_in<<((16*(ii_in+ii_in+1))+9)) + ((sq2_n_in-36)<<(16*(ii_in+ii_in+1))) + (sq1_no_in<<((16*(ii_in+ii_in))+9)) + ((sq1_n_in-36)<<(16*(ii_in+ii_in)));
end

assign pd_out = pd_delay;

// assign pd_out = pd_in + (sq2_no_in<<((16*(ii_in+ii_in+1))+9)) + ((sq2_n_in-36)<<(16*(ii_in+ii_in+1))) + (sq1_no_in<<((16*(ii_in+ii_in))+9)) + ((sq1_n_in-36)<<(16*(ii_in+ii_in)));

//assign ac_r_out = ac_r_in + aa_r_in;
endmodule