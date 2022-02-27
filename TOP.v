`timescale 1ns / 1ps

module TOP(
    input clk,reset,Start,
    input[7:0] InA,InB,
    output Busy,
    output [7:0] Out
    );
wire CO,Z,WE;
wire[1:0] InsSel;
wire[2:0] InMuxAdd;
wire[3:0] OutMuxAdd,RegAdd;
wire[7:0] CUconst,ALUinA,ALUinB,ALUout;

CU CU (clk,reset,Start,CO,Z,Busy,WE,InsSel,InMuxAdd,OutMuxAdd,RegAdd,CUconst);   
ALU ALU (ALUinA,ALUinB,InsSel,ALUout,CO,Z);
RB RB (clk,reset,WE,InA, InB,CUconst,ALUout,InMuxAdd,RegAdd,OutMuxAdd,Out,ALUinA,ALUinB);
endmodule
