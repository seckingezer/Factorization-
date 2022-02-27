`timescale 1ns / 1ps

module CU(
input clk,reset,Start,CO,Z,
output reg Busy,WE,
output reg[1:0] InsSel,
output reg[2:0] InMuxAdd,
output reg[3:0] OutMuxAdd, RegAdd,
output reg[7:0] CUconst
    );
(*KEEP = "TRUE"*)    
reg[7:0] state_next,state_reg;

parameter 
          //// Initial states //// 
          IDLE = 8'd0,                             //this is the idle stage for the desing where it waits for start flag.
          Take_InA = 8'd1,                         // Input is asserted take that input to the ALU.
          is_input_zero = 8'd165,                  // Determine by AND operation with CUcons = 8'b1111111 to see if the input is zero.
          is_input_zero_decide = 8'd166,           // IF the input is zero circuit goes back to IDLE state. Does not process zero.
          save_the_input = 8'd18,                  // If input is non-zero then save it to REG15 for recovering purposes later. 

          //// other states ////
          prime_check = 8'd100,                /// more details about the outputstages can be found in line 1139.     
          terminate = 8'd113,
          recover_final_from_reg15 = 8'd159,
          recover_final_from_reg7 = 8'd160,
          where_to_recover_final_1 = 8'd161,
          where_to_recover_final_2 = 8'd162,
          decide_recover_final = 8'd164,
          
          
          
          // dump registers //
          dump_reg14 = 8'd120,   //REG14 = total multiplier of twos          ///////////////////////////////////////////////////////////////// 
          dump_reg13 = 8'd115,   //REG13 = total multiplier of threes        // In the  recovery stages, all the used registers are cleared // 
          dump_reg12 = 8'd116,   //REG12 = total multiplier of fives         // for the later use. So evertime new input with start flag    //                                                
          dump_reg11 = 8'd117,   //REG11 = total multiplier of sevens        // inserted or reset = 1, we clear all the registers for new   //                                                     
          dump_reg10 = 8'd118,   //REG10 = total multiplier of elevens       // process.                                                    //                                                           
          dump_reg9 = 8'd119,    //REG9 = total multiplier of thirteens      //                                                             //      
          dump_reg5 = 8'd121,    //REG8 = results of every substractions     /////////////////////////////////////////////////////////////////                                                              
          dump_reg7 = 8'd163,    //REG7 = results of every sub divisions     
          ///////////////////
          
          //////// saving results //////
          save_result_of_two = 8'd128,        // these are saving result states, it is required in order to detect any prime number larger than 13.
          save_result_of_three = 8'd129,      // for example if input is 70, after division by 2 there 35 will be the result. 
          save_result_of_five = 8'd130,       // division by three will begin from 35 not 70. Therefore results needs to be saved.
          save_result_of_seven = 8'd131,
          save_result_of_eleven = 8'd132,
          save_result_of_thirteen = 8'd133,
          ///////////////////////////////// end of saving results stages ///////////////////////////
          
          ////////// Recovery for division states /////////
          recover_three_from_reg15 = 8'd134,
          recover_three_from_reg7 = 8'd135,         ///////////////////////////////////////////////////////////////// 
          where_to_recover_three_1 = 8'd136,        // General info about recovery stages; 
          where_to_recover_three_2 = 8'd137,        // after each division stages the upcoming division stage needs an input,
          decide_recover_three = 8'd138,            // so if the number is divisible by prior numbers the upcoming stage will initiate the process with result of those divisions.   
          ////////////                              // or if the number is not divisible by the previously checked numbers, then next process will begin with input itself.    
          recover_five_from_reg15 = 8'd139,         // so remember reg7 was results, and reg15 was input itself. Therefore if the reg7 is empty (which means number is not divisible by priors) 
          recover_five_from_reg7 = 8'd140,          // it will take it's input from the reg15 which holds initially given input.                                                    
          where_to_recover_five_1 = 8'd141,         ///////////////////////////////////////////////////////////////// 
          where_to_recover_five_2 = 8'd142,                         
          decide_recover_five = 8'd143,                             
          //////////////                                            
          recover_seven_from_reg15 = 8'd144,                        
          recover_seven_from_reg7 = 8'd145,                         
          where_to_recover_seven_1 = 8'd146,                        
          where_to_recover_seven_2 = 8'd147,
          decide_recover_seven = 8'd148,
          //////////////
          recover_eleven_from_reg15 = 8'd149,
          recover_eleven_from_reg7 = 8'd150,
          where_to_recover_eleven_1 = 8'd151,
          where_to_recover_eleven_2 = 8'd152,
          decide_recover_eleven = 8'd153,
          //////////////
          recover_thirteen_from_reg15 = 8'd154,
          recover_thirteen_from_reg7 = 8'd155,
          where_to_recover_thirteen_1 = 8'd156,
          where_to_recover_thirteen_2 = 8'd157,
          decide_recover_thirteen = 8'd158,     
          ////////////////////////////////////////////////////// end of recovery stages ////////////////
          
          //////// Division states ////////// 
          
          
          //// division by two states //// 
          Take_CUconst_two = 8'd2,          // loads the two's complement of 2 to the CUconst.
          Divide_by_two = 8'd3,             // substracts 2 from the number.
          decision_two = 8'd4,              // decides whether division is complete or not. 
          increment_counter_two = 8'd5,     // increments the counter which is kept in reg 5. 
          Multiplier_two = 8'd6,            // this is the state when the division is succes and divident is found.          
          cu_const_one_two = 8'd8,          // Loading cu const 1 in order to increment the counter in reg 5. 
          read_counter_two = 8'd9,          // Current value of counter is read and will be processed. 
          recover_divisionby_two = 8'd10,   // So in this state we are recovering the result of substraction to proceed to division
          increment_counter_two_d = 8'd12,  // incrementing the counter value by one. 
          mark_two      = 8'd13,            // IF 2 is a multiplier then it needs to be recorded. This is done by incrementing the value in reg 14. 
          save_counter_two = 8'd14,         // That value in reg 14 holds how many times the number is divided by two.
          save_marked_two = 8'd15,          // After incrementing it is written back to reg 14.         
          continue_divide_two = 8'd16,      // Result of first division goes under the same process again. 
          dump_r5 = 8'd17,                  // reg5 is flushed in order to be used again for other numbers. 
          prep_three = 8'd7,                // If the number is not dividable by two check for three. That states initiates division by three.
          
          //// division by three states ////
          Take_CUconst_three =8'd19,
          Divide_by_three = 8'd20,
          decision_three = 8'd21,                   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
          increment_counter_three = 8'd26,         // division algorithm goes same for the rest of those prime numbers therefore those stages left unexplained. 
          Multiplier_three = 8'd22,               /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////      
          cu_const_one_three = 8'd25,
          read_counter_three = 8'd23,
          recover_divisionby_three = 8'd27,         
          increment_counter_three_d = 8'd29,
          mark_three = 8'd31,
          save_counter_three = 8'd30,          
          save_marked_three = 8'd32,
          continue_divide_three = 8'd33,
          dump_r5_three = 8'd34,
          prep_five = 8'd51,
          
          //// division by five states ////
          Take_CUconst_five = 8'd35,
          Divide_by_five = 8'd36,
          decision_five = 8'd37,
          increment_counter_five = 8'd42, 
          Multiplier_five = 8'd38,
          cu_const_one_five = 8'd41,
          read_counter_five = 8'd39,
          recover_divisionby_five = 8'd43,
          increment_counter_five_d = 8'd45,
          mark_five = 8'd47,
          save_counter_five = 8'd46,
          save_marked_five = 8'd48,
          continue_divide_five = 8'd49,
          dump_r9_five = 8'd50, 
          prep_seven = 8'd52,
          
          //// division by seven states ////
          Take_CUconst_seven = 8'd53,
          Divide_by_seven = 8'd54,
          decision_seven = 8'd55,
          increment_counter_seven = 8'd59, 
          Multiplier_seven = 8'd56,
          cu_const_one_seven = 8'd58,
          read_counter_seven = 8'd57,
          recover_divisionby_seven = 8'd60,
          increment_counter_seven_d = 8'd62,
          mark_seven = 8'd64,
          save_counter_seven = 8'd63,
          save_marked_seven = 8'd65,
          continue_divide_seven = 8'd66,
          dump_r9_seven = 8'd67,
          prep_eleven = 8'd68,
          
          //// division by eleven states ////
          Take_CUconst_eleven = 8'd69,
          Divide_by_eleven = 8'd70,
          decision_eleven = 8'd71, 
          increment_counter_eleven = 8'd75,
          Multiplier_eleven = 8'd72,
          cu_const_one_eleven = 8'd74,
          read_counter_eleven = 8'd73,         
          recover_divisionby_eleven = 8'd76,
          increment_counter_eleven_d = 8'd78,
          mark_eleven = 8'd80,         
          save_counter_eleven = 8'd79,          
          save_marked_eleven = 8'd81,
          continue_divide_eleven = 8'd82,
          dump_r9_eleven = 8'd83,
          prep_thirteen = 8'd84,
          
          //// division by thirteen states ////
          Take_CUconst_thirteen = 8'd85,
          Divide_by_thirteen = 8'd86,
          decision_thirteen = 8'd87,
          increment_counter_thirteen = 8'd91, 
          Multiplier_thirteen = 8'd88,
          cu_const_one_thirteen = 8'd90,
          read_counter_thirteen = 8'd89,         
          recover_divisionby_thirteen = 8'd92,
          increment_counter_thirteen_d = 8'd94,
          mark_thirteen = 8'd96,
          save_counter_thirteen = 8'd95,
          save_marked_thirteen = 8'd97,
          continue_divide_thirteen = 8'd98,
          dump_r9_thirteen = 8'd99;
          

               
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg <= IDLE;               // asynch reset.
         end
         else begin
            state_reg <= state_next;        // if not reset go next state.
         end 
         end
     
     always @(*) begin
           
            case (state_reg)
                IDLE: begin 
                      CUconst <= 8'd0;				      
				      OutMuxAdd <= 4'bz;      // In idle case those variables are also neutral
				      RegAdd <= 4'bz;
				      InMuxAdd <= 3'bz;
				      InsSel <= 2'bz;
				      Busy <= 1'b0;
				      WE <= 1'b0;
                                          
                        if (Start)
                        state_next <= Take_InA;               // It determines the next state according to start flag.
                        else
                        state_next <= IDLE;                     
                        
                      end
                Take_InA: begin
                      Busy <= 1'b1; 
                      state_next <= is_input_zero;   // Write input to the ALUinA.
                      InMuxAdd <= 3'b000;
                      WE <= 1'b1;
                      RegAdd <= 4'b0001;
                      end
                is_input_zero: begin
                      state_next <= is_input_zero_decide;  // to decide if the input is zero AND it with 8'b1111111 
                      CUconst <= 8'b11111111;              
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;
                      InsSel <= 2'd0;
                      end
                is_input_zero_decide: begin
                      if (Z)
                        state_next <= IDLE;         // if input is zero stay in the idle. 
                      else 
                        state_next <= save_the_input;
                      end                           
                save_the_input: begin
                      state_next <=  dump_reg7; // Saving the input to REG15 use in division operation or if it's the prime then will be given to the system.
                      InMuxAdd <= 3'b000;
                      WE <= 1'b1;
                      RegAdd <= 4'd15;
                      end       
                Take_CUconst_two: begin
                      state_next <= Divide_by_two;  // Division is just consecutive substraction operation therefore write two's complement of two the CUconst.
                      CUconst <= 8'b11111110;       
                      InMuxAdd <= 3'b010;
                      WE <= 1'b1;
                      RegAdd <= 3'd2;
                      end
                      
                 Divide_by_two: begin
                      state_next <= decision_two;  //After substracting once, it should be decided whether keep going to divide or move to three or it's a divider.
                      InsSel <= 2'd2;               // The result of substraction is written to the third register so that it continues with the new value. 
                      InMuxAdd <= 3'd3;             // For example if the input is 44 after the first substraction, the second substraction will take 42 as input. 
                      WE <= 1'b1;
                      RegAdd <= 4'd3;
                      end
                  
                 decision_two: begin
                       
                      if(Z&CO) begin
                      state_next <= Multiplier_two;  // If it's a divider it needs to be saved.
                      end
                      else if (~Z&CO) begin
                      state_next <= read_counter_two; // Division is not complete, continue. 
                      end
                      else if (~CO) begin
                      state_next <= prep_three;  // Not a divider so check the other element.
                      end
                      end
                  read_counter_two: begin
                      state_next <= cu_const_one_two; // After dividing by a number the result can also be divided by the same number. Therefore result needs to be stored. 
                      OutMuxAdd <=  4'd5;             // To store the result of divisin Reg5 will be used. 
                      InMuxAdd <= 3'd4;
                      WE <= 1'b1;
                      RegAdd <= 4'd1;
                      end  
                  cu_const_one_two: begin
                      state_next <= increment_counter_two; // in order to increment counter by one CUconst is used. 
                      CUconst <= 8'd1;
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;
                      end
                  increment_counter_two: begin
                      state_next <= recover_divisionby_two; // The value which is read from Reg5 is now added 1.  
                      InsSel <= 2'd2;                       // And stored back to the Reg5.
                      InMuxAdd <= 3'd3;
                      WE <= 1'b1; 
                      RegAdd <= 4'd5;
                      end 
                   recover_divisionby_two: begin
                      state_next <= Take_CUconst_two; // Now in order to keep dividing the state goes back to the beginning of division operation.
                      OutMuxAdd <= 4'd3;              // Remember the result of substraction was stored in reg5. Fetch that and continue
                      InMuxAdd <= 3'd4;               // So a division loop is constructed.
                      WE <= 1'b1;
                      RegAdd <= 4'd1;     
                      end 
                   Multiplier_two: begin 
                      state_next <= increment_counter_two_d;    // If a divider detected it has to be saved to the register             
                      OutMuxAdd <= 4'd5;                        // And besides for example 44/2 = 22 and 22 can also be divided by two so it has to be processed again
                      InMuxAdd <= 3'd4;                        
                      WE <= 1'b1;                               // When Z and CO flags are rised, it means we have a divider but we need to increment the counter by one again. 
                      RegAdd <= 4'd1;                           // so we need to read reg5 and increment it by one so that we can observe the result. 
                      end
                   increment_counter_two_d : begin 
                       state_next <= save_counter_two;              // Cuconst is loaded with 1 to realize the increment. 
                       CUconst <= 8'd1; 
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;                     
                       end 
                   save_counter_two: begin
                       state_next <= mark_two;                 // then the correct result of the division is written to the reg5. 
                       InsSel <= 3'd2;
                       WE <= 1'b1;
                       InMuxAdd <= 3'd3;
                       RegAdd <= 4'd5;
                       end
                    mark_two: begin 
                       state_next <= save_marked_two;          // We need to mark that number is divided by two.
                       OutMuxAdd <= 4'd14;                      // reg14 holds the value that shows how many multiples of 2 are present.
                       InMuxAdd <= 4'd4;                       // Therefore value in reg14 will directly be the exponential of 2. ( 2^(reg14)).
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                    save_marked_two: begin
                       state_next <= save_result_of_two;      // Reg14 is incremented so keep divide.  
                       InsSel <= 2'd2;             
                       InMuxAdd <= 3'd3;                        
                       WE <= 1'b1;                             
                       RegAdd <= 4'd14;
                       end
                    save_result_of_two : begin 
                        state_next <= continue_divide_two;      // Result of division is written to REG7 to refer later.                      
                       OutMuxAdd <= 4'd5;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd7;
                       end
                    continue_divide_two: begin                 // So the result of the division is goes back to ALU. 
                       state_next <= dump_r5;                  // But we need to refresh our increment holder. 
                       OutMuxAdd <= 4'd5;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end 
                      dump_r5: begin
                       state_next <= Take_CUconst_two;         // After we feed it back to the alu now we can safely dump reg5 so that it will be able to hold new values for next cycle of division.
                       CUconst <=8'd0;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;
                       end 
                     //////// In this section exact same algorithm also goes for three five seven eleven and thirteen therefore they left unexplained. 
                     prep_three: begin 
                     
                       state_next <= where_to_recover_three_1;  // here we also dump reg5 for using again but the next state is now division by three.
                       CUconst <= 8'd0;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;
                       end
                       
                       where_to_recover_three_1 : begin 
                       state_next <= where_to_recover_three_2;  // we have to decide the value to be processed. Therefore if the number is divisible before
                       OutMuxAdd <= 4'd7;                       // for example if input was 60 now after division by 2 and 2 again it will be 15
                       InMuxAdd <= 3'd4;                        // so in this cycle 15 should be processed not 60. 
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                       where_to_recover_three_2: begin 
                        state_next <= decide_recover_three;
                        CUconst <= 8'b11111111; 
                        InMuxAdd <= 3'd2;                      // if reg7 is empty it means number is not divisible by 2. So we need to process number itself.                      
                        WE <= 1'b1;
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_three: begin
                        if (Z)
                            state_next <= recover_three_from_reg15; // if zero take value from reg15 which contains input itself.
                        else
                            state_next <= recover_three_from_reg7;  // if not, continue division from quotient .
                       end
                     recover_three_from_reg7: begin
                       state_next <= Take_CUconst_three;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;                        // takes the value from reg7 and gives it to ALU.
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     recover_three_from_reg15: begin
                       state_next <= Take_CUconst_three;
                       OutMuxAdd <= 4'd15;
                       InMuxAdd <= 3'd4;                        // takes the value from reg15 and gives it to ALU.
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     Take_CUconst_three: begin
                     
                       state_next <= Divide_by_three;
                       CUconst <= 8'b11111101;   // two's complement of 3 (-3)   
                       InMuxAdd <= 3'b010;         
                       WE <= 1'b1;                 
                       RegAdd <= 3'd2;             
                       end                         
                      
                     Divide_by_three: begin
                       state_next <= decision_three;
                       InsSel <= 2'd2;  
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;      
                       RegAdd <= 4'd3;  
                       end
                     
                     decision_three: begin
                        if(Z&CO) begin                  
                        state_next <= Multiplier_three;  
                        end                             
                        else if (~Z&CO) begin
                        state_next <= read_counter_three; 
                        end                             
                        else if (~CO) begin             
                        state_next <= prep_five;  
                        end                             
                        end                              
                     read_counter_three: begin
                        state_next <= cu_const_one_three;   
                        OutMuxAdd <=  4'd5;            
                        InMuxAdd <= 3'd4;              
                        WE <= 1'b1;                        
                        RegAdd <= 4'd1;                
                        end  
                     cu_const_one_three: begin
                       state_next <= increment_counter_three;
                       CUconst <= 8'd1;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;
                        end 
                     increment_counter_three: begin
                       state_next <= recover_divisionby_three;
                       InsSel <= 2'd2;
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;                     
                       end 
                     recover_divisionby_three: begin
                      state_next <= Take_CUconst_three; 
                      OutMuxAdd <= 4'd3;              
                      InMuxAdd <= 3'd4;               
                      WE <= 1'b1;
                      RegAdd <= 4'd1;     
                      end
                     Multiplier_three: begin
                      state_next <= increment_counter_three_d;
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4; 
                      WE <= 1'b1;       
                      RegAdd <= 4'd1;    
                      end
                     increment_counter_three_d: begin
                      state_next <= save_counter_three;             
                      CUconst <= 8'd1; 
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;                
                      end
                     save_counter_three: begin
                      state_next <= mark_three;
                      InsSel <= 3'd2;    
                      WE <= 1'b1;        
                      InMuxAdd <= 3'd3; 
                      RegAdd <= 4'd5;   
                      end
                     mark_three: begin
                      state_next <= save_marked_three;               
                      OutMuxAdd <= 4'd13;            
                      InMuxAdd <= 4'd4;             
                      WE <= 1'b1;                   
                      RegAdd <= 4'd1;               
                      end 
                     save_marked_three: begin
                      state_next <= save_result_of_three;
                      InsSel <= 2'd2;                    
                      InMuxAdd <= 3'd3;                  
                      WE <= 1'b1;                        
                      RegAdd <= 4'd13;                                       
                      end
                      save_result_of_three : begin 
                        state_next <= continue_divide_three;
                       OutMuxAdd <= 4'd5;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd7;
                       end
                     continue_divide_three: begin
                      state_next <= dump_r5_three; 
                      OutMuxAdd <= 4'd5;    
                      InMuxAdd <= 3'd4;     
                      WE <= 1'b1;           
                      RegAdd <= 4'd1;                                               
                      end                                     
                     dump_r5_three: begin     
                      state_next <= Take_CUconst_three; 
                      CUconst <=8'd0;                 
                      InMuxAdd <= 3'd2;               
                      WE <= 1'b1;                     
                      RegAdd <= 4'd5;                 
                      end
                     prep_five: begin 
                     
                      state_next <= where_to_recover_five_1;
                       CUconst <= 8'd0;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;
                       end
  ///////////////////// division by five stages /////////////////                     
                       where_to_recover_five_1 : begin 
                       state_next <= where_to_recover_five_2;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                       where_to_recover_five_2: begin 
                        state_next <= decide_recover_five;
                        CUconst <= 8'b11111111;
                        InMuxAdd <= 3'd2;                        
                        WE <= 1'b1;
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_five: begin
                        if (Z)
                            state_next <= recover_five_from_reg15;
                        else
                            state_next <= recover_five_from_reg7;
                       end
                     recover_five_from_reg7: begin
                       state_next <= Take_CUconst_five;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     recover_five_from_reg15: begin
                       state_next <= Take_CUconst_five;
                       OutMuxAdd <= 4'd15;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     
                     Take_CUconst_five: begin
                     
                       state_next <= Divide_by_five;
                       CUconst <= 8'b11111011;     
                       InMuxAdd <= 3'b010;         
                       WE <= 1'b1;                 
                       RegAdd <= 3'd2;             
                       end                         
                      
                     Divide_by_five: begin
                       state_next <= decision_five;
                       InsSel <= 2'd2;  
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;      
                       RegAdd <= 4'd3;  
                       end
                    
                     decision_five: begin
                       if(Z&CO) begin                  
                       state_next <= Multiplier_five;  
                       end                             
                       else if (~Z&CO) begin
                       state_next <= read_counter_five; 
                       end                             
                       else if (~CO) begin             
                       state_next <= prep_seven;  
                       end                             
                       end                              
                     read_counter_five: begin
                       state_next <= cu_const_one_five;   
                       OutMuxAdd <=  4'd5;            
                       InMuxAdd <= 3'd4;              
                       WE <= 1'b1;                        
                       RegAdd <= 4'd1;                
                       end  
                     cu_const_one_five: begin
                      state_next <= increment_counter_five;
                      CUconst <= 8'd1;
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;
                       end 
                     increment_counter_five: begin
                      state_next <= recover_divisionby_five;
                      InsSel <= 2'd2;
                      InMuxAdd <= 3'd3;
                      WE <= 1'b1;
                      RegAdd <= 4'd5;                     
                      end 
                     recover_divisionby_five: begin
                      state_next <= Take_CUconst_five; 
                      OutMuxAdd <= 4'd3;              
                      InMuxAdd <= 3'd4;               
                      WE <= 1'b1;
                      RegAdd <= 4'd1;     
                      end
                     Multiplier_five: begin
                      state_next <= increment_counter_five_d;
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4; 
                      WE <= 1'b1;       
                      RegAdd <= 4'd1;    
                      end
                     increment_counter_five_d: begin
                      state_next <= save_counter_five;             
                      CUconst <= 8'd1; 
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;                
                      end
                     save_counter_five: begin
                      state_next <= mark_five;
                      InsSel <= 3'd2;    
                      WE <= 1'b1;        
                      InMuxAdd <= 3'd3; 
                      RegAdd <= 4'd5;   
                      end
                  
                     mark_five: begin
                      state_next <= save_marked_five;               
                      OutMuxAdd <= 4'd12;            
                      InMuxAdd <= 4'd4;             
                      WE <= 1'b1;                   
                      RegAdd <= 4'd1;               
                      end 
                     save_marked_five: begin
                      state_next <= save_result_of_five; 
                      InsSel <= 2'd2;                    
                      InMuxAdd <= 3'd3;                  
                      WE <= 1'b1;                        
                      RegAdd <= 4'd12;                                       
                      end
                     save_result_of_five : begin 
                      state_next <= continue_divide_five;   
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4;
                      WE <= 1'b1;
                      RegAdd <= 4'd7;
                      end
                     continue_divide_five: begin
                      state_next <= dump_r9_five; 
                      OutMuxAdd <= 4'd5;    
                      InMuxAdd <= 3'd4;     
                      WE <= 1'b1;           
                      RegAdd <= 4'd1;                                               
                      end                                     
                     dump_r9_five: begin     
                      state_next <= Take_CUconst_five; 
                      CUconst <=8'd0;                 
                      InMuxAdd <= 3'd2;               
                      WE <= 1'b1;                     
                      RegAdd <= 4'd5;                 
                      end                   
                     prep_seven: begin 
                      state_next <= where_to_recover_seven_1;
                       CUconst <= 8'd0;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;
                       end
  ////////////////////////////// division to seven //////////////////////                     
                       where_to_recover_seven_1 : begin 
                       state_next <= where_to_recover_seven_2;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                       where_to_recover_seven_2: begin 
                        state_next <= decide_recover_seven;
                        CUconst <= 8'b11111111;
                        InMuxAdd <= 3'd2;                       
                        WE <= 1'b1;
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_seven: begin
                        if (Z)
                            state_next <= recover_seven_from_reg15;
                        else
                            state_next <= recover_seven_from_reg7;
                       end
                     recover_seven_from_reg7: begin
                       state_next <= Take_CUconst_seven;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     recover_seven_from_reg15: begin
                       state_next <= Take_CUconst_seven;
                       OutMuxAdd <= 4'd15;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     Take_CUconst_seven: begin
                     
                       state_next <= Divide_by_seven;
                       CUconst <= 8'b11111001;     
                       InMuxAdd <= 3'b010;         
                       WE <= 1'b1;                 
                       RegAdd <= 3'd2;             
                       end                         
                      
                     Divide_by_seven: begin
                       state_next <= decision_seven;
                       InsSel <= 2'd2;  
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;      
                       RegAdd <= 4'd3;  
                       end
                    
                     decision_seven: begin
                       if(Z&CO) begin                  
                       state_next <= Multiplier_seven;  
                       end                             
                       else if (~Z&CO) begin
                       state_next <= read_counter_seven; 
                       end                             
                       else if (~CO) begin             
                       state_next <= prep_eleven;  
                       end                             
                       end                              
                     read_counter_seven: begin
                       state_next <= cu_const_one_seven;   
                       OutMuxAdd <=  4'd5;            
                       InMuxAdd <= 3'd4;              
                       WE <= 1'b1;                        
                       RegAdd <= 4'd1;                
                       end  
                     cu_const_one_seven: begin
                       state_next <= increment_counter_seven;
                       CUconst <= 8'd1;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;
                       end 
                     increment_counter_seven: begin
                       state_next <= recover_divisionby_seven;
                       InsSel <= 2'd2;
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;                     
                       end 
                     recover_divisionby_seven: begin
                       state_next <= Take_CUconst_seven; 
                       OutMuxAdd <= 4'd3;              
                       InMuxAdd <= 3'd4;               
                       WE <= 1'b1;
                       RegAdd <= 4'd1;     
                       end
                     Multiplier_seven: begin
                       state_next <= increment_counter_seven_d;
                       OutMuxAdd <= 4'd5;
                       InMuxAdd <= 3'd4; 
                       WE <= 1'b1;       
                       RegAdd <= 4'd1;    
                       end
                     increment_counter_seven_d: begin
                       state_next <= save_counter_seven;             
                       CUconst <= 8'd1; 
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;                
                       end
                     save_counter_seven: begin
                       state_next <= mark_seven;
                       InsSel <= 3'd2;    
                       WE <= 1'b1;        
                       InMuxAdd <= 3'd3; 
                       RegAdd <= 4'd5;   
                       end                    
                     mark_seven: begin
                      state_next <= save_marked_seven;               
                      OutMuxAdd <= 4'd11;            
                      InMuxAdd <= 4'd4;             
                      WE <= 1'b1;                   
                      RegAdd <= 4'd1;               
                      end 
                     save_marked_seven: begin
                      state_next <= save_result_of_seven; 
                      InsSel <= 2'd2;                    
                      InMuxAdd <= 3'd3;                  
                      WE <= 1'b1;                        
                      RegAdd <= 4'd11;                                       
                      end
                     save_result_of_seven : begin 
                      state_next <= continue_divide_seven;                                    
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4;
                      WE <= 1'b1;
                      RegAdd <= 4'd7;
                      end
                     continue_divide_seven: begin
                      state_next <= dump_r9_seven; 
                      OutMuxAdd <= 4'd5;    
                      InMuxAdd <= 3'd4;     
                      WE <= 1'b1;           
                      RegAdd <= 4'd1;                                               
                      end                                     
                     dump_r9_seven: begin     
                      state_next <= Take_CUconst_seven; 
                      CUconst <=8'd0;                 
                      InMuxAdd <= 3'd2;               
                      WE <= 1'b1;                     
                      RegAdd <= 4'd5;                 
                      end                             
                     prep_eleven: begin 
                      state_next <= where_to_recover_eleven_1;
                      CUconst <= 8'd0;
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd5;
                      end
 ///////////////////////// division by eleven ///////////////////////                      
                       where_to_recover_eleven_1 : begin 
                       state_next <= where_to_recover_eleven_2;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                       where_to_recover_eleven_2: begin 
                        state_next <= decide_recover_eleven;
                        CUconst <= 8'b11111111;
                        InMuxAdd <= 3'd2;                         
                        WE <= 1'b1;
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_eleven: begin
                        if (Z)
                            state_next <= recover_eleven_from_reg15;
                        else
                            state_next <= recover_eleven_from_reg7;
                       end
                     recover_eleven_from_reg7: begin
                       state_next <= Take_CUconst_eleven;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     recover_eleven_from_reg15: begin
                       state_next <= Take_CUconst_eleven;
                       OutMuxAdd <= 4'd15;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     
                     end
                     Take_CUconst_eleven: begin
                      
                        state_next <= Divide_by_eleven;
                        CUconst <= 8'b11110101;     
                        InMuxAdd <= 3'b010;         
                        WE <= 1'b1;                 
                        RegAdd <= 3'd2;             
                        end                         
                       
                      Divide_by_eleven: begin
                        state_next <= decision_eleven;
                        InsSel <= 2'd2;  
                        InMuxAdd <= 3'd3;
                        WE <= 1'b1;      
                        RegAdd <= 4'd3;  
                        end
                     
                     decision_eleven: begin
                        if(Z&CO) begin                  
                        state_next <= Multiplier_eleven;  
                        end                             
                        else if (~Z&CO) begin
                        state_next <= read_counter_eleven; 
                        end                             
                        else if (~CO) begin             
                        state_next <= prep_thirteen;  
                        end                             
                        end                              
                     read_counter_eleven: begin
                        state_next <= cu_const_one_eleven;   
                        OutMuxAdd <=  4'd5;            
                        InMuxAdd <= 3'd4;              
                        WE <= 1'b1;                        
                        RegAdd <= 4'd1;                
                        end  
                     cu_const_one_eleven: begin
                       state_next <= increment_counter_eleven;
                       CUconst <= 8'd1;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;
                        end 
                     increment_counter_eleven: begin
                       state_next <= recover_divisionby_eleven;
                       InsSel <= 2'd2;
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;                     
                       end 
                     recover_divisionby_eleven: begin
                      state_next <= Take_CUconst_eleven; 
                      OutMuxAdd <= 4'd3;              
                      InMuxAdd <= 3'd4;               
                      WE <= 1'b1;
                      RegAdd <= 4'd1;     
                      end
                     Multiplier_eleven: begin
                      state_next <= increment_counter_eleven_d;
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4; 
                      WE <= 1'b1;       
                      RegAdd <= 4'd1;    
                      end
                     increment_counter_eleven_d: begin
                      state_next <= save_counter_eleven;             
                      CUconst <= 8'd1; 
                      InMuxAdd <= 3'd2;
                      WE <= 1'b1;
                      RegAdd <= 4'd2;                
                      end
                     save_counter_eleven: begin
                      state_next <= mark_eleven;
                      InsSel <= 3'd2;    
                      WE <= 1'b1;        
                      InMuxAdd <= 3'd3; 
                      RegAdd <= 4'd5;   
                      end                   
                     mark_eleven: begin
                      state_next <= save_marked_eleven;               
                      OutMuxAdd <= 4'd10;            
                      InMuxAdd <= 4'd4;             
                      WE <= 1'b1;                   
                      RegAdd <= 4'd1;               
                      end 
                     save_marked_eleven: begin
                      state_next <= save_result_of_eleven; 
                      InsSel <= 2'd2;                    
                      InMuxAdd <= 3'd3;                  
                      WE <= 1'b1;                        
                      RegAdd <= 4'd10;                                       
                      end
                     save_result_of_eleven : begin 
                      state_next <= continue_divide_eleven;                                
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4;
                      WE <= 1'b1;
                      RegAdd <= 4'd7;
                      end
                     continue_divide_eleven: begin
                      state_next <= dump_r9_eleven; 
                      OutMuxAdd <= 4'd5;    
                      InMuxAdd <= 3'd4;     
                      WE <= 1'b1;           
                      RegAdd <= 4'd1;                                               
                      end                                     
                     dump_r9_eleven: begin     
                      state_next <= Take_CUconst_eleven; 
                      CUconst <=8'd0;                 
                      InMuxAdd <= 3'd2;               
                      WE <= 1'b1;                     
                      RegAdd <= 4'd5;                 
                      end                             
                     prep_thirteen: begin 
                      state_next <= where_to_recover_thirteen_1;
                       CUconst <= 8'd0;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;
                       end
  //////////////////////// division by thirteen ///////////////////                     
                       where_to_recover_thirteen_1 : begin 
                       state_next <= where_to_recover_thirteen_2;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                       where_to_recover_thirteen_2: begin 
                        state_next <= decide_recover_thirteen;
                        CUconst <= 8'b11111111; 
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_thirteen: begin
                        if (Z)
                            state_next <= recover_thirteen_from_reg15;
                        else
                            state_next <= recover_thirteen_from_reg7;
                        end
                     recover_thirteen_from_reg7: begin
                       state_next <= Take_CUconst_thirteen;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     recover_thirteen_from_reg15: begin
                       state_next <= Take_CUconst_thirteen;
                       OutMuxAdd <= 4'd15;
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                     end
                     Take_CUconst_thirteen: begin                     
                       state_next <= Divide_by_thirteen;
                       CUconst <= 8'b11110011;     
                       InMuxAdd <= 3'b010;         
                       WE <= 1'b1;                 
                       RegAdd <= 3'd2;             
                       end                         
                       
                      Divide_by_thirteen: begin
                       state_next <= decision_thirteen;
                       InsSel <= 2'd2;  
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;      
                       RegAdd <= 4'd3;  
                       end
                     
                     decision_thirteen: begin
                       if(Z&CO) begin                  
                       state_next <= Multiplier_thirteen;  
                       end                             
                       else if (~Z&CO) begin
                       state_next <= read_counter_thirteen; 
                       end                             
                       else if (~CO) begin             
                       state_next <= prime_check;     // since there are nothing left to check, we check for the prime numbers. 
                       end                             
                       end                              
                     read_counter_thirteen: begin
                       state_next <= cu_const_one_thirteen;   
                       OutMuxAdd <=  4'd5;            
                       InMuxAdd <= 3'd4;              
                       WE <= 1'b1;                        
                       RegAdd <= 4'd1;                
                       end  
                     cu_const_one_thirteen: begin
                       state_next <= increment_counter_thirteen;
                       CUconst <= 8'd1;
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;
                       end 
                     increment_counter_thirteen: begin
                       state_next <= recover_divisionby_thirteen;
                       InsSel <= 2'd2;
                       InMuxAdd <= 3'd3;
                       WE <= 1'b1;
                       RegAdd <= 4'd5;                     
                       end 
                     recover_divisionby_thirteen: begin
                       state_next <= Take_CUconst_thirteen; 
                       OutMuxAdd <= 4'd3;              
                       InMuxAdd <= 3'd4;               
                       WE <= 1'b1;
                       RegAdd <= 4'd1;     
                       end
                     Multiplier_thirteen: begin
                       state_next <= increment_counter_thirteen_d;
                       OutMuxAdd <= 4'd5;
                       InMuxAdd <= 3'd4; 
                       WE <= 1'b1;       
                       RegAdd <= 4'd1;    
                       end
                     increment_counter_thirteen_d: begin
                       state_next <= save_counter_thirteen;             
                       CUconst <= 8'd1; 
                       InMuxAdd <= 3'd2;
                       WE <= 1'b1;
                       RegAdd <= 4'd2;                
                       end
                     save_counter_thirteen: begin
                       state_next <= mark_thirteen;
                       InsSel <= 3'd2;    
                       WE <= 1'b1;        
                       InMuxAdd <= 3'd3; 
                       RegAdd <= 4'd5;   
                       end
                     
                     mark_thirteen: begin
                       state_next <= save_marked_thirteen;               
                       OutMuxAdd <= 4'd9;            
                       InMuxAdd <= 4'd4;             
                       WE <= 1'b1;                   
                       RegAdd <= 4'd1;               
                       end 
                     save_marked_thirteen: begin
                       state_next <= save_result_of_thirteen; 
                       InsSel <= 2'd2;                    
                       InMuxAdd <= 3'd3;                  
                       WE <= 1'b1;                        
                       RegAdd <= 4'd9;                                       
                       end
                     save_result_of_thirteen : begin 
                      state_next <= continue_divide_thirteen;                                      
                      OutMuxAdd <= 4'd5;
                      InMuxAdd <= 3'd4;
                      WE <= 1'b1;
                      RegAdd <= 4'd7;
                      end
                     continue_divide_thirteen: begin
                       state_next <= dump_r9_thirteen; 
                       OutMuxAdd <= 4'd5;    
                       InMuxAdd <= 3'd4;     
                       WE <= 1'b1;           
                       RegAdd <= 4'd1;                                               
                       end                                     
                     dump_r9_thirteen: begin     
                       state_next <= Take_CUconst_thirteen; 
                       CUconst <=8'd0;                 
                       InMuxAdd <= 3'd2;               
                       WE <= 1'b1;                     
                       RegAdd <= 4'd5;                 
                       end         
                  //////////////////// output states //////////////////7                                              
                      prime_check: begin 
                       state_next <= where_to_recover_final_1;   /// Now to decide to output. REG7 was keeping the results of the divisions. 
                       CUconst <= 8'd0;                          /// If the number is totally divisible by 2,3,5,7,11,13 the REG7 will be holding 1.
                       InMuxAdd <= 3'd2;                         /// If the number is partially divisible for example for example 215 = 5*43
                       WE <= 1'b1;                               /// 43 is a prime number, reg7 will be holding 43 as the division result
                       RegAdd <= 4'd5;                           /// Then 43 will be feed into output.
                       end                                       /// IF reg7 = 0 which means input itself is Prime in that case it will output the reg15
                       
                      where_to_recover_final_1 : begin 
                       state_next <= where_to_recover_final_2;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;                                    // Load reg7 to ALU
                       WE <= 1'b1;
                       RegAdd <= 4'd1;
                       end
                      where_to_recover_final_2: begin 
                        state_next <= decide_recover_final;
                        CUconst <= 8'b11111111;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;                                         // AND reg7 with 8'b1111111 to see if it's Zero.
                        RegAdd <=4'd2;
                        InsSel <= 2'd0;
                        end
                      decide_recover_final: begin
                        if (Z)
                            state_next <= recover_final_from_reg15;
                        else                                                 // decision algorithm
                            state_next <= recover_final_from_reg7;
                       end
                     recover_final_from_reg7: begin
                       state_next <= terminate;
                       OutMuxAdd <= 4'd7;
                       InMuxAdd <= 3'd4;                                    // load reg7 to OUT
                       WE <= 1'b1;
                       RegAdd <= 4'd0;
                       end
                     recover_final_from_reg15: begin
                       state_next <= terminate;
                       OutMuxAdd <= 4'd15;                                  // load reg15 to OUT
                       InMuxAdd <= 3'd4;
                       WE <= 1'b1;
                       RegAdd <= 4'd0;
                       end                                                                                                
                     terminate : begin
                       state_next <= IDLE;         /// circuit waits 1 clock to produce output. In this case OUT will be available as soon as busy flag drops.            
                       end 
                        
                                    
                        
                ///// dumping registers ////////
                       dump_reg7 : begin 
                        state_next <= dump_reg5;             /// dump all registers by CUcons = 8'd0 and giving the each adrress.
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd7; 
                        end                    
                       dump_reg5 : begin 
                        state_next <= dump_reg14;
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd5;  
                        end           
                       dump_reg14 : begin
                        state_next <= dump_reg13;
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd14;
                        end
                       dump_reg13: begin 
                        state_next <= dump_reg12; 
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd13;
                        end
                       dump_reg12: begin 
                        state_next <= dump_reg11; 
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd12;
                        end
                       dump_reg11: begin 
                        state_next <= dump_reg10; 
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd11;
                        end
                       dump_reg10: begin 
                        state_next <= dump_reg9; 
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd10;
                        end
                       dump_reg9: begin 
                        state_next <= Take_CUconst_two;
                        CUconst <= 8'd0;
                        InMuxAdd <= 3'd2;
                        WE <= 1'b1;
                        RegAdd <= 4'd9;
                       end
                      
                       default:
                       state_next <= IDLE;
                       
endcase
end
endmodule                      
                       
                       
                       
                       
                       
                       
                                                                                                                                                                                          

