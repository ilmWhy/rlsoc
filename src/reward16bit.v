module rewardModule_16bit(
 input clk,
 input stateRstIn,
 input [7:0] currentStateIn, nextStateIn,
 input signed[15:0] rw0, rw1, rw2, rw3,
 output signed[15:0] currentRewardOut
);
 wire signed[15:0] nextReward;
 wire [1:0] rwSel;

 reg [7:0] prevState;
 reg signed[15:0] tempOut;

 //PORTMAP
 rewardSelect sel0(
  .prevState(prevState),
  .nxtState(nextStateIn),
  .currentState(currentStateIn),
  .rwSel(rwSel)
 );

 rewardMux_16bit mux0(
  .rw0(rw0),
  .rw1(rw1),
  .rw2(rw2),
  .rw3(rw3),
  .rwSel(rwSel),
  .staterst(stateRstIn),
  .out(nextReward)
 );

 //Delay operations
 always @(posedge clk) begin
  prevState = currentStateIn;
  tempOut = nextReward;
 end
 
 //Assign Outputs
 assign currentRewardOut = nextReward;
endmodule
