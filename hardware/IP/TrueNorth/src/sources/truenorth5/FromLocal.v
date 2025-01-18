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


    //input buffer_rst,

    input [PACKET_WIDTH-1:0] din,
    input din_wen,
    
    input full_east,
    input full_west,
    
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
    assign full_local = full_east | full_west;
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
        //.buffer_rst(buffer_rst),

        .wait_in(wait_local),
        .full_in(full_local),
        
        .din(din),
        .din_valid(din_wen),
        //.read_en(ren),
        .dout(dout),
        .empty(buffer_empty),
        .valid(valid),
        .full(local_buffer_full)
    );
    
    // renGen renGen(
    //     .clk(clk),
    //     .rst(rst),
    //     .empty(buffer_empty),
    //     .full(full_local),
    //     .wait_renGen(wait_local),
    //     .ren(ren)//out
    // );

    wire din_zero;
    assign din_zero = (dout == 30'b0) ? 1 : 0;
    reg [PACKET_WIDTH-1:0] din_before = 0;
    reg [PACKET_WIDTH-1:0] din_before2 = 0;
    reg [PACKET_WIDTH-1:0] din_before3 = 0;
    // always @(negedge clk) begin//dinは立ち上がりで出力されるので、立下りでキャッチする
    //     din_before <= din;
    //     din_before2 <= din_before;
    //     din_before3 <= din_before2;
    // end
    // wire read_twice;
    //assign read_twice = (din == din_before) ? 1 : 0;//二連続でおんなじ値が入力された
    //assign read_twice = 0;
    reg valid_r = 0;
    always @(posedge clk) begin
        if(rst)begin
            valid_r <= 0;
        end
        else begin
            valid_r <= valid;
        end
    end
    wire valid;

    reg empty_r = 0;
    always @(posedge clk) begin
        if(rst)begin
            empty_r <= 0;
        end
        else begin
            empty_r <= buffer_empty;
        end
    end

    wire signed [DX_MSB:DX_LSB] dx;
    assign dx = dout[DX_MSB:DX_LSB];
    
    assign dout_east = dout;
    //assign men_east = dx < 0 ? 0 : 1; // if dx == 0 going east
    assign men_east = (!valid) ? 0 : ((dx > 0)||(dx == 0) ? 1 : 0);

    assign dout_west = dout;
    //assign men_west = dx < 0 ? 1 : 0;
    assign men_west = (!valid) ? 0 : ((dx > 0)||(dx == 0) ? 0 : 1);
    
endmodule
