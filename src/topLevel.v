//Andi Muhammad Riyadhus Ilmy (13217053)
//Tyfan Juliano (13217063)
//Yafie Abdillah (13217091)
//Evan Robert (13217057)
//Modul Q Learning Agent untuk LSI Design 2021
//Top Level Module

module topLevel(
 input CLOCK, RESET, startSig,
 output [1:0] nextAction,
 output finishedLearning
);
//Rewards
 parameter signed [15:0] rw0 = 16'sh0000; //ZERO
 parameter signed [15:0] rw1 = 16'shFB00; //-5  = 1111 1011.0000 0000
 parameter signed [15:0] rw2 = 16'shF600; //-10 = 1110 0111.0000 0000 
 parameter signed [15:0] rw3 = 16'sh0A00; // 10 = 0000 1010.0000 0000

//Alfa and Gamma
 parameter signed [23:0] alfa =  24'sh010000; //0.100 = 0,5
 parameter signed [23:0] gamma = 24'sh010203; //0.111 = 0,875

//Register for delaying inputs 1 clock cycle
 reg [1:0] currentAction;
 reg [7:0] currentState;

//Wires
 wire stateReset ,stateSelect;
 wire [7:0] nextState;
 wire [9:0] randomValue;
 wire signed [15:0] currentReward;
 wire signed [15:0] row0, row1, row2, row3; // For passing to outputs
 
//PORTMAPPING START========================================================
 maze_display_tb_2 disp(
  .state(currentState)
 );
 
 qLearningAccel_16bit qla(
  .clk(CLOCK),
  .stateRst(stateReset),
  .rst(RESET),
  .st(currentState), //Current State
  .nxtst(nextState), //Next State
  .act(nextAction), //Current Action
  .rt(currentReward),
  .alfa(alfa), 
  .gamma(gamma),
  .qRow0(row0), .qRow1(row1), .qRow2(row2), .qRow3(row3)
 );

 policyGenerator_16bit pg(
  .clk(CLOCK),
  .stateRstIn(stateReset), //From CU
  .stateSelectIn(stateSelect), //From CU
  .currentStateIn(currentState),
  .qAct0(row0), .qAct1(row1), .qAct2(row2), .qAct3(row3), //From QUpdater
  .nextActionOut(nextAction),
  .randValueOut(randomValue),
  .nxtStateOut(nextState)
 );

 controlUnit32bit cu(
  .clk (CLOCK),
  .rst(RESET),
  .startFlag(startSig),
  .randomValueIn(randomValue),
  .posResetOut(stateReset),
  .actSelectOut(stateSelect),
  .finishFlag(finishedLearning)
 );
 
 rewardModule_16bit reward(
  .clk(CLOCK),
  .stateRstIn(stateReset),
  .currentStateIn(currentState),
  .nextStateIn(nextState),
  .rw0(rw0), .rw1(rw1), .rw2(rw2), .rw3(rw3),
  .currentRewardOut(currentReward)
 );
//=========================================================================
 
//Delay Operations
 always @(posedge CLOCK)
 begin
  currentAction <= nextAction;
  currentState <= nextState;
 end
 
 //Display Change in currentState to terminal
 always @(currentState)
 begin
   $monitor("state : %d\n",currentState);
 end
endmodule

//TESTBENCH FOR THE MODULE
module toplevel_tb();
 reg clock, reset, start;
 wire [1:0] nextAct;
 wire finished;

 topLevel DUT(
  .CLOCK(clock),
  .RESET(reset),
  .startSig(start),
  .nextAction(nextAct),
  .finishedLearning(finished)
 );

 initial begin
  clock = 1'b1;
  reset = 1'b1;
  start = 1'b0;
  #10
  reset = 1'b0;
  #2
  start = 1'b1;
  #2
  start = 1'b0;
 end

//clock generator
 always begin
  #1 clock = ~clock;
 end
endmodule
