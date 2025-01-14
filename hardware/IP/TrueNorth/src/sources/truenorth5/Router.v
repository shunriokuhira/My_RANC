`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Router.v
//
// The top module for the router of a core
//
//////////////////////////////////////////////////////////////////////////////////


module Router #(
    parameter PACKET_WIDTH = 30, // This is the largest width that the packet can have while going through the routers, not counting when bits are stripped away
    parameter DX_MSB = 29,       // Index of the MSB of the dx component, used so additional fields can be added to the packets without breaking logic
    parameter DX_LSB = 21,       // Index of the LSB of the dx component, used so additional fields can be added to the packets without breaking logic
    parameter DY_MSB = 20,       // Index of the MSB of the dy component, used so additional fields can be added to the packets without breaking logic
    parameter DY_LSB = 12,       // Index of the LSB of the dy component, used so additional fields can be added to the packets without breaking logic
    parameter BUFFER_DEPTH = 4   // The depth of all buffers in the router
)(
    input clk, // This is that tic-toc-clock boi
    input rst,
    input [PACKET_WIDTH-1:0] din_local,
    input din_local_wen,
    input [PACKET_WIDTH-1:0] din_west,
    input [PACKET_WIDTH-1:0] din_east,
    input [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] din_north,
    input [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] din_south,
    
    input men_in_west,
    input men_in_east,
    input men_in_north,
    input men_in_south,
    
    input full_in_west,
    input full_in_east,
    input full_in_north,
    input full_in_south,

    input wait_in_west,
    input wait_in_east,
    input wait_in_north,
    input wait_in_south,
    
    output [PACKET_WIDTH-1:0] dout_west,
    output [PACKET_WIDTH-1:0] dout_east,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_north,
    output [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] dout_south,
    output [PACKET_WIDTH-1-(DX_MSB-(DY_LSB-1)):0] dout_local,
    output dout_wen_local,
    
    output men_out_west,
    output men_out_east,
    output men_out_north,
    output men_out_south,
    
    output full_out_west,
    output full_out_east,
    output full_out_north,
    output full_out_south,

    output wait_out_west,
    output wait_out_east,
    output wait_out_north,
    output wait_out_south,

    output local_buffer_full
);
/*西から信号が入るときはin_west, 東から信号が入るときはin_east、南北も同様
    西から信号がでるときはout_west, 東から信号がでるときはout_east,南北も同様
    Forwardモジュール同士で閉じた信号のときはren_west_to_localのように、信号意味_送信先_to_受信先の構文で書く　
    パケットは東西南北いずれか"一方通行"だが、renとかは西からも東からも入出力する
  */  

    // Data signals
    wire [PACKET_WIDTH-1:0] data_local_to_east, data_local_to_west;
    wire [PACKET_WIDTH-1-(DX_MSB-(DY_LSB-1)):0] data_north_to_local, data_south_to_local;
    wire [PACKET_WIDTH-1-(DX_MSB-DY_MSB):0] data_east_to_north, data_east_to_south, data_west_to_north, data_west_to_south;

    // Full Signals
    wire full_east_to_local, full_west_to_local;
    wire full_north_to_east, full_south_to_east;
    wire full_north_to_west, full_south_to_west;

    //wait signals
    wire wait_east_to_local, wait_west_to_local;
    wire wait_north_to_east, wait_south_to_east;
    wire wait_north_to_west, wait_south_to_west;
    wire wait_local_to_north, wait_local_to_south;

    //men signals
    wire men_local_to_east, men_local_to_west;
    wire men_east_to_north, men_east_to_south;
    wire men_west_to_north, men_west_to_south;
    wire men_north_to_local, men_south_to_local;

    FromLocal #(
        .PACKET_WIDTH(PACKET_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .DX_MSB(DX_MSB),
        .DX_LSB(DX_LSB)
    ) from_local (
        .clk(clk),
        .rst(rst),
        .din(din_local),
        .din_wen(din_local_wen),
        
        .full_east(full_east_to_local),
        .full_west(full_west_to_local),
        
        .wait_east(wait_east_to_local),
        .wait_west(wait_west_to_local),
    //---output-----    
        .dout_east(data_local_to_east),
        .dout_west(data_local_to_west),
        
        .men_east(men_local_to_east),
        .men_west(men_local_to_west),
        
        .local_buffer_full(local_buffer_full)
    );
    
    
    ForwardEastWest #(
        .PACKET_WIDTH(PACKET_WIDTH),
        .DX_MSB(DX_MSB),
        .DX_LSB(DX_LSB),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .EAST(1)
    ) forward_east (
        .clk(clk),
        .rst(rst),
    
        .din_routing(din_west),
        .din_token_controller(data_local_to_east),

        .men_from_routing(men_in_west),
        .men_from_local(men_local_to_east),

        .wait_from_routing(wait_in_east),//これらの3つのwait信号を論理和とってrenGenにわたす
        .wait_from_north(wait_north_to_east),
        .wait_from_south(wait_south_to_east),
    
        .full_from_routing(full_in_east),//これらの3つのfull信号を論理和とってrenGenにわたす
        .full_from_north(full_north_to_east),
        .full_from_south(full_south_to_east),
    
    //---output-----
        .dout_routing(dout_east),
        .dout_north(data_east_to_north),
        .dout_south(data_east_to_south),
    
        .men_routing(men_out_east),
        .men_north(men_east_to_north),
        .men_south(men_east_to_south),

        .wait_to_routing(wait_out_west),
        .wait_to_local(wait_east_to_local),

        .full_to_routing(full_out_west),
        .full_to_local(full_east_to_local)
    );
    

    
    ForwardEastWest #(
        .PACKET_WIDTH(PACKET_WIDTH),
        .DX_MSB(DX_MSB),
        .DX_LSB(DX_LSB),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .EAST(0)
    ) forward_west (
        .clk(clk),
        .rst(rst),
    
        .din_routing(din_east),
        .din_token_controller(data_local_to_west),

        .men_from_routing(men_in_east),
        .men_from_local(men_local_to_west),

        .wait_from_routing(wait_in_west),
        .wait_from_north(wait_north_to_west),
        .wait_from_south(wait_south_to_west),
    
        .full_from_routing(full_in_west),
        .full_from_north(full_north_to_west),
        .full_from_south(full_south_to_west),
    
        .dout_routing(dout_west),
        .dout_north(data_west_to_north),
        .dout_south(data_west_to_south),
    
        .men_routing(men_out_west),
        .men_north(men_west_to_north),
        .men_south(men_west_to_south),

        .wait_to_routing(wait_out_east),
        .wait_to_local(wait_west_to_local),

        .full_to_routing(full_out_east),                       
        .full_to_local(full_west_to_local)
    );
    
    

    
    ForwardNorthSouth #(
        .PACKET_WIDTH(PACKET_WIDTH-(DX_MSB-DY_MSB)),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .NORTH(1)
    ) forward_north (
        .clk(clk),
        .rst(rst),
        .din_routing(din_south),
        .din_east(data_east_to_north),
        .din_west(data_west_to_north),
    
        .men_from_routing(men_in_south),
        .men_from_east(men_east_to_north),
        .men_from_west(men_west_to_north),

        .wait_from_routing(wait_in_north),
        .wait_from_local(wait_local_to_north),

        .full_from_routing(full_in_north),
        .full_from_local(1'b0),//LocalInにはバッファ存在しないのでゼロ
    
        .dout_routing(dout_north),
        .dout_local(data_north_to_local),

        .men_routing(men_out_north),
        .men_local(men_north_to_local),
    
        .wait_to_routing(wait_out_south),
        .wait_to_east(wait_north_to_east),
        .wait_to_west(wait_north_to_west),

        .full_to_routing(full_out_south),
        .full_to_east(full_north_to_east),
        .full_to_west(full_north_to_west)
    );
    

    
    ForwardNorthSouth #(
        .PACKET_WIDTH(PACKET_WIDTH-(DX_MSB-DY_MSB)),
        .DY_MSB(DY_MSB),
        .DY_LSB(DY_LSB),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .NORTH(0)
    ) forward_south (
        .clk(clk),
        .rst(rst),
        .din_routing(din_north),
        .din_east(data_east_to_south),
        .din_west(data_west_to_south),
    
        .men_from_routing(men_in_north),
        .men_from_east(men_east_to_south),
        .men_from_west(men_west_to_south),

        .wait_from_routing(wait_in_south),
        .wait_from_local(wait_local_to_south),

        .full_from_routing(full_in_south),
        .full_from_local(1'b0),
    
        .dout_routing(dout_south),
        .dout_local(data_south_to_local),

        .men_routing(men_out_south),
        .men_local(men_south_to_local),
    
        .wait_to_routing(wait_out_north),
        .wait_to_east(wait_south_to_east),
        .wait_to_west(wait_south_to_west),

        .full_to_routing(full_out_north),
        .full_to_east(full_south_to_east),
        .full_to_west(full_south_to_west)
    );
    
    LocalIn #(
        .PACKET_WIDTH(PACKET_WIDTH-(DX_MSB-(DY_LSB-1)))
    ) local_in (
        .clk(clk),
        .rst(rst),
        
        .din_north(data_north_to_local),
        .din_south(data_south_to_local),
        
        .men_from_north(men_north_to_local),
        .men_from_south(men_south_to_local),
        
        .wait_to_north(wait_local_to_north),
        .wait_to_south(wait_local_to_south),
        
        .dout(dout_local),
        .dout_wen(dout_wen_local)
    );
    
    
    
    
endmodule
