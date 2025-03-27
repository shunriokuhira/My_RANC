`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// buffer.v
//
// A simple buffer.
// Reads and writes are synchronous
// Reset is synchronous active high.
//
// NOTE: BUFFER_DEPTH has to be a power of 2 
// (Don't forget 1 is also a power of 2 :-) 
//////////////////////////////////////////////////////////////////////////////////


module buffer#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 4
)(
    input clk,
    input rst,
    input wait_in,
    input [DATA_WIDTH-1:0] din,//packet from merge
    input din_valid,//write_en from merge
    output [DATA_WIDTH-1:0] dout,
    output empty,
    output reg valid,
    output full
);

    localparam BUFFER_WIDTH = $clog2(BUFFER_DEPTH);
        
    reg [DATA_WIDTH-1:0] data [BUFFER_DEPTH-1:0];
    reg [BUFFER_WIDTH-1:0] read_pointer, write_pointer;
    reg [BUFFER_WIDTH:0] status_counter;
    reg [DATA_WIDTH-1:0] output_data;

    wire ren, wen;
    
    assign ren = ~(empty | wait_in); 
    assign wen = ~full & din_valid;
    
    assign empty = status_counter == 0;
    assign full = status_counter == BUFFER_DEPTH;
    assign dout = output_data;


    integer i;
    initial begin
        for (i = 0; i < BUFFER_DEPTH; i = i + 1)
            data[i] <= 0;
        read_pointer <= 0;
        write_pointer <= 0;
        status_counter <= 0;
        output_data <= 0;
    end

    //PathDecoderへ渡す信号
    always @(posedge clk) begin
        if(rst)begin
            valid <= 0;
        end
        else begin
            valid <= ren;
        end
    end

    always@(posedge clk) begin
        if (rst) begin
            data[0] <= 0;
            read_pointer <= 0;
            write_pointer <= 0;
            status_counter <= 0;
            output_data <= 0;
        end
        else begin
            if (wen) begin// write
                data[write_pointer] = din;
                write_pointer = write_pointer + 1;
                status_counter = status_counter + 1;
            end
            if (ren) begin// read
                output_data = data[read_pointer];
                read_pointer = read_pointer + 1;
                status_counter = status_counter - 1;
            end
        end
    end


//---------BUFFER_DEPTH == 1 ↓↓ -------
    // reg [DATA_WIDTH-1:0] data;
    // reg status_counter;
    // reg [DATA_WIDTH-1:0] output_data;
            
    // assign empty = status_counter == 0;
    // assign full = status_counter == BUFFER_DEPTH;
    // assign dout = output_data;

    // integer i;
    // initial begin
    //     data <= 0;
    //     status_counter <= 0;
    //     output_data <= 0;
    // end


    // always@(posedge clk) begin
    //     if (rst) begin
    //         data <= 0;
    //         status_counter <= 0;
    //         output_data <= 0;
    //     end
    //     else begin
    //         if (wen) begin
    //             data = din;
    //             status_counter = status_counter + 1;
    //         end
    //         if (ren) begin
    //             output_data = data;
    //             status_counter = status_counter - 1;
    //         end
    //     end
    // end


endmodule