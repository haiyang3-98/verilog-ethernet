/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic
 */
module fpga_core #
(
    parameter TARGET = "XILINX"
)
(
    /*
     * Clock: 390.625 MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       rst,

    /*
     * GPIO
     */
    output wire [1:0] user_led_g,
    output wire       user_led_r,
    output wire [1:0] front_led,
    input  wire [1:0] user_sw,

    /*
     * Ethernet: QSFP28
     */
    input  wire        qsfp_0_tx_clk_0,
    input  wire        qsfp_0_tx_rst_0,
    output wire [63:0] qsfp_0_txd_0,
    output wire [7:0]  qsfp_0_txc_0,
    input  wire        qsfp_0_rx_clk_0,
    input  wire        qsfp_0_rx_rst_0,
    input  wire [63:0] qsfp_0_rxd_0,
    input  wire [7:0]  qsfp_0_rxc_0,
    input  wire        qsfp_0_tx_clk_1,
    input  wire        qsfp_0_tx_rst_1,
    output wire [63:0] qsfp_0_txd_1,
    output wire [7:0]  qsfp_0_txc_1,
    input  wire        qsfp_0_rx_clk_1,
    input  wire        qsfp_0_rx_rst_1,
    input  wire [63:0] qsfp_0_rxd_1,
    input  wire [7:0]  qsfp_0_rxc_1,
    input  wire        qsfp_0_tx_clk_2,
    input  wire        qsfp_0_tx_rst_2,
    output wire [63:0] qsfp_0_txd_2,
    output wire [7:0]  qsfp_0_txc_2,
    input  wire        qsfp_0_rx_clk_2,
    input  wire        qsfp_0_rx_rst_2,
    input  wire [63:0] qsfp_0_rxd_2,
    input  wire [7:0]  qsfp_0_rxc_2,
    input  wire        qsfp_0_tx_clk_3,
    input  wire        qsfp_0_tx_rst_3,
    output wire [63:0] qsfp_0_txd_3,
    output wire [7:0]  qsfp_0_txc_3,
    input  wire        qsfp_0_rx_clk_3,
    input  wire        qsfp_0_rx_rst_3,
    input  wire [63:0] qsfp_0_rxd_3,
    input  wire [7:0]  qsfp_0_rxc_3,
    input  wire        qsfp_1_tx_clk_0,
    input  wire        qsfp_1_tx_rst_0,
    output wire [63:0] qsfp_1_txd_0,
    output wire [7:0]  qsfp_1_txc_0,
    input  wire        qsfp_1_rx_clk_0,
    input  wire        qsfp_1_rx_rst_0,
    input  wire [63:0] qsfp_1_rxd_0,
    input  wire [7:0]  qsfp_1_rxc_0,
    input  wire        qsfp_1_tx_clk_1,
    input  wire        qsfp_1_tx_rst_1,
    output wire [63:0] qsfp_1_txd_1,
    output wire [7:0]  qsfp_1_txc_1,
    input  wire        qsfp_1_rx_clk_1,
    input  wire        qsfp_1_rx_rst_1,
    input  wire [63:0] qsfp_1_rxd_1,
    input  wire [7:0]  qsfp_1_rxc_1,
    input  wire        qsfp_1_tx_clk_2,
    input  wire        qsfp_1_tx_rst_2,
    output wire [63:0] qsfp_1_txd_2,
    output wire [7:0]  qsfp_1_txc_2,
    input  wire        qsfp_1_rx_clk_2,
    input  wire        qsfp_1_rx_rst_2,
    input  wire [63:0] qsfp_1_rxd_2,
    input  wire [7:0]  qsfp_1_rxc_2,
    input  wire        qsfp_1_tx_clk_3,
    input  wire        qsfp_1_tx_rst_3,
    output wire [63:0] qsfp_1_txd_3,
    output wire [7:0]  qsfp_1_txc_3,
    input  wire        qsfp_1_rx_clk_3,
    input  wire        qsfp_1_rx_rst_3,
    input  wire [63:0] qsfp_1_rxd_3,
    input  wire [7:0]  qsfp_1_rxc_3,

    //input and output payload
    output wire [255:0] rx_payload_axis_tdata,
    output wire [31:0] rx_payload_axis_tkeep,
    output wire rx_payload_axis_tvalid,
    input wire rx_payload_axis_tready,
    output wire  rx_payload_axis_tlast,
    output wire rx_payload_axis_tuser,

    input wire [255:0] tx_payload_axis_tdata,
    input wire [31:0] tx_payload_axis_tkeep,
    input wire tx_payload_axis_tvalid,
    output wire tx_payload_axis_tready,
    input wire  tx_payload_axis_tlast, 

    //networking parameter
        // Configuration
    input wire [47:0] local_mac,
    input wire [31:0] local_ip,
    input wire [31:0] gateway_ip,
    input wire [31:0] subnet_mask,
    input wire [47:0] dest_mac, // is not used, discovered by arp instead
    input wire [31:0] dest_ip  

);

//for icarus dump

initial begin
  $dumpfile ("dump.vcd");
  $dumpvars (0, fpga_core);
  #1;
end

reg [47:0] checksum;
reg [47:0] checksum_next;
reg wait_checksum;
reg checksum_last_step;
reg [47:0] checksum_header;

// 256bit to 64bit convertion
wire [63:0] rx_payload_axis_tdata_64;
wire [7:0] rx_payload_axis_tkeep_64;
wire rx_payload_axis_tvalid_64;
wire rx_payload_axis_tready_64;
wire  rx_payload_axis_tlast_64;
wire rx_checksum_OK_64;

wire [63:0] tx_payload_axis_tdata_64;
wire [7:0] tx_payload_axis_tkeep_64;
wire tx_payload_axis_tvalid_64;
wire tx_payload_axis_tready_64;
wire  tx_payload_axis_tlast_64; 

axis_adapter #
(
    .S_DATA_WIDTH(256),
    .M_DATA_WIDTH(64),
    .USER_ENABLE(0)
) axis_dwidth_converter_256_64_inst
(
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(tx_payload_axis_tdata),
    .s_axis_tkeep(tx_payload_axis_tkeep),
    .s_axis_tvalid(tx_payload_axis_tvalid),
    .s_axis_tready(tx_payload_axis_tready),
    .s_axis_tlast(tx_payload_axis_tlast),

    .m_axis_tdata(tx_payload_axis_tdata_64),
    .m_axis_tkeep(tx_payload_axis_tkeep_64),
    .m_axis_tvalid(tx_payload_axis_tvalid_64),
    .m_axis_tready(tx_payload_axis_tready_64),
    .m_axis_tlast(tx_payload_axis_tlast_64)
    );

axis_adapter #
(
    .S_DATA_WIDTH(64),
    .M_DATA_WIDTH(256)
) axis_dwidth_converter_64_256_inst
(
    .clk(clk),
    .rst(rst),

    .s_axis_tdata(rx_payload_axis_tdata_64),
    .s_axis_tkeep(rx_payload_axis_tkeep_64),
    .s_axis_tvalid(rx_payload_axis_tvalid_64),
    .s_axis_tready(rx_payload_axis_tready_64),
    .s_axis_tlast(rx_payload_axis_tlast_64),
    .s_axis_tuser(rx_checksum_OK_64),

    .m_axis_tdata(rx_payload_axis_tdata),
    .m_axis_tkeep(rx_payload_axis_tkeep),
    .m_axis_tvalid(rx_payload_axis_tvalid),
    .m_axis_tready(rx_payload_axis_tready),
    .m_axis_tlast(rx_payload_axis_tlast),
    .m_axis_tuser(rx_payload_axis_tuser)
    );


/*
axis_dwidth_converter_256_64 axis_dwidth_converter_256_64_inst(
  aclk(clk_390mhz_int),
  aresetn(rst_390mhz_int),
  s_axis_tvalid(tx_payload_axis_tvalid),
  s_axis_tready(tx_payload_axis_tready),
  s_axis_tdata(tx_payload_axis_tdata),
  s_axis_tkeep(tx_payload_axis_tkeep),
  s_axis_tlast(tx_payload_axis_tlast),
  m_axis_tvalid(tx_payload_axis_tdata_64),
  m_axis_tready(tx_payload_axis_tready_64),
  m_axis_tdata(tx_payload_axis_tdata_64),
  m_axis_tkeep(tx_payload_axis_tkeep_64),
  m_axis_tlast(tx_payload_axis_tlast_64)
);
*/
/*
axis_dwidth_converter_64_256 axis_dwidth_converter_64_256_inst(
  aclk(clk_390mhz_int),
  aresetn(rst_390mhz_int),
  s_axis_tvalid(rx_payload_axis_tdata_64),
  s_axis_tready(rx_payload_axis_tready_64),
  s_axis_tdata(rx_payload_axis_tdata_64),
  s_axis_tkeep(rx_payload_axis_tkeep_64),
  s_axis_tlast(rx_payload_axis_tlast_64),
  m_axis_tvalid(rx_payload_axis_tvalid),
  m_axis_tready(rx_payload_axis_tready),
  m_axis_tdata(rx_payload_axis_tdata),
  m_axis_tkeep(rx_payload_axis_tkeep),
  m_axis_tlast(rx_payload_axis_tlast)
);
*/

// AXI between MAC and Ethernet modules
wire [63:0] rx_axis_tdata;
wire [7:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [63:0] tx_axis_tdata;
wire [7:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;

// Ethernet frame between Ethernet modules and UDP stack
wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [63:0] rx_eth_payload_axis_tdata;
wire [7:0] rx_eth_payload_axis_tkeep;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [63:0] tx_eth_payload_axis_tdata;
wire [7:0] tx_eth_payload_axis_tkeep;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;

/*
assign tx_eth_dest_mac = dest_mac;
assign tx_eth_src_mac = local_mac;
assign tx_eth_type = 16'h800; //hardcoded to be ipv4
*/
 
// IP frame connections
wire rx_ip_hdr_valid;
wire rx_ip_hdr_ready;
wire [47:0] rx_ip_eth_dest_mac;
wire [47:0] rx_ip_eth_src_mac;
wire [15:0] rx_ip_eth_type;
wire [3:0] rx_ip_version;
wire [3:0] rx_ip_ihl;
wire [5:0] rx_ip_dscp;
wire [1:0] rx_ip_ecn;
wire [15:0] rx_ip_length;
wire [15:0] rx_ip_identification;
wire [2:0] rx_ip_flags;
wire [12:0] rx_ip_fragment_offset;
wire [7:0] rx_ip_ttl;
wire [7:0] rx_ip_protocol;
wire [15:0] rx_ip_header_checksum;
wire [31:0] rx_ip_source_ip;
wire [31:0] rx_ip_dest_ip;
wire [63:0] rx_ip_payload_axis_tdata;
wire [7:0] rx_ip_payload_axis_tkeep;
wire rx_ip_payload_axis_tvalid;
wire rx_ip_payload_axis_tready;
wire rx_ip_payload_axis_tlast;
wire rx_ip_payload_axis_tuser;

wire tx_ip_hdr_valid;
wire tx_ip_hdr_ready;
wire [5:0] tx_ip_dscp;
wire [1:0] tx_ip_ecn;
wire [15:0] tx_ip_length;
wire [7:0] tx_ip_ttl;
wire [7:0] tx_ip_protocol;
wire [31:0] tx_ip_source_ip;
wire [31:0] tx_ip_dest_ip;
wire [63:0] tx_ip_payload_axis_tdata;
wire [7:0] tx_ip_payload_axis_tkeep;
wire tx_ip_payload_axis_tvalid;
wire tx_ip_payload_axis_tready;
wire tx_ip_payload_axis_tlast;
wire tx_ip_payload_axis_tuser;

// UDP frame connections
wire rx_udp_hdr_valid;
wire rx_udp_hdr_ready;
wire [47:0] rx_udp_eth_dest_mac;
wire [47:0] rx_udp_eth_src_mac;
wire [15:0] rx_udp_eth_type;
wire [3:0] rx_udp_ip_version;
wire [3:0] rx_udp_ip_ihl;
wire [5:0] rx_udp_ip_dscp;
wire [1:0] rx_udp_ip_ecn;
wire [15:0] rx_udp_ip_length;
wire [15:0] rx_udp_ip_identification;
wire [2:0] rx_udp_ip_flags;
wire [12:0] rx_udp_ip_fragment_offset;
wire [7:0] rx_udp_ip_ttl;
wire [7:0] rx_udp_ip_protocol;
wire [15:0] rx_udp_ip_header_checksum;
wire [31:0] rx_udp_ip_source_ip;
wire [31:0] rx_udp_ip_dest_ip;
wire [15:0] rx_udp_source_port;
wire [15:0] rx_udp_dest_port;
wire [15:0] rx_udp_length;
wire [15:0] rx_udp_checksum;
wire [63:0] rx_udp_payload_axis_tdata;
wire [7:0] rx_udp_payload_axis_tkeep;
wire rx_udp_payload_axis_tvalid;
wire rx_udp_payload_axis_tready;
wire rx_udp_payload_axis_tlast;
wire rx_udp_payload_axis_tuser;

wire tx_udp_hdr_valid;
wire tx_udp_hdr_ready;
wire [5:0] tx_udp_ip_dscp;
wire [1:0] tx_udp_ip_ecn;
wire [7:0] tx_udp_ip_ttl;
wire [31:0] tx_udp_ip_source_ip;
wire [31:0] tx_udp_ip_dest_ip;
wire [15:0] tx_udp_source_port;
wire [15:0] tx_udp_dest_port;
wire [15:0] tx_udp_length;
wire [15:0] tx_udp_checksum;
wire [63:0] tx_udp_payload_axis_tdata;
wire [7:0] tx_udp_payload_axis_tkeep;
wire tx_udp_payload_axis_tvalid;
wire tx_udp_payload_axis_tready;
wire tx_udp_payload_axis_tlast;
wire tx_udp_payload_axis_tuser;

wire [63:0] rx_fifo_udp_payload_axis_tdata;
wire [7:0] rx_fifo_udp_payload_axis_tkeep;
wire rx_fifo_udp_payload_axis_tvalid;
wire rx_fifo_udp_payload_axis_tready;
wire rx_fifo_udp_payload_axis_tlast;
wire rx_fifo_udp_payload_axis_tuser;

wire [63:0] tx_fifo_udp_payload_axis_tdata;
wire [7:0] tx_fifo_udp_payload_axis_tkeep;
wire tx_fifo_udp_payload_axis_tvalid;
wire tx_fifo_udp_payload_axis_tready;
wire tx_fifo_udp_payload_axis_tlast;
wire tx_fifo_udp_payload_axis_tuser;


// IP ports not used
assign rx_ip_hdr_ready = 1;
assign rx_ip_payload_axis_tready = 1;

assign tx_ip_hdr_valid = 0;
assign tx_ip_dscp = 0;
assign tx_ip_ecn = 0;
assign tx_ip_length = 0;
assign tx_ip_ttl = 0;
assign tx_ip_protocol = 8'b11;
assign tx_ip_source_ip = 0;
assign tx_ip_dest_ip = 0;
assign tx_ip_payload_axis_tdata = 0;
assign tx_ip_payload_axis_tkeep = 0;
assign tx_ip_payload_axis_tvalid = 0;
assign tx_ip_payload_axis_tlast = 0;
assign tx_ip_payload_axis_tuser = 0;

// Loop back UDP
//wire match_cond = rx_udp_dest_port == 1234;
wire match_cond = 1'b1; //ignore port
wire no_match = !match_cond;

reg match_cond_reg = 0;
reg no_match_reg = 0;

always @(posedge clk) begin
    if (rst) begin
        match_cond_reg <= 0;
        no_match_reg <= 0;
    end else begin
        if (rx_udp_payload_axis_tvalid) begin
            if ((!match_cond_reg && !no_match_reg) ||
                (rx_udp_payload_axis_tvalid && rx_udp_payload_axis_tready && rx_udp_payload_axis_tlast)) begin
                match_cond_reg <= match_cond;
                no_match_reg <= no_match;
            end
        end else begin
            match_cond_reg <= 0;
            no_match_reg <= 0;
        end
    end
end

//assign tx_udp_hdr_valid = rx_udp_hdr_valid && match_cond;
assign tx_udp_hdr_valid = 1'b1;
assign rx_udp_hdr_ready = (tx_eth_hdr_ready && match_cond) || no_match;
assign tx_udp_ip_dscp = 0;
assign tx_udp_ip_ecn = 0;
assign tx_udp_ip_ttl = 64;
assign tx_udp_ip_source_ip = local_ip;
assign tx_udp_ip_dest_ip = dest_ip;
assign tx_udp_source_port = 0; //ignore right now
assign tx_udp_dest_port = 0; //ignore right now
assign tx_udp_length = 0; // will be overrided
assign tx_udp_checksum = 0; // will be overrided

assign tx_udp_payload_axis_tdata = tx_fifo_udp_payload_axis_tdata;
assign tx_udp_payload_axis_tkeep = tx_fifo_udp_payload_axis_tkeep;
assign tx_udp_payload_axis_tvalid = tx_fifo_udp_payload_axis_tvalid;
assign tx_fifo_udp_payload_axis_tready = tx_udp_payload_axis_tready;
assign tx_udp_payload_axis_tlast = tx_fifo_udp_payload_axis_tlast;
assign tx_udp_payload_axis_tuser = tx_fifo_udp_payload_axis_tuser;

assign rx_fifo_udp_payload_axis_tdata = rx_udp_payload_axis_tdata;
assign rx_fifo_udp_payload_axis_tkeep = rx_udp_payload_axis_tkeep;
assign rx_fifo_udp_payload_axis_tvalid = rx_udp_payload_axis_tvalid && match_cond_reg;
assign rx_udp_payload_axis_tready = (rx_fifo_udp_payload_axis_tready && match_cond_reg) || no_match_reg;
assign rx_fifo_udp_payload_axis_tlast = rx_udp_payload_axis_tlast;
assign rx_fifo_udp_payload_axis_tuser = checksum == 48'hFFFF; // used for checksum validation

// Place first payload byte onto LEDs
reg valid_last = 0;
reg [7:0] led_reg = 0;

always @(posedge clk) begin
    if (rst) begin
        led_reg <= 0;
    end else begin
        valid_last <= tx_udp_payload_axis_tvalid;
        if (tx_udp_payload_axis_tvalid && !valid_last) begin
            led_reg <= tx_udp_payload_axis_tdata;
        end
    end
end

assign user_led_g = ~led_reg[1:0];
assign user_led_r = 1'b1;
assign front_led = 2'b00;

assign qsfp_0_txd_1 = 64'h0707070707070707;
assign qsfp_0_txc_1 = 8'hff;
assign qsfp_0_txd_2 = 64'h0707070707070707;
assign qsfp_0_txc_2 = 8'hff;
assign qsfp_0_txd_3 = 64'h0707070707070707;
assign qsfp_0_txc_3 = 8'hff;

assign qsfp_1_txd_0 = 64'h0707070707070707;
assign qsfp_1_txc_0 = 8'hff;
assign qsfp_1_txd_1 = 64'h0707070707070707;
assign qsfp_1_txc_1 = 8'hff;
assign qsfp_1_txd_2 = 64'h0707070707070707;
assign qsfp_1_txc_2 = 8'hff;
assign qsfp_1_txd_3 = 64'h0707070707070707;
assign qsfp_1_txc_3 = 8'hff;

eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_10g_fifo_inst (
    .rx_clk(qsfp_0_rx_clk_0),
    .rx_rst(qsfp_0_rx_rst_0),
    .tx_clk(qsfp_0_tx_clk_0),
    .tx_rst(qsfp_0_tx_rst_0),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .xgmii_rxd(qsfp_0_rxd_0),
    .xgmii_rxc(qsfp_0_rxc_0),
    .xgmii_txd(qsfp_0_txd_0),
    .xgmii_txc(qsfp_0_txc_0),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .ifg_delay(8'd12)
);

eth_axis_rx #(
    .DATA_WIDTH(64)
)
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tkeep(rx_axis_tkeep),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx #(
    .DATA_WIDTH(64)
)
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tkeep(tx_axis_tkeep),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
);

udp_complete_64
udp_complete_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(rx_eth_hdr_valid),
    .s_eth_hdr_ready(rx_eth_hdr_ready),
    .s_eth_dest_mac(rx_eth_dest_mac),
    .s_eth_src_mac(rx_eth_src_mac),
    .s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // IP frame input
    .s_ip_hdr_valid(tx_ip_hdr_valid),
    .s_ip_hdr_ready(tx_ip_hdr_ready),
    .s_ip_dscp(tx_ip_dscp),
    .s_ip_ecn(tx_ip_ecn),
    .s_ip_length(tx_ip_length),
    .s_ip_ttl(tx_ip_ttl),
    .s_ip_protocol(tx_ip_protocol),
    .s_ip_source_ip(tx_ip_source_ip),
    .s_ip_dest_ip(tx_ip_dest_ip),
    .s_ip_payload_axis_tdata(tx_ip_payload_axis_tdata),
    .s_ip_payload_axis_tkeep(tx_ip_payload_axis_tkeep),
    .s_ip_payload_axis_tvalid(tx_ip_payload_axis_tvalid),
    .s_ip_payload_axis_tready(tx_ip_payload_axis_tready),
    .s_ip_payload_axis_tlast(tx_ip_payload_axis_tlast),
    .s_ip_payload_axis_tuser(tx_ip_payload_axis_tuser),
    // IP frame output
    .m_ip_hdr_valid(rx_ip_hdr_valid),
    .m_ip_hdr_ready(rx_ip_hdr_ready),
    .m_ip_eth_dest_mac(rx_ip_eth_dest_mac),
    .m_ip_eth_src_mac(rx_ip_eth_src_mac),
    .m_ip_eth_type(rx_ip_eth_type),
    .m_ip_version(rx_ip_version),
    .m_ip_ihl(rx_ip_ihl),
    .m_ip_dscp(rx_ip_dscp),
    .m_ip_ecn(rx_ip_ecn),
    .m_ip_length(rx_ip_length),
    .m_ip_identification(rx_ip_identification),
    .m_ip_flags(rx_ip_flags),
    .m_ip_fragment_offset(rx_ip_fragment_offset),
    .m_ip_ttl(rx_ip_ttl),
    .m_ip_protocol(rx_ip_protocol),
    .m_ip_header_checksum(rx_ip_header_checksum),
    .m_ip_source_ip(rx_ip_source_ip),
    .m_ip_dest_ip(rx_ip_dest_ip),
    .m_ip_payload_axis_tdata(rx_ip_payload_axis_tdata),
    .m_ip_payload_axis_tkeep(rx_ip_payload_axis_tkeep),
    .m_ip_payload_axis_tvalid(rx_ip_payload_axis_tvalid),
    .m_ip_payload_axis_tready(rx_ip_payload_axis_tready),
    .m_ip_payload_axis_tlast(rx_ip_payload_axis_tlast),
    .m_ip_payload_axis_tuser(rx_ip_payload_axis_tuser),
    // UDP frame input
    .s_udp_hdr_valid(tx_udp_hdr_valid),
    .s_udp_hdr_ready(tx_udp_hdr_ready),
    .s_udp_ip_dscp(tx_udp_ip_dscp),
    .s_udp_ip_ecn(tx_udp_ip_ecn),
    .s_udp_ip_ttl(tx_udp_ip_ttl),
    .s_udp_ip_source_ip(tx_udp_ip_source_ip),
    .s_udp_ip_dest_ip(tx_udp_ip_dest_ip),
    .s_udp_source_port(tx_udp_source_port),
    .s_udp_dest_port(tx_udp_dest_port),
    .s_udp_length(tx_udp_length),
    .s_udp_checksum(tx_udp_checksum),
    .s_udp_payload_axis_tdata(tx_udp_payload_axis_tdata),
    .s_udp_payload_axis_tkeep(tx_udp_payload_axis_tkeep),
    .s_udp_payload_axis_tvalid(tx_udp_payload_axis_tvalid),
    .s_udp_payload_axis_tready(tx_udp_payload_axis_tready),
    .s_udp_payload_axis_tlast(tx_udp_payload_axis_tlast),
    .s_udp_payload_axis_tuser(tx_udp_payload_axis_tuser),
    // UDP frame output
    .m_udp_hdr_valid(rx_udp_hdr_valid),
    .m_udp_hdr_ready(rx_udp_hdr_ready),
    .m_udp_eth_dest_mac(rx_udp_eth_dest_mac),
    .m_udp_eth_src_mac(rx_udp_eth_src_mac),
    .m_udp_eth_type(rx_udp_eth_type),
    .m_udp_ip_version(rx_udp_ip_version),
    .m_udp_ip_ihl(rx_udp_ip_ihl),
    .m_udp_ip_dscp(rx_udp_ip_dscp),
    .m_udp_ip_ecn(rx_udp_ip_ecn),
    .m_udp_ip_length(rx_udp_ip_length),
    .m_udp_ip_identification(rx_udp_ip_identification),
    .m_udp_ip_flags(rx_udp_ip_flags),
    .m_udp_ip_fragment_offset(rx_udp_ip_fragment_offset),
    .m_udp_ip_ttl(rx_udp_ip_ttl),
    .m_udp_ip_protocol(rx_udp_ip_protocol),
    .m_udp_ip_header_checksum(rx_udp_ip_header_checksum),
    .m_udp_ip_source_ip(rx_udp_ip_source_ip),
    .m_udp_ip_dest_ip(rx_udp_ip_dest_ip),
    .m_udp_source_port(rx_udp_source_port),
    .m_udp_dest_port(rx_udp_dest_port),
    .m_udp_length(rx_udp_length),
    .m_udp_checksum(rx_udp_checksum),
    .m_udp_payload_axis_tdata(rx_udp_payload_axis_tdata),
    .m_udp_payload_axis_tkeep(rx_udp_payload_axis_tkeep),
    .m_udp_payload_axis_tvalid(rx_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(rx_udp_payload_axis_tready && !(rx_fifo_udp_payload_axis_tlast && wait_checksum)),
    .m_udp_payload_axis_tlast(rx_udp_payload_axis_tlast),
    .m_udp_payload_axis_tuser(),
    // Status signals
    .ip_rx_busy(),
    .ip_tx_busy(),
    .udp_rx_busy(),
    .udp_tx_busy(),
    .ip_rx_error_header_early_termination(),
    .ip_rx_error_payload_early_termination(),
    .ip_rx_error_invalid_header(),
    .ip_rx_error_invalid_checksum(),
    .ip_tx_error_payload_early_termination(),
    .ip_tx_error_arp_failed(),
    .udp_rx_error_header_early_termination(),
    .udp_rx_error_payload_early_termination(),
    .udp_tx_error_payload_early_termination(),
    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(1'b0)
);

always  @ (posedge clk )
begin
    checksum_last_step <= 0;
    wait_checksum <= 1;
    checksum_header <= endian_swap(rx_udp_ip_source_ip[31:16])+ endian_swap(rx_udp_ip_source_ip[15:0]) + 
                        endian_swap(rx_udp_ip_dest_ip[31:16]) + endian_swap(rx_udp_ip_dest_ip[15:0]) + endian_swap(17) + endian_swap(rx_udp_length) +
                      endian_swap(rx_udp_dest_port) + endian_swap(rx_udp_source_port) + endian_swap(rx_udp_length) + endian_swap(rx_udp_checksum);
    if (rst || !wait_checksum) begin
        checksum <= 0;
    end else if (rx_fifo_udp_payload_axis_tvalid && rx_fifo_udp_payload_axis_tready) begin
        checksum <= checksum_next;
        if(rx_fifo_udp_payload_axis_tlast) begin
            checksum_last_step <= 1;
        end
        if (checksum_last_step) begin
            wait_checksum <= 0;
        end
    end
end

function [15:0] endian_swap;
    input [15:0] data; 
    begin
        endian_swap = {{data[07:00]},{data[15:08]}};
    end
endfunction

always @* 
begin

    //checksum_next = checksum + endian_swap(rx_udp_payload_axis_tdata[15:0]) + endian_swap(rx_udp_payload_axis_tdata[31:16]) + 
    //    endian_swap(rx_udp_payload_axis_tdata[47:32]) + endian_swap(rx_udp_payload_axis_tdata[63:48]);

    if (checksum_last_step)  begin
        checksum_next = checksum + checksum_header;
        checksum_next = (checksum_next >> 16) + (checksum_next & 48'hffff);
        checksum_next = checksum_next+(checksum_next >> 16);
        checksum_next = checksum_next & 48'hffff;
    end else begin
        checksum_next = checksum + rx_udp_payload_axis_tdata[15:0] + rx_udp_payload_axis_tdata[31:16] + 
        rx_udp_payload_axis_tdata[47:32] + rx_udp_payload_axis_tdata[63:48];    
    end
    
end
axis_fifo #(
    .DEPTH(8192),
    .DATA_WIDTH(64),
    .KEEP_ENABLE(1),
    .KEEP_WIDTH(8),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(1),
    .USER_WIDTH(1),
    .FRAME_FIFO(0)
)
rx_payload_fifo (
    .clk(clk),
    .rst(rst),

    // AXI input
    .s_axis_tdata(rx_fifo_udp_payload_axis_tdata),
    .s_axis_tkeep(rx_fifo_udp_payload_axis_tkeep),
    .s_axis_tvalid(rx_fifo_udp_payload_axis_tvalid && !(rx_fifo_udp_payload_axis_tlast && wait_checksum)),
    .s_axis_tready(rx_fifo_udp_payload_axis_tready),
    .s_axis_tlast(rx_fifo_udp_payload_axis_tlast),
    .s_axis_tid(8'b0),
    .s_axis_tdest(8'b0),
    .s_axis_tuser(rx_fifo_udp_payload_axis_tuser),

    // AXI output
    .m_axis_tdata(rx_payload_axis_tdata_64),
    .m_axis_tkeep(rx_payload_axis_tkeep_64),
    .m_axis_tvalid(rx_payload_axis_tvalid_64),
    .m_axis_tready(rx_payload_axis_tready_64),
    .m_axis_tlast(rx_payload_axis_tlast_64),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(rx_checksum_OK_64),

    // Status
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);

axis_fifo #(
    .DEPTH(8192),
    .DATA_WIDTH(64),
    .KEEP_ENABLE(1),
    .KEEP_WIDTH(8),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(0),
    .USER_WIDTH(1),
    .FRAME_FIFO(0)
)
tx_payload_fifo (
    .clk(clk),
    .rst(rst),

    // AXI input
    .s_axis_tdata(tx_payload_axis_tdata_64),
    .s_axis_tkeep(tx_payload_axis_tkeep_64),
    .s_axis_tvalid(tx_payload_axis_tvalid_64),
    .s_axis_tready(tx_payload_axis_tready_64),
    .s_axis_tlast(tx_payload_axis_tlast_64),
    .s_axis_tid(8'b0),
    .s_axis_tdest(8'b0),
    .s_axis_tuser(1'b0),

    // AXI output
    .m_axis_tdata(tx_fifo_udp_payload_axis_tdata),
    .m_axis_tkeep(tx_fifo_udp_payload_axis_tkeep),
    .m_axis_tvalid(tx_fifo_udp_payload_axis_tvalid),
    .m_axis_tready(tx_fifo_udp_payload_axis_tready),
    .m_axis_tlast(tx_fifo_udp_payload_axis_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(tx_fifo_udp_payload_axis_tuser),

    // Status
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);

endmodule

`resetall
