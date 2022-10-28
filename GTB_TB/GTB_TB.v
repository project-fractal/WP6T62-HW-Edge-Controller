`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2022 10:12:08 AM
// Design Name: 
// Module Name: GTB_TB
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


module GTB_TB(

    );
    
   reg  clk;
   reg  reset_n;
   reg  mtclk;
   wire [63:0]TimeCnt; 
    
    GTB DUT( 
             clk,
             reset_n,
             mtclk,
             TimeCnt 
            );       
            
     initial
       begin
         clk =0;
         reset_n =0;
         mtclk = 0;
         #10 
         reset_n = 1;
       end 
     
     always 
       begin
         #5 clk = ! clk;
       end 
       
     always 
       begin
         #40 mtclk = ! mtclk ;
       end 
endmodule
