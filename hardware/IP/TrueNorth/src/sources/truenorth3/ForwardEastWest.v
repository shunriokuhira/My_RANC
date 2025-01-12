`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ForwardEastWest.v
//
// The router forwarding modules for either Forward East or Forward East.
//
// If forward east, set EAST to 1. If forward west, set EAST to 0.
// BUFFER_DEPTH must be a power of 2.
//////////////////////////////////////////////////////////////////////////////////


module ForwardEastWest #(
    parameter PACKET_WIDTH = 30,
    parameter DX_MSB = 29,
    parameter DX_LSB = 21,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter BUFFER_DEPTH = 4,
    parameter EAST = 1
)(
    input clk,
    input rst,
    input [PACKET_WIDTH-1:0] din_routing,
    input [PACKET_WIDTH-1:0] din_token_controller,
    //input men_routing,//merge2に対する書き込み許可
    //input men_token_controller,//merge2に対する書き込み許可
    input empty_routing,
    input empty_token_controller,
    input ren_in_north,
    input ren_in_routing,
    input ren_in_south,
    output ren_out_routing,
    output ren_out_token_controller,
    output [PACKET_WIDTH-1:0] dout_routing,
    //output buffer_empty,
    //output routing_buffer_empty,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_north,
    //output north_buffer_empty,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_south,
    //output south_buffer_empty
    output routing_empty,//merge3に対する書き込み許可
    output north_empty,//merge3に対する書き込み許可
    output south_empty//merge3に対する書き込み許可
);

    localparam ADD = EAST ? -1 : 1;

    wire buffers_full;
    wire [PACKET_WIDTH-1:0] merge_out;
    wire merge_out_wen;
    
    wire [PACKET_WIDTH-1:0] routing_buffer_in;
    wire routing_buffer_wen;
    wire [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] north_buffer_in;
    wire north_buffer_wen;
    wire [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] south_buffer_in;
    wire south_buffer_wen;
    
    wire buffer_full;
    //assign buffers_full = routing_buffer_full | north_buffer_full | south_buffer_full;
    wire ren;
    assign ren = ren_in_routing | ren_in_north | ren_in_south;
    wire [PACKET_WIDTH-1:0] dout_buff, dx_dy;

    Merge2 #(
        .DATA_WIDTH(PACKET_WIDTH)
    ) Merge (
        .clk(clk),
        .rst(rst),
        .din_a(din_routing),//from PathDecoder3Way
        .buffer_a_empty(empty_routing),//from Buffer
        //.men_a(men_routing),//din_routingと一緒にセットでやってくる信号

        .din_b(din_token_controller),//from Fromlocall module
        .buffer_b_empty(empty_token_controller),
        //.men_b(men_token_controller),//din_token_controllerと一緒にセットでやってくる信号

        .buffer_out_full(buffer_full),
        .read_en_a(ren_out_routing),//out
        .read_en_b(ren_out_token_controller),//out
        .dout(merge_out),//out
        .wen(merge_out_wen)//out
    );
    
    buffer2 #(//rooting_buffer
        .DATA_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) routing_buffer (
        .clk(clk),
        .rst(rst),
        .din(merge_out),
        .din_valid(merge_out_wen),
        .read_en(ren),
        .dout(dout_buff),//西もしくは東へパケットを渡すポート
        .empty(buffer_empty),
        .full(buffer_full),
        .dx_dy(dx_dy)
    );

    PathDecoder3Way #(
        .DATA_WIDTH(PACKET_WIDTH),
        .DX_MSB(DX_MSB),
        .DX_LSB(DX_LSB),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .ADD(ADD)
    ) PathDecoder (
        //.clk(clk),
        .din(dout_buff),
        .dx_dy(dx_dy),
        .empty(buffer_empty),
        .dout_a(dout_routing),
        .empty_a(routing_empty),
        .dout_b(dout_north),
        .empty_b(north_empty),
        .dout_c(dout_south),
        .empty_c(south_empty)
    );
    
endmodule
