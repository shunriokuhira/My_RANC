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
    input [PACKET_WIDTH-1:0] din,//CSRAMからのニューロンの目的地情報
    input din_wen,//コントローラからのスパイク列
    input ren_east,
    input ren_west,
    output [PACKET_WIDTH-1:0] dout_east,
    output [PACKET_WIDTH-1:0] dout_west,
    //output empty_east,
    //output empty_west,
    output buffer_empty,
    output buffer_full,
    //output full_west
    output local_east_men,
    output local_west_men
);
    wire ren;
    assign ren = ren_east | ren_west;

    buffer #(
        .DATA_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) buffer_local (
        .clk(clk),
        .rst(rst),
        .din(din),
        .din_valid(din_wen),//wenが有効になったらバッファに書き込み
        .read_en(ren),
        .dout(dout),
        .empty(buffer_empty),//ForwardEastWestのmerge2宛
        .full(buffer_full)//to controller
    );

    wire signed [DX_MSB:DX_LSB] dx;
    wire [PACKET_WIDTH-1:0] dout2;
    assign dout2 = dout;
    assign dx = dout2[DX_MSB:DX_LSB];//なぜかdxに直接dout[]を流すとIllegal part-select expression for variable "dout"というエラーでる
    //dx < 0なら、west側にパケットを書き込む
    //assign dout_east = dx < 0 ? 0 : din; // if dx == 0 going east      din_wenはcontrollerからのspike
    
    //assign dout_west= dx < 0 ? din : 0;

    //パケットの宛先方角(west or east)を決める
    assign dout_east = dout2;
    assign local_east_men = dx < 0 ? 0 : 1; // マージのための書き込みイネーブル信号。バッファではない
    
    assign dout_west = dout2;
    assign local_west_men = dx < 0 ? 1 : 0;
    
endmodule
