`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Core.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Contains all the modules for a single RANC core.
//////////////////////////////////////////////////////////////////////////////////

module Core #(
    parameter PACKET_WIDTH = 30,
    parameter NUM_NEURONS = 256,
    parameter NUM_AXONS = 256,
    parameter NUM_TICKS = 16,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2,
    parameter POTENTIAL_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter LEAK_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter DX_MSB = 29,
    parameter DX_LSB = 21,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter ROUTER_BUFFER_DEPTH = 4,
    parameter CSRAM_FILE = "csram_000.mem",
    parameter TC_FILE = "tc_000.mem"
)(
    input clk,
    input tick,
    input rst,
    input ren_in_west,
    input ren_in_east,
    input ren_in_north,
    input ren_in_south,
    input empty_in_west,
    input empty_in_east,
    input empty_in_north,
    input empty_in_south,
    input [PACKET_WIDTH-1:0] east_in,
    input [PACKET_WIDTH-1:0] west_in,
    input [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] north_in,
    input [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] south_in,
    output ren_out_west,
    output ren_out_east,
    output ren_out_north,
    output ren_out_south,
    output empty_out_west,
    output empty_out_east,
    output empty_out_north,
    output empty_out_south,
    output [PACKET_WIDTH-1:0] east_out,
    output [PACKET_WIDTH-1:0] west_out,
    output [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] north_out,
    output [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] south_out,
    output token_controller_error,
    output scheduler_error                  
);
    
    localparam DX_WIDTH = (DX_MSB-DX_LSB+1);
    localparam DY_WIDTH = (DY_MSB-DY_LSB+1);
    localparam CSRAM_WIDTH = NUM_AXONS + POTENTIAL_WIDTH + POTENTIAL_WIDTH + WEIGHT_WIDTH*NUM_WEIGHTS + LEAK_WIDTH + THRESHOLD_WIDTH + THRESHOLD_WIDTH + $clog2(NUM_RESET_MODES) + DX_WIDTH + DY_WIDTH + $clog2(NUM_AXONS) + $clog2(NUM_TICKS);
    localparam CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX = CSRAM_WIDTH - NUM_AXONS;
    localparam CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX = CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX - POTENTIAL_WIDTH;
    localparam CSRAM_RESET_POTENTIAL_BOTTOM_INDEX = CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX - POTENTIAL_WIDTH;
    localparam CSRAM_WEIGHTS_BOTTOM_INDEX = CSRAM_RESET_POTENTIAL_BOTTOM_INDEX - WEIGHT_WIDTH*NUM_WEIGHTS;
    localparam CSRAM_LEAK_BOTTOM_INDEX = CSRAM_WEIGHTS_BOTTOM_INDEX - LEAK_WIDTH;
    localparam CSRAM_THRESHOLD_BOTTOM_INDEX = CSRAM_LEAK_BOTTOM_INDEX - THRESHOLD_WIDTH;
    localparam CSRAM_FLOOR_BOTTOM_INDEX = CSRAM_THRESHOLD_BOTTOM_INDEX - THRESHOLD_WIDTH;
    localparam CSRAM_RESET_MODE_BOTTOM_INDEX = CSRAM_FLOOR_BOTTOM_INDEX - $clog2(NUM_RESET_MODES);
    //↓使われてなさそう
    localparam CSRAM_DX_BOTTOM_INDEX = CSRAM_RESET_MODE_BOTTOM_INDEX - DX_WIDTH;
    localparam CSRAM_DY_BOTTOM_INDEX = CSRAM_DX_BOTTOM_INDEX - DY_WIDTH;
    localparam CSRAM_AXON_DESTINATION_BOTTOM_INDEX = CSRAM_DY_BOTTOM_INDEX - $clog2(NUM_AXONS);
    localparam CSRAM_SPIKE_DELIVERY_TICK_BOTTOM_INDEX = CSRAM_AXON_DESTINATION_BOTTOM_INDEX - $clog2(NUM_AXONS);
    
    // Scheduler
    wire [NUM_AXONS-1:0] axon_spikes;
    
    // CSRAM
    wire [CSRAM_WIDTH-1:0] CSRAM_data;
    wire CSRAM_complete;
    wire [$clog2(NUM_NEURONS)-1:0] CSRAM_addr;
    
    // Token Controller
    wire CSRAM_write, CSRAM_set, CSRAM_init;
    wire scheduler_set, scheduler_clr, router_spike;
    wire neuron_block_en, neuron_block_next_neuron;
    wire neuron_block_write_current_potential;
    wire [$clog2(NUM_WEIGHTS)-1:0] neuron_instruction;
    
    // Nueron Block
    wire [POTENTIAL_WIDTH-1:0] neuron_potential;
    wire neuron_block_spike;

    // Router -> Scheduler
    wire [$clog2(NUM_AXONS) + $clog2(NUM_TICKS) - 1:0] scheduler_packet;
    wire scheduler_wen;
    
    // Router -> Token Controller
    wire local_buffers_full;
    
Scheduler #(
    .NUM_AXONS(NUM_AXONS),
    .NUM_TICKS(NUM_TICKS)
) Scheduler (
    .clk(clk),
    .rst(rst),
    .wen(scheduler_wen),// router >> scheduler
    .set(scheduler_set),// controller >> scheduler
    .clr(scheduler_clr),// controller >> scheduler
    .packet(scheduler_packet),// router >> scheduler
    .axon_spikes(axon_spikes),//output scheduler >> controller
    .error(scheduler_error)//output scheduler >> otherCore?
);

/* Addressing:
    ~ NUM_AXONS - Synaptic Connections
    ~ POTENTIAL_WIDTH - Current Potential
    ~ POTENTIAL_WIDTH - Reset Potential
    ~ WEIGHT_WIDTH*NUM_WEIGHTS - Weights
    ~ LEAK_WIDTH - Leak
    ~ THRESHOLD_WIDTH - Positive Threshold
    ~ THRESHOLD_WIDTH - Negative Threshold
    ~ $clog2(NUM_RESET_MODES) - Reset Mode
    ~ DX_WIDTH - Destination X
    ~ DY_WIDTH - Destination Y
    ~ $clog2(NUM_AXONS) - Axon Destination
    ~ $clog2(NUM_TICKS) - Spike Delivery Tick */
CSRAM #(
    .FILENAME(CSRAM_FILE),
    .NUM_NEURONS(NUM_NEURONS),
    .WIDTH(CSRAM_WIDTH),
    .WRITE_INDEX(CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX),
    .WRITE_WIDTH(POTENTIAL_WIDTH)
) CSRAM (
    .clk(clk),
    .wen(CSRAM_write),  //from controller
    .address(CSRAM_addr),
    .data_in({CSRAM_data[CSRAM_WIDTH-1:CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX], neuron_potential, CSRAM_data[CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX-1:0]}),
    .data_out(CSRAM_data)//output reg to CSRAM, controller, neuronblock, router
);

TokenController #(
    .NUM_AXONS(NUM_AXONS),
    .NUM_NEURONS(NUM_NEURONS),
    .NUM_WEIGHTS(NUM_WEIGHTS),
    .FILENAME(TC_FILE)
) TokenController (
    .clk(clk), 
    .rst(rst),
    .tick(tick),
    .axon_spikes(axon_spikes), 
    .synapses(CSRAM_data[CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX +: NUM_AXONS]), //from CSRAM
    .spike_in(neuron_block_spike),
    .local_buffers_full(local_buffers_full),
    .error(token_controller_error),//to outside
    .scheduler_set(scheduler_set), //to scheduler
    .scheduler_clr(scheduler_clr),//to scheduler
    .CSRAM_write(CSRAM_write),//to CSRAM
    .CSRAM_addr(CSRAM_addr),//to CSRAM
    .neuron_instruction(neuron_instruction), //to neuronblock
    .spike_out(router_spike),//to router
    .neuron_reg_en(neuron_block_en), //to neuronblock
    .next_neuron(neuron_block_next_neuron),// to neuronblock
    .write_current_potential(neuron_block_write_current_potential)//to neuronblock
);

NeuronBlock #(
    .LEAK_WIDTH(LEAK_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .THRESHOLD_WIDTH(THRESHOLD_WIDTH),
    .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
    .NUM_WEIGHTS(NUM_WEIGHTS),
    .NUM_RESET_MODES(NUM_RESET_MODES)
) NeuronBlock (
    .leak(CSRAM_data[CSRAM_LEAK_BOTTOM_INDEX +: LEAK_WIDTH]),
    .weights(CSRAM_data[CSRAM_WEIGHTS_BOTTOM_INDEX +: WEIGHT_WIDTH*NUM_WEIGHTS]),
    .positive_threshold(CSRAM_data[CSRAM_THRESHOLD_BOTTOM_INDEX +: THRESHOLD_WIDTH]),
    .negative_threshold(CSRAM_data[CSRAM_FLOOR_BOTTOM_INDEX +: THRESHOLD_WIDTH]),
    .reset_potential(CSRAM_data[CSRAM_RESET_POTENTIAL_BOTTOM_INDEX +: POTENTIAL_WIDTH]),
    .current_potential(CSRAM_data[CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX +: POTENTIAL_WIDTH]),
    .neuron_instruction(neuron_instruction),//from controller
    .reset_mode(CSRAM_data[CSRAM_RESET_MODE_BOTTOM_INDEX +: $clog2(NUM_RESET_MODES)]),
    .clk(clk),
    .next_neuron(neuron_block_next_neuron),//from controller
    .integrator_reg_en(neuron_block_en),//from controller
    .write_current_potential(neuron_block_write_current_potential),//from controller
    .write_potential(neuron_potential),//to CSRAM
    .spike_out(neuron_block_spike)//to controller
);

Router #(
    .PACKET_WIDTH(PACKET_WIDTH),
    .DX_MSB(DX_MSB), 
    .DX_LSB(DX_LSB),
    .DY_MSB(DY_MSB),
    .DY_LSB(DY_LSB),
    .BUFFER_DEPTH(ROUTER_BUFFER_DEPTH)
) Router (
    .clk(clk),
    .rst(rst),
    .din_local(CSRAM_data[PACKET_WIDTH-1:0]),
    .din_local_wen(router_spike),//from controller
    .din_west(west_in),//from outside
    .din_east(east_in),//from outside
    .din_north(north_in),//from outside
    .din_south(south_in),//from outside
    .ren_in_west(ren_in_west),//from outside
    .ren_in_east(ren_in_east),//from outside
    .ren_in_north(ren_in_north),//from outside
    .ren_in_south(ren_in_south),//from outside
    .empty_in_west(empty_in_west),//from outside
    .empty_in_east(empty_in_east),//from outside
    .empty_in_north(empty_in_north),//from outside
    .empty_in_south(empty_in_south),//from outside
    .dout_west(west_out),//to outside
    .dout_east(east_out),//to outside
    .dout_north(north_out),//to outside
    .dout_south(south_out),//to outside
    .dout_local(scheduler_packet),//to scheduler
    .dout_wen_local(scheduler_wen),//to scheduler
    .ren_out_west(ren_out_west),//to outside
    .ren_out_east(ren_out_east),//to outside
    .ren_out_north(ren_out_north),//to outside
    .ren_out_south(ren_out_south),//to outside
    .empty_out_west(empty_out_west),//to outside
    .empty_out_east(empty_out_east),//to outside
    .empty_out_north(empty_out_north),//to outside
    .empty_out_south(empty_out_south),//to outside
    .local_buffers_full(local_buffers_full)//to controller
);

endmodule
