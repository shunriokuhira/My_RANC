`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// LocalIn.v
//
// The local in module for the routing network. Packets from the north are
// prioritized over packets from the south. Packets should have dx and dy stripped.
//////////////////////////////////////////////////////////////////////////////////


module LocalIn #(
    parameter PACKET_WIDTH = 12
)(
    input clk,
    input rst,
    input [PACKET_WIDTH-1:0] din_north,
    input [PACKET_WIDTH-1:0] din_south,
    input men_from_north,
    input men_from_south,
    output wait_to_north,
    output wait_to_south,
    output [PACKET_WIDTH-1:0] dout,
    output dout_wen
    );
    
    
    Merge2 #(
        .DATA_WIDTH(PACKET_WIDTH)
    ) Merge (
        .clk(clk),
        .rst(rst),
        .full(1'b0),//LocalInモジュール内にはバッファないのでバッファからのfull信号はなし
        
        .men_from_local(men_from_north),
        .men_from_routing(men_from_south),
        
        .din_from_local(din_north),
        .din_from_routing(din_south),
        
        //---output----
        .merge_out(dout),
        .merge_wen(dout_wen),

        .wait_to_local(wait_to_north),
        .wait_to_routing(wait_to_south)
        );
    
endmodule
