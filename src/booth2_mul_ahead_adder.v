//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_ahead_adder.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [do DATA_THR bit adder based on 4 bit adder]
  //
//------------------------------------------------------------------------------

module booth2_mul_ahead_adder (
  // global
  clk     ,
  rstn    ,
  // dat_i
  val_i   ,
  ai      ,
  bi      ,
  cin     ,
  // dat_o
  val_o   ,
  cout    ,
  so
);

//*** PARAMETER ****************************************************************
  parameter  DATA_THR       = -1 ;
  localparam BASIC_ADDER_WD = 4  ;
//*** INPUT/OUTPUT *************************************************************
  // global
  input                                              clk   ;
  input                                              rstn  ;
  input                                              val_i ;
  // dat_i
  input       [DATA_THR                  - 1 : 0]    ai    ;
  input       [DATA_THR                  - 1 : 0]    bi    ;
  input                                              cin   ;
  // dat_o
  output  reg                                        val_o ;
  output  reg                                        cout  ;
  output  reg [DATA_THR                  - 1 : 0]    so    ;
//*** WIRE/REG *****************************************************************
  wire        [DATA_THR / BASIC_ADDER_WD - 1 : 0]    c_w   ;
  wire        [DATA_THR                  - 1 : 0]    s_w   ;
  // genvar
  genvar                            gvIdx ;
//*** MAIN BODY ****************************************************************
  // output
  // val_o
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      val_o <= 1'b0 ;
    end
    else begin
      val_o <= val_i ;
    end
  end
  // cout
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cout <= 1'b0 ;
    end
    else begin
      if( val_i ) begin
        cout <= c_w[DATA_THR / BASIC_ADDER_WD - 1] ;
      end
    end
  end
  // so
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      so <= 'd0 ;
    end
    else begin
      if( val_i ) begin
        so <= s_w ;
      end
    end
  end

  // main
  booth2_mul_4bit_ahead_adder adder0(
    .ai      (  ai[BASIC_ADDER_WD * 'd1 - 'd1 -: BASIC_ADDER_WD]  ) ,
    .bi      (  bi[BASIC_ADDER_WD * 'd1 - 'd1 -: BASIC_ADDER_WD]  ) ,
    .cin     (  1'b0                                              ) ,
    .cout    (  c_w[0]                                            ) ,
    .so      (  s_w[BASIC_ADDER_WD * 'd1 - 'd1 -: BASIC_ADDER_WD] ) 
  ) ;

  generate
    for( gvIdx = 'd2 ;gvIdx < DATA_THR / BASIC_ADDER_WD + 1;gvIdx = gvIdx + 'd1 ) begin : datAdderStage
      booth2_mul_4bit_ahead_adder adder(
        .ai      (  ai[BASIC_ADDER_WD * gvIdx - 'd1 -: BASIC_ADDER_WD]  ) ,
        .bi      (  bi[BASIC_ADDER_WD * gvIdx - 'd1 -: BASIC_ADDER_WD]  ) ,
        .cin     (  c_w[gvIdx - 'd2]                                    ) ,
        .cout    (  c_w[gvIdx - 'd1]                                    ) ,
        .so      (  s_w[BASIC_ADDER_WD * gvIdx - 'd1 -: BASIC_ADDER_WD] ) 
      ) ;
    end
  endgenerate

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule