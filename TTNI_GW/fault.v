`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2021 03:26:21 PM
// Design Name: 
// Module Name: SingleFault
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


module SingleFault(
originalSignal , outputSig
    );
    input [33:0]originalSignal;
    output [33:0]outputSig;
   
   assign outputSig = {originalSignal[33:32],4'b0010,originalSignal[27:0]};
endmodule
