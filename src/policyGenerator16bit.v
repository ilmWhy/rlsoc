//Andi Muhammad Riyadhus Ilmy (13217053)
//Tyfan Juliano (13217063)
//Yafie Abdillah (13217091)
//Evan Robert (13217057)
//Modul Policy Generator untuk LSI Design 2021

module policyGenerator_16bit(
 input clk,
 input stateRstIn, //From CU
 input stateSelectIn, //From CU
 input [7:0] currentStateIn,
 input [15:0] qAct0, qAct1, qAct2, qAct3, //From QUpdater
 output [1:0] nextActionOut,
 output [9:0] randValueOut,
 output [7:0] nxtStateOut
);
 
 wire [1:0] actLsfr, actGreed, muxOut; //Action Wire
 wire [7:0] wallOut; //State Wire

 //PORTMAP
 lsfr_16bit lsfr0(
  .clk(clk),
  .nextAction(actLsfr),
  .randomValue(randValueOut)
 );

 greedAction greed0(
  .qAct0(qAct0), .qAct1(qAct1), .qAct2(qAct2), .qAct3(qAct3),
  .nextAction(actGreed)
 );

 decideNextAct mux0(
  .greedAct(actGreed), .lsfrAct(actLsfr),
  .sel(stateSelectIn),
  .nxtAct(muxOut)
 );

 wallDetect wall0(
  .currentState(currentStateIn),
  .nxtAction(muxOut),
  .nxtState(wallOut)
 );

 resetState rst0(
  .inState(wallOut),
  .stateRst(stateRstIn),
  .outState(nxtStateOut)
 );

 assign nextActionOut = muxOut;
endmodule
