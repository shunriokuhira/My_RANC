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
    //input buffer_rst,
    
    input [PACKET_WIDTH-1:0] din_routing,
    input [PACKET_WIDTH-1:0] din_token_controller,

    input men_from_routing,
    input men_from_local,

    input wait_from_routing,
    input wait_from_north,
    input wait_from_south,
    
    input full_from_routing,
    input full_from_north,
    input full_from_south,
    
    output [PACKET_WIDTH-1:0] dout_routing,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_north,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_south,
    
    output men_routing,
    output men_north,
    output men_south,

    output wait_to_local,
    output wait_to_routing,

    output full_to_local,
    output full_to_routing
);

    localparam ADD = EAST ? -1 : 1;

    wire [PACKET_WIDTH-1:0] merge_out, buffer_out;
    wire merge_out_wen;
    
    wire routing_buffer_full, north_buffer_full, south_buffer_full;
    wire buffer_empty, ren;

    //-----to renGen------
    wire wait_in;
    wire full, valid;
    assign wait_in = wait_from_routing | wait_from_north | wait_from_south;
    assign full = full_from_routing | full_from_north | full_from_south;
    //--------------------
    wire buffer_full;
    assign full_to_local = buffer_full;
    assign full_to_routing = buffer_full;

    Merge2 #(
        .DATA_WIDTH(PACKET_WIDTH)
    ) Merge (
        .clk(clk),
        .rst(rst),
        .full(buffer_full),
        
        .men_from_local(men_from_local),
        .men_from_routing(men_from_routing),
        
        .din_from_local(din_token_controller),
        .din_from_routing(din_routing),
        
        .merge_out(merge_out),
        .merge_wen(merge_out_wen),
        
        .wait_to_routing(wait_to_routing),
        .wait_to_local(wait_to_local)
    );
    
    // renGen renGen(
    //     .clk(clk),
    //     .rst(rst),
    //     .empty(buffer_empty),
    //     .full(full),
    //     .ren(ren),
    //     .wait_renGen(wait_in)
    // );
    
    buffer #(
        .DATA_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) routing_buffer (
        .clk(clk),
        .rst(rst),
        //.buffer_rst(buffer_rst),
        .wait_in(wait_in),//read_en
        .full_in(full),
        .din(merge_out),
        .din_valid(merge_out_wen),
        //.read_en(),
        .dout(buffer_out),
        .empty(buffer_empty),
        .valid(valid),
        .full(buffer_full)
    );

    PathDecoder3Way #(
        .DATA_WIDTH(PACKET_WIDTH),
        .DX_MSB(DX_MSB),
        .DX_LSB(DX_LSB),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .ADD(ADD)
    ) PathDecoder (
        .din(buffer_out),
        .empty(buffer_empty),
        .valid(valid),

        .dout_routing(dout_routing),
        .dout_north(dout_north),
        .dout_south(dout_south),
        
        .men_routing(men_routing),
        .men_north(men_north),
        .men_south(men_south)
    );
    
    
endmodule
