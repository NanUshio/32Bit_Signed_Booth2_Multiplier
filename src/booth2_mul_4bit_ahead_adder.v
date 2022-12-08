//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_4bit_ahead_adder.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [do 4 bit carry look ahead adder]
  //
//------------------------------------------------------------------------------

module booth2_mul_4bit_ahead_adder (
  // dat_i
  ai      ,
  bi      ,
  cin     ,
  // dat_o
  cout    ,
  so
);

//*** PARAMETER ****************************************************************
  localparam DATA_THR = 4 ;
//*** INPUT/OUTPUT *************************************************************
  // dat_i
  input    [DATA_THR    - 1 : 0]    ai    ;
  input    [DATA_THR    - 1 : 0]    bi    ;
  input                             cin   ;
  // dat_o
  output                            cout  ;
  output   [DATA_THR    - 1 : 0]    so    ;
//*** WIRE/REG *****************************************************************
  wire     [DATA_THR    - 1 : 0]    c_w   ;
  wire     [DATA_THR    - 1 : 0]    p_w   ;
  wire     [DATA_THR    - 1 : 0]    g_w   ;

  // genvar
  genvar                            gvIdx ;
//*** MaiN BODY ****************************************************************
  // output
  assign cout  = c_w[DATA_THR - 1]      ;
  assign so[0] = ai[0] ^ bi[0] ^ cin    ;
  assign so[1] = ai[1] ^ bi[1] ^ c_w[0] ;
  assign so[2] = ai[2] ^ bi[2] ^ c_w[1] ;
  assign so[3] = ai[3] ^ bi[3] ^ c_w[2] ;


  // main
    assign c_w[0] = g_w[0]
                  | ( cin & p_w[0] )                            ;
    assign c_w[1] = g_w[1]
                  | ( g_w[0] & p_w[1] )
                  | ( cin & p_w[0] & p_w[1] )                   ;
    assign c_w[2] = g_w[2]
                  | ( g_w[1] & p_w[2] )
                  | ( g_w[0] & p_w[1] * p_w[2] )
                  | ( cin & p_w[0] & p_w[1] & p_w[2] )          ;
    assign c_w[3] = g_w[3]
                  | ( g_w[2] & p_w[3] )
                  | ( g_w[1] & p_w[2] & p_w[3] )
                  | ( g_w[0] & p_w[1] & p_w[2] & p_w[3] )
                  | ( cin & p_w[0] & p_w[1] & p_w[2] & p_w[3] ) ;
  generate
    for( gvIdx = 'd0 ;gvIdx < DATA_THR ;gvIdx = gvIdx + 'd1 ) begin : datAdderbit
      assign p_w[gvIdx] = ai[gvIdx] | bi[gvIdx] ;
      assign g_w[gvIdx] = ai[gvIdx] & bi[gvIdx] ;
    end
  endgenerate

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule