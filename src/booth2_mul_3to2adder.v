//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_3to2adder.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [do one bit full adder]
  //
//------------------------------------------------------------------------------

module booth2_mul_3to2adder (
  // dat_i
  ai      ,
  bi      ,
  cin     ,
  // dat_o
  cout    ,
  so
);

//*** PARAMETER ****************************************************************
  // NULL
//*** INPUT/OUTPUT *************************************************************
  // dat_i
  input    ai    ;
  input    bi    ;
  input    cin   ;
  // dat_o
  output   cout  ;
  output   so    ;
//*** WIRE/REG *****************************************************************
  wire     xor1_o_w ;
  wire     xor2_o_w ;
  wire     and1_o_w ;
  wire     and2_o_w ;
  wire     or1_o_w  ; 
//*** MaiN BODY ****************************************************************
  // output
  assign so   = xor2_o_w ;
  assign cout = or1_o_w  ;

  // main 
  assign or1_o_w  = and1_o_w | and2_o_w ;
  assign and1_o_w = xor1_o_w & cin ;
  assign and2_o_w = ~xor1_o_w & ai ;
  assign xor2_o_w = xor1_o_w ^ cin ;
  assign xor1_o_w = ai ^ bi ;

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule