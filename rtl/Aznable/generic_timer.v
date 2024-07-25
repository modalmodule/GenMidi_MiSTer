`timescale 1ps / 1ps
/*============================================================================
	Aznable (custom 8-bit computer system) - Generic timer

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-10-20

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

module generic_timer #(
	parameter COUNTER_WIDTH = 16,
	parameter DIVIDER_WIDTH = 15,
	parameter INTERVAL = 15'd24000
)(
	input   clk,
	input   reset,
    output reg [COUNTER_WIDTH-1:0]   counter
);

reg  [DIVIDER_WIDTH-1:0] divider = {DIVIDER_WIDTH{1'b0}};

always @(posedge clk or posedge reset) 
begin
	if(reset)
	begin
		counter <= {COUNTER_WIDTH{1'b0}};
		divider <= {DIVIDER_WIDTH{1'b0}};
	end
	else
	begin
		if(divider==INTERVAL)
		begin
			counter <= counter + 1'b1;
			divider <= {DIVIDER_WIDTH{1'b0}};
		end
		else
		begin
			divider <= divider + 1'b1;
	 	end
	end
end

endmodule