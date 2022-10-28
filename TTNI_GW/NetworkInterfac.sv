`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/21/2020 03:18:31 PM
// Design Name:
// Module Name: NetworkInterface
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module TT_NetworkInterface #(
                            parameter integer C_S00_AXI_ID_WIDTH = 1,      
                            parameter integer C_S00_AXI_DATA_WIDTH = 32,  
                            parameter integer C_S00_AXI_ADDR_WIDTH = 32,  
                            parameter integer C_S00_AXI_AWUSER_WIDTH = 0,  
                            parameter integer C_S00_AXI_ARUSER_WIDTH = 0,  
                            parameter integer C_S00_AXI_WUSER_WIDTH = 0,  
                            parameter integer C_S00_AXI_RUSER_WIDTH = 0,  
                            parameter integer C_S00_AXI_BUSER_WIDTH = 0,  
                           
                             parameter FLIT_DATA_WIDTH = 32,
                             parameter FLIT_TYPE_WIDTH = 2,
                             parameter FLIT_WIDTH = (FLIT_DATA_WIDTH + FLIT_TYPE_WIDTH),
                             parameter VCHANNELS = 1,
                             parameter  nodes=4,
                             parameter my_id=0
                             )
                             (
                             
                             input [63:0]GTB,
                              // Router side source
                              output   [FLIT_WIDTH-1:0] flit_source,
                              output  [VCHANNELS-1:0]  valid_source,
                              input [VCHANNELS-1:0] ready_source,
                              
                              // redundant source 
                              output   [FLIT_WIDTH-1:0] flit_source_r,
                              output  [VCHANNELS-1:0]  valid_source_r,
                              input [VCHANNELS-1:0] ready_source_r,
                              
                             
                             
                              //Router side sink
                              input [FLIT_WIDTH-1:0] flit_sink,
                              input [VCHANNELS-1:0] valid_sink,
                              output   [VCHANNELS-1:0] ready_sink,
                              
                              //redundant sink
                               input [FLIT_WIDTH-1:0] flit_sink_r,
                              input [VCHANNELS-1:0] valid_sink_r,
                              output   [VCHANNELS-1:0] ready_sink_r,
                             
                              input wire  clk,
                              input wire reset_globle,  
                              //input wire [3:0]source_id,
                              //core side
                              output pIntToCore,
                             
//                              input wire  s00_axi_aclk,                                      
//                              input wire  s00_axi_aresetn,                                            
                              input wire [C_S00_AXI_ID_WIDTH-1 : 0] s_axi_core_awid         ,
                              input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]s_axi_core_awaddr      ,
                              input wire [7 : 0] s_axi_core_awlen                           ,
                              input wire [2 : 0] s_axi_core_awsize                          ,
                              input wire [1 : 0] s_axi_core_awburst                         ,
                              input wire s_axi_core_awlock                                  ,
                              input wire s_axi_core_awcache                                 ,
                              input wire s_axi_core_awprot                                  ,
                              input wire s_axi_core_awqos                                   ,
                              input wire s_axi_core_awregion                                ,
                              input wire s_axi_core_awuser                                  ,
                              input wire s_axi_core_awvalid                                 ,
                              output wire s_axi_core_awready                                ,
                              input wire [C_S00_AXI_DATA_WIDTH-1 : 0]s_axi_core_wdata       ,
                              input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s_axi_core_wstrb  ,    
                              input wire  s_axi_core_wlast                                  ,
                              input wire [C_S00_AXI_WUSER_WIDTH-1 : 0]s_axi_core_wuser      ,
                              input wire  s_axi_core_wvalid                                 ,
                              output wire  s_axi_core_wready                                ,
                              output wire [C_S00_AXI_ID_WIDTH-1 : 0] s_axi_core_bid         ,
                              output wire [1 : 0]s_axi_core_bresp                           ,
                              output wire [C_S00_AXI_BUSER_WIDTH-1 : 0] s_axi_core_buser    ,  
                              output wire  s_axi_core_bvalid                                ,
                              input wire  s_axi_core_bready                                 ,
                              input wire [C_S00_AXI_ID_WIDTH-1 : 0] s_axi_core_arid         ,
                              input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s_axi_core_araddr     ,
                              input wire [7 : 0] s_axi_core_arlen                           ,
                              input wire [2 : 0] s_axi_core_arsize                          ,
                              input wire [1 : 0] s_axi_core_arburst                         ,
                              input wire  s_axi_core_arlock                                 ,
                              input wire [3 : 0] s_axi_core_arcache                         ,
                              input wire [2 : 0] s_axi_core_arprot                          ,
                              input wire [3 : 0] s_axi_core_arqos                           ,
                              input wire [3 : 0] s_axi_core_arregion                        ,
                              input wire [C_S00_AXI_ARUSER_WIDTH-1 : 0] s_axi_core_aruser   ,  
                              input wire  s_axi_core_arvalid                                ,
                              output wire s_axi_core_arready                                ,
                              output wire [C_S00_AXI_ID_WIDTH-1 : 0] s_axi_core_rid         ,
                              output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s_axi_core_rdata     ,  
                              output wire [1 : 0] s_axi_core_rresp                          ,
                              output wire  s_axi_core_rlast                                 ,
                              output wire [C_S00_AXI_RUSER_WIDTH-1 : 0] s_axi_core_ruser    ,  
                              output wire  s_axi_core_rvalid                                ,
                              input wire  s_axi_core_rready   ,
                              input wire sel        
                              ,
                              input  wire tx_adaptiveRMI                      
 );

wire [27:0]routing_opcode;
wire trigger;  
wire trigger2;    
wire [(FLIT_DATA_WIDTH - 1):0] i_source_data_in;    
wire out_rd_en;


wire  portid_valid;
wire  [7:0] sink_portid;
wire  write_en;
wire  [31:0] sink_dataout;
wire [31:0] sink_dataout_r;
wire  [31:0]destination_address;
wire  sink_terminate;
wire[9:0] msglen;
wire [31:0]sink_dataout_ttel;
wire [FLIT_WIDTH-1:0] a1;
//wire [31:0]latency;
     
routing_control_unit#(.nodes(nodes)) rcu (.clk(clk),
                                          .destination_address(destination_address[31:8]),
                                          .routing_opcode(routing_opcode),
                                          .source_id(my_id));
         
         
             
             
 
                                   
 
Source_FSM u_source_one(.flit                     (a1),
                        .valid                    (valid_source),
                         // Inputs
                        .clk                      (clk),
                        .rst_source                      (reset_globle),
                        .ready                    (ready_source),
                        .msglen(msglen),
                        .routing_opcode(routing_opcode),
                        .Number_of_flits(16),
                        .active_source(active_source),
                        .Tx_Traffic_id(3),
                        .i_trigger(trigger),
                        .i_trigger2(trigger2),
                        .i_source_data_in(i_source_data_in),
                        .out_rd_en(out_rd_en),
                        .Dest_port_id(destination_address[7:0]),
                        .GTB(GTB)
                         );
 // REDUNDANT SOURCE FSM
 
 Source_FSM u_source_r(.flit                     (flit_source_r),
                        .valid                    (valid_source_r),
                         // Inputs
                        .clk                      (clk),
                        .rst_source                      (reset_globle),
                        .ready                    (ready_source_r),
                        .msglen(msglen),
                        .routing_opcode(routing_opcode),
                        .Number_of_flits(16),
                        .active_source(active_source),
                        .Tx_Traffic_id(3),
                        .i_trigger(trigger),
                        .i_trigger2(trigger2),
                        .i_source_data_in(i_source_data_in),
                        .out_rd_en(),
                        .Dest_port_id(destination_address[7:0]),
                        .GTB(GTB)
                         );
                                       
Sink_FSM u_sink_one(// Outputs
                     .ready                      (ready_sink),
                     .clk                        (clk),
                     .rst_sink                        (reset_globle),
                     .flit                       (flit_sink),
                     .valid                      (valid_sink),
                     .portid_valid(),        
                     .sink_portid(),  
                     .write_en(),            
                     .sink_dataout(sink_dataout),
                     .sink_terminate(),
                     .GTB(GTB)      
                     );
                     
 // fault injection
 
 SingleFault fault(
                   .originalSignal(a1) ,
                   .outputSig (flit_source)
    );   
                     
// redundant sink                     

Sink_FSM u_sink_r(// Outputs
                     .ready                      (ready_sink_r),
                     .clk                        (clk),
                     .rst_sink                        (reset_globle),
                     .flit                       (flit_sink_r),
                     .valid                      (valid_sink_r),
                     .portid_valid(portid_valid),        
                     .sink_portid(sink_portid),  
                     .write_en(write_en),            
                     .sink_dataout(sink_dataout_r),
                     .sink_terminate(sink_terminate),
                     .GTB(GTB)      
                     );           
                     
                     
                     
// compare the messages from two redundant sink                
comp comparator(
                    .in_1 (sink_dataout),
                    .in_2 (sink_dataout_r),
                    .out_1(sink_dataout_ttel) //, error

    );
                   
 TTEL #(.MY_ID(my_id))ttel(
 
 . tx_adaptiveRMI (tx_adaptiveRMI),
       
.sel (sel),
.clk (clk),
//.latency(latency),
.TimeCntIn       (GTB),
.reset_n (~reset_globle),
.pIntToCore          ( pIntToCore),
// connection to source
.out_rd_en(out_rd_en),
.trigger   (trigger),
.trigger2  (trigger2),
   .source_datain(i_source_data_in),
   .destination_address(destination_address),
   .msglen(msglen),

// connection to sink
        .sink_dataout         (sink_dataout_ttel),  
        .sink_portid          (sink_portid),  
        .portid_valid         (portid_valid),
        .write_en             (write_en),      
        .sink_terminate       (sink_terminate),
 
  // connection to AXI
//   .s_axi_core_aclk(s00_axi_aclk),
//       .s_axi_core_aresetn(s00_axi_aresetn),
.s_axi_core_awid        (s_axi_core_awid   ),    
        .s_axi_core_awaddr      (s_axi_core_awaddr  ),    
        .s_axi_core_awlen       (s_axi_core_awlen   ),    
        .s_axi_core_awsize      (s_axi_core_awsize  ),    
        .s_axi_core_awburst     (s_axi_core_awburst ),    
        .s_axi_core_awlock      (s_axi_core_awlock  ),    
        .s_axi_core_awcache     (s_axi_core_awcache ),    
        .s_axi_core_awprot      (s_axi_core_awprot  ),    
        .s_axi_core_awqos       (s_axi_core_awqos   ),    
        .s_axi_core_awregion    (s_axi_core_awregion),    
        .s_axi_core_awuser      (s_axi_core_awuser  ),    
        .s_axi_core_awvalid     (s_axi_core_awvalid ),    
        .s_axi_core_awready     (s_axi_core_awready ),    
        .s_axi_core_wdata       (s_axi_core_wdata   ),    
        .s_axi_core_wstrb       (s_axi_core_wstrb   ),    
        .s_axi_core_wlast       (s_axi_core_wlast   ),    
        .s_axi_core_wuser       (s_axi_core_wuser   ),    
        .s_axi_core_wvalid      (s_axi_core_wvalid  ),    
        .s_axi_core_wready      (s_axi_core_wready  ),    
        .s_axi_core_bid         (s_axi_core_bid     ),    
        .s_axi_core_bresp       (s_axi_core_bresp   ),    
        .s_axi_core_buser       (s_axi_core_buser   ),    
        .s_axi_core_bvalid      (s_axi_core_bvalid  ),    
        .s_axi_core_bready      (s_axi_core_bready  ),    
        .s_axi_core_arid        (s_axi_core_arid    ),    
        .s_axi_core_araddr      (s_axi_core_araddr  ),    
        .s_axi_core_arlen       (s_axi_core_arlen   ),    
        .s_axi_core_arsize      (s_axi_core_arsize  ),    
        .s_axi_core_arburst     (s_axi_core_arburst ),    
        .s_axi_core_arlock      (s_axi_core_arlock  ),    
        .s_axi_core_arcache     (s_axi_core_arcache ),    
        .s_axi_core_arprot      (s_axi_core_arprot  ),    
        .s_axi_core_arqos       (s_axi_core_arqos   ),    
        .s_axi_core_arregion    (s_axi_core_arregion),    
        .s_axi_core_aruser      (s_axi_core_aruser  ),    
        .s_axi_core_arvalid     (s_axi_core_arvalid ),    
        .s_axi_core_arready     (s_axi_core_arready ),    
        .s_axi_core_rid         (s_axi_core_rid     ),    
        .s_axi_core_rdata       (s_axi_core_rdata   ),    
        .s_axi_core_rresp       (s_axi_core_rresp   ),    
        .s_axi_core_rlast       (s_axi_core_rlast   ),    
        .s_axi_core_ruser       (s_axi_core_ruser   ),    
        .s_axi_core_rvalid      (s_axi_core_rvalid  ),    
        .s_axi_core_rready      (s_axi_core_rready  )    
);                    
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                     
                                     


endmodule

