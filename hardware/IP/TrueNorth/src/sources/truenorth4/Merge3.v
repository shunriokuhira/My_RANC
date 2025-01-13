`timescale 1ns / 1ps
module Merge3#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input full,
    input men_from_east,
    input men_from_west,
    input men_from_routing,
    input [DATA_WIDTH-1:0] din_from_east,
    input [DATA_WIDTH-1:0] din_from_west,
    input [DATA_WIDTH-1:0] din_from_routing,
    output reg [DATA_WIDTH-1:0] merge_out,
    output reg merge_wen,
    output reg wait_to_east,
    output reg wait_to_west,
    output reg wait_to_routing
);

// reg [3:0] state = 0;
// localparam IDLE = 0, ROUTING = 1, EAST = 2, WEST = 3;
// initial begin
//     wait_to_east <= 0;
//     wait_to_west <= 0;
//     wait_to_routing <= 0;
//     merge_out <= 30'b0;
//     merge_wen <= 0;
// end

// always @(*) begin
//     case(state)
//         IDLE:begin
//             if(men_from_routing)begin//menはCLK立ち上がりで動作
//                 state <= ROUTING;
//                 wait_to_routing <= 0;
//             end
//             else if(men_from_east)begin
//                 state <= EAST;
//                 wait_to_east <= 0;
//             end
//             else if(men_from_west)begin
//                 state <= WEST;
//                 wait_to_west <= 0;
//             end
//             else begin
//                 state <= IDLE;
//                 wait_to_east <= 0;
//                 wait_to_west <= 0;
//                 wait_to_routing <= 0;
//             end
//         end
//         ROUTING:begin//rouitng側からのパケット処理中
//             if(!men_from_routing)begin
//                 state <= IDLE;
//                 // wait_to_east <= 0;
//                 // wait_to_west <= 0;
//             end
//             else if(men_from_east & men_from_west)begin//同時に1
//                 state <= state;
//                 wait_to_east <= 1;
//                 wait_to_west <= 1;
//             end
//             else if(men_from_east)begin//menはCLK立ち上がりで動作
//                 state <= state;//現状維持
//                 wait_to_east <= 1;
//                 wait_to_west <= 0;
//             end
//             else if(men_from_west)begin
//                 state <= state;
//                 wait_to_west <= 1;
//                 wait_to_east <= 0;
//             end
//             else begin
//                 state <= ROUTING;
//                 wait_to_east <= 0;
//                 wait_to_west <= 0;
//             end
//         end
//         EAST:begin
//             if(!men_from_east)begin
//                 state <= IDLE;
//                 // wait_to_routing <= 0;
//                 // wai_to_west <= 0;
//             end
//             else if(men_from_routing & men_from_west)begin//同時に1
//                 state <= state;
//                 wait_to_routing <= 1;
//                 wait_to_west <= 1;
//             end
//             else if(men_from_routing)begin
//                 state <= state;
//                 wait_to_routing <= 1;
//                 wait_to_west <= 0;
//             end
//             else if(men_from_west)begin
//                 state <= state;
//                 wait_to_west <= 1;
//                 wait_to_routing <= 0;
//             end
//             else begin
//                 state <= EAST;
//                 wait_to_routing <= 0;
//                 wait_to_west <= 0;
//             end
//         end
//         WEST:begin
//             if(!men_from_west)begin
//                 state <= IDLE;
//                 // wait_to_routing <= 0;
//                 // wai_to_east <= 0;
//             end
//             else if(men_from_routing & men_from_east)begin//同時に1
//                 state <= state;
//                 wait_to_routing <= 1;
//                 wait_to_east <= 1;
//             end
//             else if(men_from_routing)begin
//                 state <= state;
//                 wait_to_routing <= 1;
//                 wait_to_east <= 0;
//             end
//             else if(men_from_east)begin
//                 state <= state;
//                 wait_to_east <= 1;
//                 wait_to_routing <= 0;
//             end
//             else begin
//                 state <= WEST;
//                 wait_to_routing <= 0;
//                 wait_to_east <= 0;
//             end
//         end
//     endcase
// end

// always @(negedge clk) begin
//     if(rst)begin
//         merge_out <= 30'b0;
//         merge_wen <= 0;
//     end
//     else if(!full)begin
//         case(state)
//             IDLE:begin
//                 merge_out <= merge_out;
//                 merge_wen <= 0;
//             end
//             ROUTING:begin
//                 merge_out <= din_from_routing;
//                 merge_wen <= 1;
//             end
//             EAST:begin
//                 merge_out <= din_from_east;
//                 merge_wen <= 1;
//             end
//             WEST:begin
//                 merge_out <= din_from_west;
//                 merge_wen <= 1;
//             end
//         endcase
//     end
// end
always @(negedge clk) begin
    if(rst)begin
        merge_out <= 0;
        merge_wen <= 0;
        wait_to_east <= 0;
        wait_to_west <= 0;
        wait_to_routing <= 0;
    end
    else if(!full)begin//マージ出力先のバッファが満タンでない
        if(men_from_routing)begin//このフラグが立ってるあいだはパケット取り込める
            if(men_from_east)begin//外部パケット取り込み中にforwardeastモジュールからパケット取り込みのリクエストがきたとき
                wait_to_east <= 1;
            end
            else if(men_from_west)begin
                wait_to_west <= 1;
            end
            merge_out <= din_from_routing;//外部パケット取り込み
            merge_wen <= 1;//バッファへの書き込み許可
            wait_to_routing <= 0;
        end
        else if(men_from_east)begin
            if(men_from_routing)begin
                wait_to_routing <= 1;
            end
            else if(men_from_west)begin
                wait_to_west <= 1;
            end
            merge_out <= din_from_east;
            merge_wen <= 1;
            wait_to_east <= 0;
        end
        else if(men_from_west)begin
            if(men_from_routing)begin
                wait_to_routing <= 1;
            end
            else if(men_from_east)begin
                wait_to_east <= 1;
            end
            merge_out <= din_from_west;
            merge_wen <= 1;
            wait_to_west <= 0;
        end
        else begin
            merge_wen <= 0;
            wait_to_east <= 0;
            wait_to_west <= 0;
            wait_to_routing <= 0;
        end
    end
end

endmodule