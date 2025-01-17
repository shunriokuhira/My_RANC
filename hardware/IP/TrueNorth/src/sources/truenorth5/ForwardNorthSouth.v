`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// ForwardNorthSouth.v
//
// The router forwarding modules for either Forward North or Forward South.
//
// If forward north, set NORTH to 1. If forward south, set SOUTH to 0.
// BUFFER_DEPTH must be a power of 2.
//////////////////////////////////////////////////////////////////////////////////


module ForwardNorthSouth #(
    parameter PACKET_WIDTH = 21,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter BUFFER_DEPTH = 4,
    parameter NORTH = 1
)(
    input clk,
    input rst,

   // input buffer_rst,

    input [PACKET_WIDTH-1:0] din_routing,
    input [PACKET_WIDTH-1:0] din_east,
    input [PACKET_WIDTH-1:0] din_west,
    
    input men_from_routing,
    input men_from_east,
    input men_from_west,

    input wait_from_routing,
    input wait_from_local,

    input full_from_routing,
    input full_from_local,//this is 0
    
    output [PACKET_WIDTH-1:0] dout_routing,
    output [PACKET_WIDTH-1-(DY_MSB-(DY_LSB-1)):0] dout_local,

    output men_routing,
    output men_local,
    
    output wait_to_routing,
    output wait_to_east,
    output wait_to_west,

    output full_to_routing,
    output full_to_east,
    output full_to_west
);

    localparam ADD = NORTH ? -1 : 1;
    wire [PACKET_WIDTH-1:0] merge_out;
    wire merge_out_wen;
    
    wire [PACKET_WIDTH-1:0] buffer_out;    
    wire buffer_full, buffer_empty, ren;
    
    wire wait_in, full, valid;
    assign wait_in = wait_from_routing | wait_from_local;
    assign full = full_from_routing | full_from_local;
    
    assign full_to_routing = buffer_full;
    assign full_to_east = buffer_full;
    assign full_to_west = buffer_full;

    Merge3 #(
        .DATA_WIDTH(PACKET_WIDTH)
    ) merge (
        .clk(clk),
        .rst(rst),
        .full(buffer_full),
        
        .men_from_routing(men_from_routing),
        .men_from_east(men_from_east),
        .men_from_west(men_from_west),

        .din_from_routing(din_routing),
        .din_from_east(din_east),
        .din_from_west(din_west),
        
        .merge_out(merge_out),
        .merge_wen(merge_out_wen),
        
        .wait_to_routing(wait_to_routing),
        .wait_to_east(wait_to_east),
        .wait_to_west(wait_to_west)
    );
    
    buffer #(
        .DATA_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) routing_buffer (
        .clk(clk),
        .rst(rst),

        //.buffer_rst(buffer_rst),

        .wait_in(wait_in),
        .full_in(full),
        .din(merge_out),
        .din_valid(merge_out_wen),
        //.read_en(ren),
        .dout(buffer_out),
        .empty(buffer_empty),
        .valid(valid),
        .full(buffer_full)
    );

    // renGen renGen(
    //     .clk(clk),
    //     .rst(rst),
    //     .empty(buffer_empty),
    //     .full(full),
    //     .ren(ren),
    //     .wait_renGen(wait_in)
    // );

    PathDecoder2Way #(
        .DATA_WIDTH(PACKET_WIDTH),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .ADD(ADD)
    ) PathDecoder2Way_tb (
        .din(buffer_out),
        .empty(buffer_empty),
        .valid(valid),
        
        .dout_routing(dout_routing),
        .dout_local(dout_local),
        
        .men_routing(men_routing),
        .men_local(men_local)
    );
    
        
    
endmodule
