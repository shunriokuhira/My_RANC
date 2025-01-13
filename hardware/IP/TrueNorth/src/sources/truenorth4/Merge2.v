`timescale 1ns / 1ps
module Merge2#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input full,
    input men_from_local,
    input men_from_routing,
    input [DATA_WIDTH-1:0] din_from_local,
    input [DATA_WIDTH-1:0] din_from_routing,
    output reg [DATA_WIDTH-1:0] merge_out,
    output reg merge_wen,
    output reg wait_to_routing,
    output reg wait_to_local
);


// reg [3:0] state = 0;
// localparam IDLE = 0, ROUTING = 1, LOCAL = 2;
// initial begin
//     wait_to_local <= 0;
//     wait_to_routing <= 0;
//     merge_out <= 30'b0;
//     merge_wen <= 0;
// end

// always @(*) begin
//     case(state)
//         IDLE:begin
//             if(men_from_routing)begin//menはCLK立ち上がりで動作
//                 state <= ROUTING;
//                 //wait_to_local <= 0;
//                 wait_to_routing <= 0;
//             end
//             else if(men_from_local)begin
//                 state <= LOCAL;
//                 wait_to_local <= 0;
//                 //wait_to_routing <= 0;
//             end
//             else begin
//                 state <= IDLE;
//                 wait_to_local <= 0;
//                 wait_to_routing <= 0;
//             end
//         end
//         ROUTING:begin//rouitng側からのパケット処理中
//             if(!men_from_routing)begin
//                 state <= IDLE;
//                 //wait_to_local <= 0;
//             end
//             else if(men_from_local)begin//menはCLK立ち上がりで動作
//                 state <= state;//現状維持
//                 wait_to_local <= 1;
//             end
//             else begin
//                 state <= ROUTING;
//                 wait_to_local <= 0;
//             end
//         end
//         LOCAL:begin
//             if(!men_from_local)begin
//                 state <= IDLE;
//                 wait_to_routing <= 0;
//             end
//             else if(men_from_routing)begin
//                 state <= state;
//                 wait_to_routing <= 1;
//             end
//             else begin
//                 state <= LOCAL;
//                 wait_to_routing <= 0;
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
//             LOCAL:begin
//                 merge_out <= din_from_local;
//                 merge_wen <= 1;
//             end
//         endcase
//     end
// end
reg [DATA_WIDTH-1:0] din_from_local_before;
reg [DATA_WIDTH-1:0] din_from_routing_before;
wire read_twice_local, read_twice_routing;//バッファが同じパケットを二回連続して書き込もうとしたことを検知
assign read_twice_local = (din_from_local_before == din_from_local) ? 1 : 0;
assign read_twice_routing = (din_from_routing_before == din_from_routing) ? 1 : 0;
always @(negedge clk) begin
    if(rst)begin
        din_from_local_before <= 0;
        din_from_routing_before <= 0;
    end
    else if(men_from_local)begin
        din_from_local_before <= din_from_local;
    end
    else if(men_from_routing)begin
        din_from_routing_before <= din_from_routing;
    end
end

always @(negedge clk) begin
    if(rst)begin
        merge_out <= 0;
        merge_wen <= 0;
        wait_to_local <= 0;
        wait_to_routing <= 0;
    end
    else if(!full)begin
        if(men_from_routing)begin//このフラグが立ってるあいだはパケット取り込める
            if(men_from_local)begin//外部パケット取り込み中にローカルパケットの取り込みのリクエストがきたとき
                wait_to_local <= 1;
            end

            // if(read_twice_routing)begin
            //     merge_out <= 0;
            //     merge_wen <= 0;
            //     wait_to_routing <= 0;
            // end
            // else begin
            //     merge_out <= din_from_routing;//外部パケット取り込み
            //     merge_wen <= 1;//バッファへの書き込み許可
            //     wait_to_routing <= 0;
            // end
            merge_out <= din_from_routing;//外部パケット取り込み
            merge_wen <= 1;//バッファへの書き込み許可
            wait_to_routing <= 0;
        end
        else if(men_from_local)begin
            if(men_from_routing)begin
                wait_to_routing <= 1;
            end
            // if(read_twice_local)begin
            //     merge_out <= 0;
            //     merge_wen <= 0;
            //     wait_to_local <= 0;
            // end
            // else begin
            //     merge_out <= din_from_local;
            //     merge_wen <= 1;
            //     wait_to_local <= 0;
            // end
                merge_out <= din_from_local;
                merge_wen <= 1;
                wait_to_local <= 0;

        end
        else begin
            merge_wen <= 0;
            //merge_out <= 0;
            wait_to_local <= 0;
            wait_to_routing <= 0;
        end
    end
end

endmodule