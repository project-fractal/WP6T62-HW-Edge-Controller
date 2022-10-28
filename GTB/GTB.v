`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Name : Nambinina 
// Date : 01-OCt-2021
// Company : University of Siegen 
// Description : This is top module of Global Time Base, GTB is used to synchronized each resources, even if using different clock frequency
//////////////////////////////////////////////////////////////////////////////////


module GTB( 
            // input port 
            input wire clk,
            input wire reset_n,
            input wire mtclk,
            // output port 
            output wire[63:0]TimeCnt 
            );

  
Clock   Global(

    .clk(clk),          
    .reset_n(reset_n),      
    .mtclk(mtclk),
    .SetTimeVal(0),   
    .NewTimeVal(0),   
    .ReconfInst(0),   
	.TimeCnt(TimeCnt)		
);

endmodule

