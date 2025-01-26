`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// FromLocal.v
//
// Communicates between the core and the routing network.
// BUFFER_DEPTH must be a power of 2.
//////////////////////////////////////////////////////////////////////////////////


module FromLocal #(
    parameter PACKET_WIDTH = 30,
    parameter BUFFER_DEPTH = 4,
    parameter DX_MSB = 29,
    parameter DX_LSB = 21
)(
    input clk,
    input rst,

    input [PACKET_WIDTH-1:0] din,
    input din_wen,
    
    input wait_east,
    input wait_west,
    
    output [PACKET_WIDTH-1:0] dout_east,
    output [PACKET_WIDTH-1:0] dout_west,
    
    output men_east,
    output men_west,
    
    output local_buffer_full
);
    wire full_local;
    wire wait_local;
    assign wait_local = wait_east | wait_west;
    wire ren;
    wire buffer_empty;
    wire [PACKET_WIDTH-1:0] dout;
    
    buffer #(
        .DATA_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) buffer_east (
        .clk(clk),
        .rst(rst),
        .wait_in(wait_local),
        .din(din),
        .din_valid(din_wen),
        .dout(dout),
        .empty(buffer_empty),
        .valid(valid),
        .full(local_buffer_full)
    );
    
    wire valid;
    wire signed [DX_MSB:DX_LSB] dx;
    assign dx = dout[DX_MSB:DX_LSB];
    
    assign dout_east = dout;
    //assign men_east = dx < 0 ? 0 : 1; // if dx == 0 going east
    assign men_east = (!valid) ? 0 : ((dx > 0)||(dx == 0) ? 1 : 0);

    assign dout_west = dout;
    //assign men_west = dx < 0 ? 1 : 0;
    assign men_west = (!valid) ? 0 : ((dx > 0)||(dx == 0) ? 0 : 1);
    
endmodule
