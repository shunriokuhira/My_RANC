`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PathDecoder3Way.v
//
// The combinational logic or the forward east / forward west modules.
//
// For forward east:
//  - ADD should be set to -1
//  - dout_a goes to east out
//  - dout_b goes to forward north
//  - dout_c goes to forward south
//
// For forward west:
//  - ADD should be set to 1
//  - dout_a goes to west out
//  - dout_b goes to forward north
//  - dout_c goes to forward south
//////////////////////////////////////////////////////////////////////////////////


module PathDecoder3Way#(
    parameter DATA_WIDTH = 32,
    parameter DX_MSB = 29,
    parameter DX_LSB = 21,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter ADD = 1//eastなら-1
)(
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] dout_routing,
    output men_routing,
    output [DATA_WIDTH-1-(DX_MSB-DY_MSB):0] dout_north,
    output men_north,
    output [DATA_WIDTH-1-(DX_MSB-DY_MSB):0] dout_south,
    output men_south
);
    wire din_zero;
    assign din_zero = (din == 30'b0) ? 1 : 0;//バッファの初期値

    wire [DX_MSB:DX_LSB] dx;
    wire signed [DY_MSB:DY_LSB] dy;
    assign dx = din[DX_MSB:DX_LSB];
    assign dy = din[DY_MSB:DY_LSB];
    
    wire [DX_MSB:DX_LSB] dx_plus_add;
    assign dx_plus_add = dx + ADD;
    
    assign dout_routing = {dx_plus_add, din[DX_LSB-1:0]};
    assign men_routing = din_zero ? 0 : (dx == 0 ? 0 : 1);
    
    //din_zero考慮しないとゼロパケットに反応してさいしょからmen_northが1のままになる
    assign dout_north = din[DX_LSB-1:0];
    //assign men_north = dy >= 0 ? (dx == 0 ? 1 : 0) : 0;
    assign men_north = din_zero ? 0 : (dy >= 0 ? (dx == 0 ? 1 : 0) : 0);

    assign dout_south = din[DX_LSB-1:0];
    assign men_south = din_zero ? 0 : (dy < 0 ? (dx == 0 ? 1 : 0) : 0);

endmodule
