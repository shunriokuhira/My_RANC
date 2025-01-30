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


//merge_v4
// State machine states
reg [1:0] state = 0; // 0: idle, 1: wait state
localparam idle = 0, east_out = 1, west_out = 2;

// Internal flags for prioritizing inputs
reg conflict_3 = 0;

always @(negedge clk) begin
    if(rst)begin
        merge_out <= 0;
        merge_wen <= 0;
        wait_to_routing <= 0;
        wait_to_east <= 0;
        wait_to_west <= 0;
        state <= 0;
        conflict_3 <= 0;
    end
    else if(!full)begin
        case (state)
            idle: begin
                // Idle state: check enable signals and prioritize data_a
                if (men_from_routing & men_from_east & men_from_west) begin//3つ同時に競合を検知
                    merge_out <= din_from_routing; // Prioritize data_a
                    merge_wen <= 1;
                    state <= east_out;
                    conflict_3 <= 1;

                    wait_to_routing <= 1;
                    wait_to_east <= 1;
                    wait_to_west <= 1;
                end
                else if(men_from_routing & men_from_east & !men_from_west)begin//routingとeastの競合を検知
                    merge_out <= din_from_routing;
                    merge_wen <= 1;
                    state <= east_out;

                    wait_to_routing <= 1;
                    wait_to_east <= 1;
                    wait_to_west <= 0;
                end 
                else if(men_from_routing & !men_from_east & men_from_west)begin//routingとwestの競合を検知
                    merge_out <= din_from_routing;//いったん，routing側を出力
                    merge_wen <= 1;
                    state <= west_out;//つぎの立下りでwest側を出力

                    wait_to_routing <= 1;
                    wait_to_east <= 0;
                    wait_to_west <= 1;
                end
                else if(!men_from_routing & men_from_east & men_from_west)begin//eastとwestの競合を検知
                    merge_out <= din_from_east;
                    merge_wen <= 1;
                    state <= west_out;

                    wait_to_routing <= 0;
                    wait_to_east <= 1;
                    wait_to_west <= 1;
                end
                else if (men_from_routing & !men_from_east & !men_from_west) begin//routingのみを検知
                    merge_out <= din_from_routing; // Only data_a is enabled
                    merge_wen <= 1;
                    state <= idle;

                    wait_to_routing <= 1'b0;
                    wait_to_east <= 1'b0; // Clear wait signal otherwise
                    wait_to_west <= 1'b0;
                end 
                else if (!men_from_routing & men_from_east & !men_from_west) begin//eastのみを検知
                    merge_out <= din_from_east; // Only data_b is enabled
                    merge_wen <= 1;
                    state <= idle;

                    wait_to_routing <= 1'b0;
                    wait_to_east <= 1'b0; // Clear wait signal otherwise
                    wait_to_west <= 1'b0;
                end
                else if (!men_from_routing & !men_from_east & men_from_west) begin//westのみを検知
                    merge_out <= din_from_west; // Only data_b is enabled
                    merge_wen <= 1;
                    state <= idle;

                    wait_to_routing <= 1'b0;
                    wait_to_east <= 1'b0; // Clear wait signal otherwise
                    wait_to_west <= 1'b0;
                end
                else begin
                    merge_out <= 0;
                    merge_wen <= 0;
                    state <= idle;
                    wait_to_routing <= 1'b0;
                    wait_to_east <= 1'b0; // Clear wait signal otherwise
                    wait_to_west <= 1'b0;
                end
            end
            east_out: begin
                // Wait state: process data_b if flagged
                merge_out <= din_from_east;
                merge_wen <= 1;
                if(conflict_3)begin
                    state <= west_out;
                end
                else begin
                    state <= idle; // Return to idle state
                    wait_to_east <= 1'b0; // Clear wait signal otherwise
                    wait_to_west <= 1'b0;
                    wait_to_routing <= 1'b0;
                end
            end
            west_out: begin
                // Wait state: process data_b if flagged
                merge_out <= din_from_west;
                merge_wen <= 1;
                conflict_3 <= 0;
                state <= idle; // Return to idle state
                wait_to_east <= 1'b0; // Clear wait signal otherwise
                wait_to_west <= 1'b0;
                wait_to_routing <= 1'b0;
            end
        endcase
    end
    else begin
        merge_out <= merge_out;
        merge_wen <= 0;
        wait_to_routing <= 1;
        wait_to_east <= 1;
        wait_to_west <= 1;
        state <= idle;
    end
    
end


// always @(negedge clk) begin
//     if(rst)begin
//         merge_out <= 0;
//         merge_wen <= 0;
//         wait_to_routing <= 0;
//         wait_to_east <= 0;
//         wait_to_west <= 0;
//         state <= wait_east;
//     end
//     else if(!full)begin
//         if(men_from_routing & !men_from_east & !men_from_west)begin//routing側だけからリクエストがきたとき
//             merge_out <= din_from_routing;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//         end
//         else if(!men_from_routing & men_from_east & !men_from_west)begin//東側だけからリクエストきたとき
//             merge_out <= din_from_east;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//         end
//         else if(!men_from_routing & !men_from_east & men_from_west)begin//西側だけからリクエストきたとき
//             merge_out <= din_from_west;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//         end
//         else if(men_from_routing & men_from_east & !men_from_west)begin//routing側と東の競合
//            merge_out <= din_from_routing;
//            merge_wen <= 1;
//            clk_cycle <= clk_cycle + 1;
//         end
//         else if(men_from_routing & !men_from_east & men_from_west)begin//routing側と西の競合
            
                
//         end
//         else if(!men_from_routing & men_from_east & men_from_west)begin//西と東での競合
           

//         end
//         else if(men_from_routing & men_from_east & men_from_west)begin//すべて競合したとき
           

//         end
//         else begin
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             merge_out <= 0;
//             merge_wen <= 0;
//             state <= wait_east;
//         end
        
//     end
// end


//merge_v3
// reg[3:0] state = 1;
// localparam wait_routing = 0, wait_east = 1, wait_west = 2;
// always @(negedge clk) begin
//     if(rst)begin
//         merge_out <= 0;
//         merge_wen <= 0;
//         wait_to_routing <= 0;
//         wait_to_east <= 0;
//         wait_to_west <= 0;
//         state <= wait_east;
//     end
//     else if(!full)begin
//         if(men_from_routing & !men_from_east & !men_from_west)begin//routing側だけからリクエストがきたとき
//             merge_out <= din_from_routing;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             state <= wait_routing;
//         end
//         else if(!men_from_routing & men_from_east & !men_from_west)begin//東側だけからリクエストきたとき
//             merge_out <= din_from_east;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             state <= wait_east;
//         end
//         else if(!men_from_routing & !men_from_east & men_from_west)begin//西側だけからリクエストきたとき
//             merge_out <= din_from_west;
//             merge_wen <= 1;
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             state <= wait_west;
//         end
//         else if(men_from_routing & men_from_east & !men_from_west)begin//routing側と東の競合
//             case(state)
//                 wait_routing:begin
//                     wait_to_routing <= 1;
//                     wait_to_east <= 0;
//                     wait_to_west <= 0;
//                     merge_out <= din_from_east;//東からのパケットを優先してあげる
//                     merge_wen <= 1;
//                     state <= wait_east;
//                 end

//                 wait_east:begin
//                     wait_to_routing <= 0;
//                     wait_to_east <= 1;
//                     wait_to_west <= 0;
//                     merge_out <= din_from_routing;
//                     merge_wen <= 1;
//                     state <= wait_routing;
//                 end
//             endcase
//         end
//         else if(men_from_routing & !men_from_east & men_from_west)begin//routing側と西の競合
//             case(state)
//                 wait_routing:begin
//                     wait_to_routing <= 1;
//                     wait_to_east <= 0;
//                     wait_to_west <= 0;
//                     merge_out <= din_from_west;
//                     merge_wen <= 1;
//                     state <= wait_west;
//                 end

//                 wait_west:begin
//                     wait_to_routing <= 0;
//                     wait_to_east <= 0;
//                     wait_to_west <= 1;
//                     merge_out <= din_from_routing;
//                     merge_wen <= 1;
//                     state <= wait_routing;
//                 end
//             endcase
//         end
//         else if(!men_from_routing & men_from_east & men_from_west)begin//西と東での競合
//             case(state)
//                 wait_east:begin
//                     wait_to_routing <= 0;
//                     wait_to_east <= 1;
//                     wait_to_west <= 0;
//                     merge_out <= din_from_west;
//                     merge_wen <= 1;
//                     state <= wait_west;
//                 end

//                 wait_west:begin
//                     wait_to_routing <= 0;
//                     wait_to_east <= 0;
//                     wait_to_west <= 1;
//                     merge_out <= din_from_east;
//                     merge_wen <= 1;
//                     state <= wait_east;
//                 end
//             endcase
//         end
//         else if(men_from_routing & men_from_east & men_from_west)begin//すべて競合したとき
//             case(state)
//                 wait_routing:begin
//                     wait_to_routing <= 1;
//                     wait_to_east <= 0;
//                     wait_to_west <= 1;
//                     merge_out <= din_from_east;
//                     merge_wen <= 1;
//                     state <= wait_east;
//                 end

//                 wait_east:begin
//                     wait_to_routing <= 1;
//                     wait_to_east <= 1;
//                     wait_to_west <= 0;
//                     merge_out <= din_from_west;
//                     merge_wen <= 1;
//                     state <= wait_west;
//                 end

//                 wait_west:begin
//                     wait_to_routing <= 0;
//                     wait_to_east <= 1;
//                     wait_to_west <= 1;
//                     merge_out <= din_from_routing;
//                     merge_wen <= 1;
//                     state <= wait_routing;
//                 end
//             endcase
//         end
//         else begin
//             wait_to_routing <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             merge_out <= 0;
//             merge_wen <= 0;
//             state <= wait_east;
//         end
        
//     end
// end





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


//merge_v1
// always @(negedge clk) begin
//     if(rst)begin
//         merge_out <= 0;
//         merge_wen <= 0;
//         wait_to_east <= 0;
//         wait_to_west <= 0;
//         wait_to_routing <= 0;
//     end
//     else if(!full)begin//マージ出力先のバッファが満タンでない
//         if(men_from_routing)begin//このフラグが立ってるあいだはパケット取り込める
//             if(men_from_east)begin//外部パケット取り込み中にforwardeastモジュールからパケット取り込みのリクエストがきたとき
//                 wait_to_east <= 1;
//             end
//             else if(men_from_west)begin
//                 wait_to_west <= 1;
//             end
//             merge_out <= din_from_routing;//外部パケット取り込み
//             merge_wen <= 1;//バッファへの書き込み許可
//             wait_to_routing <= 0;
//         end
//         else if(men_from_east)begin
//             if(men_from_routing)begin
//                 wait_to_routing <= 1;
//             end
//             else if(men_from_west)begin
//                 wait_to_west <= 1;
//             end
//             merge_out <= din_from_east;
//             merge_wen <= 1;
//             wait_to_east <= 0;
//         end
//         else if(men_from_west)begin
//             if(men_from_routing)begin
//                 wait_to_routing <= 1;
//             end
//             else if(men_from_east)begin
//                 wait_to_east <= 1;
//             end
//             merge_out <= din_from_west;
//             merge_wen <= 1;
//             wait_to_west <= 0;
//         end
//         else begin
//             merge_wen <= 0;
//             merge_out <= 0;
//             wait_to_east <= 0;
//             wait_to_west <= 0;
//             wait_to_routing <= 0;
//         end
//     end
// end

endmodule