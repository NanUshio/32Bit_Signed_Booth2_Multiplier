//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_4to2compressor.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [do 4-2 compressor]
  //
//------------------------------------------------------------------------------

module booth2_mul_4to2compressor (
  // dat_i
  ai      ,
  bi      ,
  ci      ,
  di      ,
  cin     ,
  // dat_o
  cout    ,
  so      ,
  co
);

//*** PARAMETER ****************************************************************
  // NULL
//*** INPUT/OUTPUT *************************************************************
  // dat_i
  input    ai    ;
  input    bi    ;
  input    ci    ;
  input    di    ;
  input    cin   ;
  // dat_o
  output   cout  ; // Carry out of the second 3to2adder
  output   so    ;
  output   co    ; // Carry out of the first  3to2adder
//*** WIRE/REG *****************************************************************
  wire     first_adder_so_w  ;
  wire     first_adder_co_w  ;
  wire     second_adder_so_w ;
  wire     second_adder_co_w ;
//*** MAIN BODY ****************************************************************
  // output
  assign cout = second_adder_co_w  ;
  assign so   = second_adder_so_w  ;
  assign co   = first_adder_co_w   ;  

  // main 
  booth2_mul_3to2adder firstadder(
    .ai      ( ai               ) ,
    .bi      ( bi               ) ,
    .cin     ( ci               ) ,
    .cout    ( first_adder_co_w ) ,
    .so      ( first_adder_so_w )
  ) ;

  booth2_mul_3to2adder secondadder(
    .ai      ( di                ) ,
    .bi      ( first_adder_so_w  ) ,
    .cin     ( cin               ) ,
    .cout    ( second_adder_co_w ) ,
    .so      ( second_adder_so_w )
  ) ;

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule