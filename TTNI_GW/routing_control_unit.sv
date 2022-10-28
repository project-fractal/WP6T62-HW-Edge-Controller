`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2020 01:37:23 PM
// Design Name: 
// Module Name: routing_control_unit
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


module routing_control_unit#(parameter  nodes=4)
                           ( input clk,
                             input [23:0]destination_address,
                             input  [3:0]source_id,
                             
                             output reg [27:0]routing_opcode
                            );
                             
reg [27:0] rauting_table_memory[64:1];                             

//read memory 
initial
    begin
        $readmemb("routingtable.mem",rauting_table_memory);
    end

always@(posedge clk)
begin
routing_opcode<=rauting_table_memory[destination_address+(source_id*nodes)+1];
end                             



endmodule
