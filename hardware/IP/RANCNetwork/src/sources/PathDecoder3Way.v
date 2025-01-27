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
    parameter ADD = 1//forward eastなら-1、forward westなら1
)(
    input [DATA_WIDTH-1:0] din,//merge moduleからのパケット
    input wen,//from merge module
    output [DATA_WIDTH-1:0] dout_a,//to rooting_buffer
    output wen_a,//to rooting_buffer
    output [DATA_WIDTH-1-(DX_MSB-DY_MSB):0] dout_b,//to north_buffer  dx座標は切り取る >> ビット幅[20:0]
    output wen_b,//to north_buffer
    output [DATA_WIDTH-1-(DX_MSB-DY_MSB):0] dout_c,//to south_buffer　dx座標は切り取る >> ビット幅[20:0]
    output wen_c//to south_buffer
);

    wire [DX_MSB:DX_LSB] dx;
    wire signed [DY_MSB:DY_LSB] dy;
    assign dx = din[DX_MSB:DX_LSB];//9bit
    assign dy = din[DY_MSB:DY_LSB];//9bit
    
    wire [DX_MSB:DX_LSB] dx_plus_add;//9bit
    assign dx_plus_add = dx + ADD;
    
    //to rooting_buffer(西または東)
    //assign dout_a = DATA_WIDTH-1 == DX_MSB ? {dx_plus_add, din[DX_LSB-1:0]} : {din[DATA_WIDTH-1:DX_MSB+1], dx_plus_add, din[DX_LSB-1:0]};
    assign dout_a = {dx_plus_add, din[DX_LSB-1:0]};//dxだけインクリメントされて更新
    assign wen_a = dx == 0 ? 0 : wen;//dx==0とはそれ以上水平方向にパケットを移動しないでいいということ
    
    //to north_buffer(北)
    //assign dout_b = DATA_WIDTH-1 == DX_MSB ? din[DX_LSB-1:0] : {din[DATA_WIDTH-1:DX_MSB+1], din[DX_LSB-1:0]};
    assign dout_b = din[DX_LSB-1:0];
    assign wen_b = dy >= 0 ? (dx == 0 ? wen : 0) : 0;
    
    //to south_buffer(南)
    //assign dout_c = DATA_WIDTH-1 == DX_MSB ? din[DX_LSB-1:0] : {din[DATA_WIDTH-1:DX_MSB+1], din[DX_LSB-1:0]};
    assign dout_c = din[DX_LSB-1:0];
    assign wen_c = dy < 0 ? (dx == 0 ? wen : 0) : 0;

endmodule
