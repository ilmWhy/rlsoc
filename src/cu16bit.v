//Andi Muhammad Riyadhus Ilmy (13217053)
//Tyfan Juliano (13217063)
//Yafie Abdillah (13217091)
//Evan Robert (13217057)
//Modul Control Unit untuk LSI Design 2021
module controlUnit32bit(
 input clk,
 input rst,
 input startFlag, //sinyal dari software untuk mulai generasi
 input signed[9:0] randomValueIn,
 output posResetOut,
 output actSelectOut,
 output finishFlag //sinyal ke sotfware untuk memberi tahu hasil learning selesai
);

//STATE DECLARATION
 parameter RESET = 2'd0;
 parameter INIT = 2'd1;
 parameter LEARN = 2'd2;
 parameter FINISH = 2'd3;

 parameter maxGen = 16'd1023;
 parameter maxAct = 16'd50;

 reg [2:0] state;
 
 reg signed [10:0] decideFactor, randomValue = 11'sd0;
 reg signed [10:0] epsilon = 11'd1023;

 //Counter
 reg signed [15:0] genCount = 16'd0;
 reg [15:0] actionCount = 16'd0; 
 
 //output passing register
 reg actSelectTemp;
 reg posResetTemp = 1'b0;

 wire [2:0] nextState;

 always @(posedge clk) begin
  if (rst) begin
   state <= RESET;
  end else begin
   //Finite State Machine
   case(state)
    RESET: begin
     if (startFlag) begin
      state <= nextState;
     end
    end

    INIT: begin
     state <= nextState;
     //Reset generation and action count
     genCount <= 16'd0;
     actionCount <= 16'd0;
    end

    LEARN: begin
     //Generation Counter
     if (genCount >= maxGen) begin
      //Max number of generations reached
      state <= nextState; //Learning process finished
      posResetTemp <= 1'd1; //return agent to start pos.
     end else begin
      if (actionCount >= maxAct) begin //max act per gen. reached
       genCount = genCount + 16'd1; //new generation
       epsilon = maxGen - genCount; //update epsilon
       actionCount = 16'd0; //reset action counter
      end else begin
       actionCount = actionCount + 16'd1; //Count steps
      end
      
      //Epsilon Calculation for actionSelect
      randomValue[9:0] = randomValueIn;
      decideFactor = epsilon - randomValue; 
      if (decideFactor >= 11'sd0) begin
       actSelectTemp = 1'b1; //Choose random action
      end else begin
       actSelectTemp = 1'b0; //Choose greedy algorithm to determine action
      end
     end
    end

    FINISH: begin
     state <= nextState;
    end
   endcase
  end
 end

 //State Logic
 assign nextState =
 (state == RESET)  ? INIT :
 (state == INIT)   ? LEARN :
 (state == LEARN)  ? FINISH :
 (state == FINISH) ? RESET :
                     RESET ;

 //Assign outputs
 assign posResetOut = posResetTemp;
 assign actSelectOut = actSelectTemp;
 assign finishFlag = (state == FINISH) ? 1'b1 : 1'b0;
 assign ctrlSignal =
 (state == RESET)  ? 3'd0 :
 (state == INIT)   ? 3'd1 :
 (state == LEARN)  ? 3'd2 :
 (state == FINISH) ? 3'd3 :
                     3'd4 ;       
endmodule
///////////////////////////////////////////////////////////////////////////