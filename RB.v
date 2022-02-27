`timescale 1ns / 1ps

module RB(
        input clk,reset,WE,
        input [7:0] InA, InB,CUconst,ALUout,
        input [2:0] InMuxAdd,
        input [3:0] RegAdd,OutMuxAdd,
        output [7:0] Out,ALUinA,ALUinB
    );
    
    wire [15:0] EN;
    wire [7:0] Rin,RegOut;
    wire [7:0] Rout [15:0];
    
fourbysixteen_decoder Decoder(WE,RegAdd,EN);
threebyeight_mux#(8) Multiplexer1 (InA,InB,CUconst,ALUout,RegOut,RegOut,RegOut,RegOut,InMuxAdd,Rin);
Register Registers0 (clk,EN[0],reset,Rin,Rout[0]);
Register Registers1 (clk,EN[1],reset,Rin,Rout[1]);
Register Registers2 (clk,EN[2],reset,Rin,Rout[2]);
Register Registers3 (clk,EN[3],reset,Rin,Rout[3]);
Register Registers4 (clk,EN[4],reset,Rin,Rout[4]);
Register Registers5 (clk,EN[5],reset,Rin,Rout[5]);
Register Registers6 (clk,EN[6],reset,Rin,Rout[6]);
Register Registers7 (clk,EN[7],reset,Rin,Rout[7]);
Register Registers8 (clk,EN[8],reset,Rin,Rout[8]);
Register Registers9 (clk,EN[9],reset,Rin,Rout[9]);
Register Registers10 (clk,EN[10],reset,Rin,Rout[10]);
Register Registers11 (clk,EN[11],reset,Rin,Rout[11]);
Register Registers12 (clk,EN[12],reset,Rin,Rout[12]);
Register Registers13 (clk,EN[13],reset,Rin,Rout[13]);
Register Registers14 (clk,EN[14],reset,Rin,Rout[14]);
Register Registers15 (clk,EN[15],reset,Rin,Rout[15]);
fourbysixteen_mux #(8) Multiplexer2 (Rout[0],Rout[1],Rout[2],Rout[3],Rout[4],Rout[5],Rout[6],Rout[7],Rout[8],Rout[9],Rout[10],Rout[11],Rout[12],Rout[13],Rout[14],Rout[15],OutMuxAdd,RegOut);  
assign Out =  Rout[0];
assign ALUinA = Rout[1];
assign ALUinB = Rout[2];
endmodule
