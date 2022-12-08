//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_all_pp_generator.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [generate all product]
  //
//------------------------------------------------------------------------------

module booth2_mul_all_pp_generator (
  // global
  clk     ,
  rstn    ,
  // dat_i
  val_i   ,
  ai      ,
  bi      ,
  // dat_o
  val_o   ,
  ppo     ,
  so      ,
  eo
);

//*** PARAMETER ****************************************************************
  parameter    MUL_IN_WD      = -1                              ;
  localparam   BOOTH2_TRA_WD  = 3                               ;
  localparam   PRODCUT_OUT_WD = MUL_IN_WD + 1                   ;
  localparam   BOOTH2_TRA_NUM = MUL_IN_WD / (BOOTH2_TRA_WD - 1) ;
//*** INPUT/OUTPUT *************************************************************
  // global
  input                                                    clk  ;
  input                                                    rstn ;
  input                                                    val_i;
  // dat_i
  input       [MUL_IN_WD                       - 1 : 0]    ai   ;
  input       [MUL_IN_WD                       - 1 : 0]    bi   ;
  // dat_o
  output  reg                                              val_o;
  output  reg [BOOTH2_TRA_NUM * PRODCUT_OUT_WD - 1 : 0]    ppo  ;
  output  reg [BOOTH2_TRA_NUM                  - 1 : 0]    so   ;
  output  reg [BOOTH2_TRA_NUM                  - 1 : 0]    eo   ;
//*** WIRE/REG *****************************************************************
  wire        [MUL_IN_WD                           : 0]    b_w  ;
  wire        [BOOTH2_TRA_NUM * PRODCUT_OUT_WD - 1 : 0]    pp_w ;
  wire        [BOOTH2_TRA_NUM                  - 1 : 0]    s_w  ;
  wire        [BOOTH2_TRA_NUM                  - 1 : 0]    e_w  ;
  // genvar
  genvar                                                   gvIdx;
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
  // ppo
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      ppo <= 'd0 ;
    end
    else begin
      if( val_i ) begin
        ppo <= pp_w ;
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
  // eo
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      eo <= 'd0 ;
    end
    else begin
      if( val_i ) begin
        eo <= e_w ;
      end
    end
  end

  // main
  generate
    for( gvIdx = 'd0 ;gvIdx < BOOTH2_TRA_NUM ;gvIdx = gvIdx + 'd1 ) begin : datPpGenStage
      booth2_mul_one_pp_generator #(
        .MUL_IN_WD ( MUL_IN_WD )
      ) one_pp_generator(
          .ai     ( ai ) ,
          .bi     ( b_w[ (gvIdx + 'd1) * (BOOTH2_TRA_WD - 'd1) -: BOOTH2_TRA_WD]  ) ,
          .ppo    ( pp_w[ (gvIdx + 'd1) * PRODCUT_OUT_WD - 'd1 -: PRODCUT_OUT_WD] ) ,
          .so     ( s_w[gvIdx]                                                    ) ,
          .eo     ( e_w[gvIdx]                                                    )
      ) ;
    end
  endgenerate
  
  assign b_w = {bi , 1'b0} ; 

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule