module Source_FSM#(parameter WIDTH = 32,msg_length=1024,contral_status_reg_memory_length=40,FLIT_DATA_WIDTH = 32,VCHANNELS = 1,start_rd_address = contral_status_reg_memory_length,end_rd_address = contral_status_reg_memory_length+msg_length,FLIT_TYPE_WIDTH = 2,FLIT_WIDTH = (FLIT_DATA_WIDTH + FLIT_TYPE_WIDTH))
 ( output reg [FLIT_WIDTH-1:0] flit,
   output reg [VCHANNELS-1:0]  valid,
   // Inputs
   input clk,
   
   input rst_source,
   input [VCHANNELS-1:0]       ready,
   input i_trigger,
   input i_trigger2,
   input[9:0] msglen,
   input wire [(FLIT_DATA_WIDTH - 1):0] i_source_data_in,
   input [27:0]routing_opcode,
   input [31:0]Number_of_flits,
   output reg [FLIT_DATA_WIDTH-1:0]active_source,
   output reg out_rd_en,
   output reg [31:0] count,
   input [FLIT_DATA_WIDTH-1:0]Tx_Traffic_id,
   input [7:0]Dest_port_id,
   input [63:0]GTB
   //input [3:0]source_id
   );
   reg [31:0] store_GTB;
   reg flag;
   integer clkcount,clkcount_t,clkcount_negedge;
   integer state=0;
   reg[9:0] msg_reg;
   reg[1:0] i_trigger2_reg;
   initial
    begin
    count=0;
    clkcount=0;
    clkcount_t=0;
    out_rd_en=0;
    end
 always@(posedge clk or posedge rst_source)
 begin
    if(rst_source)    
         i_trigger2_reg<=2'b0;          
        else if(i_trigger2)
        begin
           i_trigger2_reg[0]<=1;
           store_GTB <= GTB[38:6];
        end
     else
         i_trigger2_reg<={i_trigger2_reg[0],1'b0};
 end
  always@(posedge clk or posedge rst_source)
 begin
    if(rst_source)    
         msg_reg<=10'h1;          
        else if(i_trigger2_reg[1])
           msg_reg<=msglen;
     else
         msg_reg<=msg_reg;
 end

   always @(posedge clk) begin  
      clkcount<=clkcount+1;
      clkcount_t<=clkcount_t+1;
      if (rst_source) begin
         state <= 0;      
         //count<=start_rd_address;
               end else begin
         // The state machine
         case(state)
           0: begin
              // Wait for transfer signal to high
              if (i_trigger==1)  //clkcount_t i_trigger
                  begin
                     state <= 4;
                     active_source<=1;
                     clkcount<=0;
                  end
              else
                     active_source<=0;
              end
           1: begin        
              if (ready)
              begin
                        state <= 2;
                      //  out_rd_en<=0;
              end
              end
           
           2: begin  
              if (count<msg_reg +1) //message lenth
                  begin
                     out_rd_en<=1;
                     state <= 2;
                  end
              else
                     state <= 3;
                     clkcount <= 0;
              end
           3: begin
              if (clkcount_negedge==1)
                   begin
                        state <= 0;
                        clkcount<=0;
                        out_rd_en<=0;
                   end  
              end
           4: begin
              if (clkcount==1)
              begin
                        state <= 1;
                        clkcount<=0;
              end
              end  
         endcase // case (state)
      end
   end

   // This is the combinational part
   always @(negedge clk) begin
     clkcount_negedge<=clkcount_negedge+1;
      case (state)
            0:begin
             valid <= 0;
             flit <= 'x;
             clkcount_negedge<=0;
             count<=0;
             end
             //state 1  Sends Header flit
            1:begin            
               valid <= 1;
               flit <= {2'b01,Tx_Traffic_id[3:0],routing_opcode[27:0]};//dest_address is nothing a routing opcode
               clkcount_negedge<=0;
              end
              //state 2  Sends body flits
            2:begin
               if(count==0)
                begin
                valid <= 1;
                flit <= {2'b00,Dest_port_id };//Dest_port_id , 32'b1000
                count <= count + 1;
                clkcount_negedge<=0;
                end
               else if(count==1)
               begin
                valid <= 1;
                flit <= {2'b00,store_GTB };//Dest_port_id , 32'b1000
                count <= count + 1;
                clkcount_negedge<=0;
               
               end
               
               
               else
                begin
                    valid <= 1;
                    flit <= {2'b00,i_source_data_in};
                    count <= count + 1;
                    clkcount_negedge<=0;
                end
             end
              //state 3  Sends last flit
            3: begin
               valid <= 1;
               flit <= {2'b10,i_source_data_in};//aa changes
               end
      endcase
   end  
endmodule // source_FSM

