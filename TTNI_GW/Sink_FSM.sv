
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/16/2020 09:35:02 AM
// Design Name:
// Module Name: Sink_FSM
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

module Sink_FSM #(VCHANNELS = 1,FLIT_DATA_WIDTH = 32, FIFO_DEPTH = 1024,msg_length=1024,contral_status_reg_memory_length=40,start_wr_address = msg_length+contral_status_reg_memory_length,end_wr_address = ((msg_length*2)+contral_status_reg_memory_length)-1,FLIT_TYPE_WIDTH = 2,FLIT_WIDTH = (FLIT_DATA_WIDTH + FLIT_TYPE_WIDTH))
 (output reg [VCHANNELS-1:0] ready,
  output  reg[FLIT_DATA_WIDTH-1:0] read_data,
  output reg[FLIT_DATA_WIDTH-1:0] wr_data,
  output reg wr_en,
  output reg[FLIT_DATA_WIDTH-1:0] sink_active,
  output reg [31:0] count,
  output reg [31:0]Rx_new_msg_status,
 
  output reg portid_valid,
  output reg [7:0] sink_portid,
  output reg write_en,
  output reg [31:0] sink_dataout,
  output reg  sink_terminate,
 
  input clk,
  input rst_sink,
  input [FLIT_WIDTH-1:0] flit,
  input [VCHANNELS-1:0]      valid,
  input [31:0]Rx_ready,
  input [63:0]GTB,
  output reg [31:0]latency
 );
 //  reg[7:0] sink_portid_reg;
   reg [31:0] count1;
   reg [31:0] source_time_stamp;
   integer state,clkcount;
   reg flag;
   reg flag_term;//by chen
   reg id_flag;
 
    // The state machine is triggered on the positive edge
    always @(posedge clk) begin
    clkcount <= clkcount + 1;

      if (rst_sink) begin
         state <= 0;
         clkcount <= 0;
       
         flag<=0;
      end else begin  
         
          case(state)  
            0: begin
               
                 //Rx_new_msg_status<=0;
                 //ready<=0;  
                 flag<=0;        
                 read_data<=0;        
                 wr_en<=0;            
                 //sink_active<=0;      
                 wr_data<= 0;                
                 state <= 1;
                 clkcount<=0;
                 count<=0;
                 id_flag<=0;
                // sink_terminate<=0;
                 
               end  
            1: begin
               // Wait for flit
               if (valid)
                begin
                 if (flit[FLIT_WIDTH-1:FLIT_WIDTH-2]==1)
                     begin
                      count<= count + 1;
                     end
                 else if( flit[FLIT_WIDTH-1:FLIT_WIDTH-2]==0)
                     begin            
                         count<= count + 1;
                         $display("Received %x", flit);
                         state<= 1;
                         
                     end
                 else if(flit[FLIT_WIDTH-1:FLIT_WIDTH-2]==2)
                     begin
                         $display("Received %x", flit);
                         state<= 0;//1
                         count <= 0;
                         flag<=1;
                         id_flag<=0;
                         latency<=source_time_stamp;
                     end
                 end
               else
                   begin
                        count <= 0;
                        flag<=0;
                   end
            end
            2: begin
                if (Rx_ready==1)
                  begin
                    state <= 1;
                    count<=0;
                  end
                else
                   begin
                    count<=0;
                   end  
               end
          endcase // case (state)
       end
       end
     
     
     
     //
     always @(negedge clk) begin
        if(count==2)
            begin
            source_time_stamp<=flit;
            end
        else if(count==120)
            begin
           //  Do nothing
             
            end    
     end
     
   
   
     
     
     
     
 
    // This is the combinational part
    always @(negedge clk) begin
       // Default
       //ready<= 0;
 
       case (state)
         1: begin
                // Set ready
                ready<= 1;    
                Rx_new_msg_status<=0;
                sink_active<=1;
            end
         2: begin  
            // Set ready
                ready<= 0;
                Rx_new_msg_status<=1;
                sink_active<=0;
            end  
       endcase
    end
//    always@(*)
//    begin
//        if( flit[FLIT_WIDTH-1:FLIT_WIDTH-2]==0)
//            if(id_flag==0)
//            begin
//            id_flag<=1;
//            sink_portid<=flit[4:0];
//            end
//    end
     always@(negedge clk or posedge rst_sink)
     begin
     if(rst_sink) begin
        portid_valid<='0;
        sink_portid<='ha;
      end
      else  if(count==0)
          begin        
            portid_valid<='0;
            sink_portid<='ha;
        end
        else if(count==1) begin
             portid_valid<=1;
             sink_portid<=flit[4:0];
        end
        else
             portid_valid<='0;
     end  
     always @(posedge clk or posedge rst_sink) begin
     if(rst_sink)
     begin
      //  sink_portid<='ha;
      //  sink_portid_reg<='ha;
        sink_terminate<=0;
     end
       
     else  if(count==0)
          begin
          if(count1==2)
            begin
                 write_en<=1;
                 sink_dataout<=latency;
               
             end
            else if(count1==20)
            begin
                write_en<=1;
                 sink_terminate<=1;
               
             end
             else begin
                sink_terminate<=0;
               // sink_portid<='ha;
                         
                write_en<=0;            
                sink_dataout<='z;
                //sink_terminate<=1;
                end      
            end
       else if (count ==1)begin
               write_en <=0;
               sink_dataout <='z;
       end
       else if(count==2) begin
              write_en<=0;
             sink_dataout<='z;
             
        end
       else if(count==121) begin
            // write_en<=1;
            // sink_dataout<=latency;
             
        end
             
       else
        begin
          
                write_en<=1;
                sink_dataout<=flit[31:0]; //******************************
                       
        end  
        end    
       
       
//        //by chen
       always@ (posedge clk or posedge rst_sink)
       begin
       if(rst_sink)
             count1<=32'd25;
       else if(flag)
            begin
                count1<=32'b0;
            end
            else if(count1==25)
            begin
                count1<=count1;
            end
         else
            begin
            count1=count1+1;
            end
       end

endmodule // sink

