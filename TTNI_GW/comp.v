`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2021 10:26:54 AM
// Design Name: 
// Module Name: comp
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


module comp(
in_1 , in_2, out_1 //, error

    );
input [31:0]in_1;
input [31:0] in_2;
output [31:0] out_1;
//output error;

assign out_1 = in_2; //out_1 = (in_1 ==in_2)?in_1 : in_2;
//assign error  = (in_1 ==in_2)?0:1;

endmodule
