module mixer
(
    input clk,
    input ce_2x,
    input  [15:0] aa_l_in,
    input  [15:0] aa_r_in,
    input  [15:0] ac_l_in,
    input  [15:0] ac_r_in,
    output [15:0] ac_l_out,
    output [15:0] ac_r_out
);

//reg[15:0] ac_l_out_reg;
//reg[15:0] ac_r_out_reg;
assign ac_l_out = ac_l_in + aa_l_in;
assign ac_r_out = ac_r_in + aa_r_in;

/*always @ (posedge clk) begin
    if (ce_2x) begin
        ac_l_out_reg <= ac_l_in + aa_l_in;
        ac_r_out_reg <= ac_r_in + aa_r_in;
    end
end*/

endmodule