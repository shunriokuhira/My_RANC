-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
-- Date        : Wed May 22 14:40:46 2019
-- Host        : ENGR-RCL11G running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/rubenpurdy/Developer/RANC/Emulation/Projects/RANCStreaming/src/blockdesign/streaming/ip/streaming_AXIStreamPacketBuffer_0_1/streaming_AXIStreamPacketBuffer_0_1_stub.vhdl
-- Design      : streaming_AXIStreamPacketBuffer_0_1
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu9eg-ffvb1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity streaming_AXIStreamPacketBuffer_0_1 is
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    tick : in STD_LOGIC;
    packet : in STD_LOGIC_VECTOR ( 29 downto 0 );
    packet_valid : in STD_LOGIC;
    buffer_overflow_error : out STD_LOGIC;
    buffer_to_stream_error : out STD_LOGIC;
    m00_axis_aclk : in STD_LOGIC;
    m00_axis_aresetn : in STD_LOGIC;
    m00_axis_tvalid : out STD_LOGIC;
    m00_axis_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m00_axis_tstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m00_axis_tlast : out STD_LOGIC;
    m00_axis_tready : in STD_LOGIC
  );

end streaming_AXIStreamPacketBuffer_0_1;

architecture stub of streaming_AXIStreamPacketBuffer_0_1 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,rst,tick,packet[29:0],packet_valid,buffer_overflow_error,buffer_to_stream_error,m00_axis_aclk,m00_axis_aresetn,m00_axis_tvalid,m00_axis_tdata[31:0],m00_axis_tstrb[3:0],m00_axis_tlast,m00_axis_tready";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "AXIStreamPacketBuffer,Vivado 2018.2";
begin
end;
