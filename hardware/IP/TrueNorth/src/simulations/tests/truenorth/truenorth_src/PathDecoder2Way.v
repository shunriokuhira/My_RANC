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
    input valid,//入ってくるパケットが有効であるか
    output [DATA_WIDTH-1:0] dout_routing,
    output men_routing,
    output [DATA_WIDTH-1-(DY_MSB-(DY_LSB-1)):0] dout_local,
    output men_local
);
   
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
