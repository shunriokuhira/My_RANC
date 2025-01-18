`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// PathDecoder2Way.v
//
// The combinational logic or the forward north / forward south modules.
//
// For forward north:
//  - ADD should be set to -1
//  - dout_a goes to north out
//  - dout_b goes to local
//
// For forward south:
//  - ADD should be set to 1
//  - dout_a goes to south out
//  - dout_b goes to local
//////////////////////////////////////////////////////////////////////////////////


module PathDecoder2Way#(
    parameter DATA_WIDTH = 23,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter ADD = 1
)(
    input [DATA_WIDTH-1:0] din,
    input clk,
    input rst,
    input empty,
    input valid,//入ってくるパケットが有効であるか
    output [DATA_WIDTH-1:0] dout_routing,
    output men_routing,
    output [DATA_WIDTH-1-(DY_MSB-(DY_LSB-1)):0] dout_local,
    output men_local
);
    wire din_zero;
    assign din_zero = (din == 0) ? 1 : 0;
    // reg [DATA_WIDTH-1:0] din_before = 0;
    // reg [DATA_WIDTH-1:0] din_before2 = 0;
    // reg [DATA_WIDTH-1:0] din_before3 = 0;
    // always @(negedge clk) begin
    //     din_before <= din;
    //     din_before2 <= din_before;
    //     din_before3 <= din_before2;
    // end
    // wire read_twice;
    // assign read_twice = (din == din_before) ? 1 : 0;//二連続でおんなじ値が入力された
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
    reg empty_r = 0;
    always @(posedge clk) begin
        if(rst)begin
            empty_r <= 0;
        end
        else begin
            empty_r <= empty;
        end
    end
    wire signed [DY_MSB:DY_LSB] dy;
    assign dy = din[DY_MSB:DY_LSB];
    
    wire [DY_MSB:DY_LSB] dy_plus_add;
    assign dy_plus_add = dy + ADD;
    
    assign dout_routing = {dy_plus_add, din[DY_LSB-1:0]};
    assign men_routing = !valid ? 0 : ((dy == 0) ? 0 : 1);
    
    assign dout_local = din[DY_LSB-1:0];
    //assign men_local = dy == 0 ? 1 : 0;
    assign men_local = !valid ? 0 : (dy == 0 ? 1 : 0);

endmodule
