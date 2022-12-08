//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_binary_tree_compressor_array.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [do compress all products based on binary tree 4-2 compressor array]
  //
//------------------------------------------------------------------------------
// stage 1 : PP0 PP1 PP2 PP3 | PP4 PP5 PP6 PP7 | PP8 PP9 PP10 PP11 | PP12 PP13 PP14 PP15
// stage 2 :  SO0_s1  CO0_s1    SO1_s1  CO1_s1 |   SO2_s1  CO2_s1      SO3_s1   CO3_s1
// stage 3 :      SO0_s2            CO0_s2            SO1_s2               CO1_s2
// result  :                          SO0_s3         CO0_s3     
//------------------------------------------------------------------------------
module booth2_mul_binary_tree_compressor_array (
  // global
  clk     ,
  rstn    ,
  // dat_i
  val_i   ,
  ppi     ,
  si      ,
  ei      ,
  // dat_o
  val_o   ,
  so      ,
  co
);

//*** PARAMETER **********************************************************************************************************
  parameter    MUL_IN_WD             = -1                                                                                ;
  parameter    MUL_OUT_WD            = -1                                                                                ;
  localparam   BOOTH2_TRA_WD         = 3                                                                                 ;
  localparam   PRODCUT_OUT_WD        = MUL_IN_WD + 1                                                                     ;
  localparam   BOOTH2_TRA_NUM        = MUL_IN_WD / (BOOTH2_TRA_WD - 1)                                                   ;
  localparam   COM_IN_NUM            = 4                                                                                 ;
  localparam   PAD_SIGN_WD           = 2                                                                                 ;
  localparam   STAGE_1_PP0T3_IN_WD   = ( PRODCUT_OUT_WD ) + ( (COM_IN_NUM - 1) * (BOOTH2_TRA_WD - 1) ) + PAD_SIGN_WD     ;
  localparam   STAGE_1_PP4T7_IN_WD   = STAGE_1_PP0T3_IN_WD + BOOTH2_TRA_WD - 1                                           ;
  localparam   STAGE_1_PP8T11_IN_WD  = STAGE_1_PP4T7_IN_WD                                                               ;
  localparam   STAGE_1_PP12T15_IN_WD = STAGE_1_PP8T11_IN_WD - 1                                                          ;
  localparam   STAGE_2_SC0T1_IN_WD   = STAGE_1_PP0T3_IN_WD + 9                                                           ;
  localparam   STAGE_2_SC2T3_IN_WD   = STAGE_2_SC0T1_IN_WD                                                               ;
  localparam   STAGE_3_SC0T1_IN_WD   = MUL_OUT_WD                                                                        ;
//*** INPUT/OUTPUT *******************************************************************************************************
  // global
  input                                                    clk  ;
  input                                                    rstn ;
  input                                                    val_i;
  // dat_i
  input       [BOOTH2_TRA_NUM * PRODCUT_OUT_WD - 1 : 0]    ppi  ;
  input       [BOOTH2_TRA_NUM                  - 1 : 0]    si   ;
  input       [BOOTH2_TRA_NUM                  - 1 : 0]    ei   ;
  // dat_o
  output                                                   val_o;
  output      [MUL_OUT_WD                      - 1 : 0]    so   ;
  output      [MUL_OUT_WD                      - 1 : 0]    co   ;
//*** WIRE/REG *****************************************************************
  // stage 1
  wire                                                      STAGE_1_val_i_w    ;
  reg                                                       STAGE_1_val_o_r    ;
    // pp0 ~ pp3
  wire        [STAGE_1_PP0T3_IN_WD * COM_IN_NUM - 1 : 0]    STAGE_1_pp0_3_w    ;
  wire        [STAGE_1_PP0T3_IN_WD              - 1 : 0]    STAGE_1_so0_3_w    ;
  wire        [STAGE_1_PP0T3_IN_WD              - 1 : 0]    STAGE_1_co0_3_w    ;
  wire        [STAGE_1_PP0T3_IN_WD              - 1 : 0]    STAGE_1_ca0_3_w    ;
    // pp4 ~ pp7
  wire        [STAGE_1_PP4T7_IN_WD * COM_IN_NUM - 1 : 0]    STAGE_1_pp4_7_w    ;
  wire        [STAGE_1_PP4T7_IN_WD              - 1 : 0]    STAGE_1_so4_7_w    ;
  wire        [STAGE_1_PP4T7_IN_WD              - 1 : 0]    STAGE_1_co4_7_w    ;
  wire        [STAGE_1_PP4T7_IN_WD              - 1 : 0]    STAGE_1_ca4_7_w    ;
    // pp8 ~ pp11
  wire        [STAGE_1_PP8T11_IN_WD * COM_IN_NUM- 1 : 0]    STAGE_1_pp8_11_w   ;
  wire        [STAGE_1_PP8T11_IN_WD             - 1 : 0]    STAGE_1_so8_11_w   ;
  wire        [STAGE_1_PP8T11_IN_WD             - 1 : 0]    STAGE_1_co8_11_w   ;
  wire        [STAGE_1_PP8T11_IN_WD             - 1 : 0]    STAGE_1_ca8_11_w   ;
    // pp12 ~ pp15
  wire        [STAGE_1_PP12T15_IN_WD *COM_IN_NUM- 1 : 0]    STAGE_1_pp12_15_w  ;
  wire        [STAGE_1_PP12T15_IN_WD            - 1 : 0]    STAGE_1_so12_15_w  ;
  wire        [STAGE_1_PP12T15_IN_WD            - 1 : 0]    STAGE_1_co12_15_w  ;
  wire        [STAGE_1_PP12T15_IN_WD            - 1 : 0]    STAGE_1_ca12_15_w  ;
  // stage 2
  wire                                                      STAGE_2_val_i_w    ;
  reg                                                       STAGE_2_val_o_r    ;
    // so0 = so0_3 ; co0 = co0_3 ... 
    // sc means so & co
    // sc0 ~ sc1
  reg         [STAGE_2_SC0T1_IN_WD * COM_IN_NUM - 1 : 0]    STAGE_2_sc0_1_r    ;
  wire        [STAGE_2_SC0T1_IN_WD              - 1 : 0]    STAGE_2_so0_1_w    ;
  wire        [STAGE_2_SC0T1_IN_WD              - 1 : 0]    STAGE_2_co0_1_w    ;
  wire        [STAGE_2_SC0T1_IN_WD              - 1 : 0]    STAGE_2_ca0_1_w    ;
    // sc2 ~ sc3
  reg         [STAGE_2_SC2T3_IN_WD * COM_IN_NUM - 1 : 0]    STAGE_2_sc2_3_r    ;
  wire        [STAGE_2_SC2T3_IN_WD              - 1 : 0]    STAGE_2_so2_3_w    ;
  wire        [STAGE_2_SC2T3_IN_WD              - 1 : 0]    STAGE_2_co2_3_w    ;
  wire        [STAGE_2_SC2T3_IN_WD              - 1 : 0]    STAGE_2_ca2_3_w    ;
  // stage 3
  wire                                                      STAGE_3_val_i_w    ;
  reg                                                       STAGE_3_val_o_r    ;
    // sc0 ~ sc1
  reg         [STAGE_3_SC0T1_IN_WD * COM_IN_NUM - 1 : 0]    STAGE_3_sc0_1_r    ;
  wire        [STAGE_3_SC0T1_IN_WD              - 1 : 0]    STAGE_3_so0_1_w    ;
  reg         [STAGE_3_SC0T1_IN_WD              - 1 : 0]    STAGE_3_so0_1_r    ;
  wire        [STAGE_3_SC0T1_IN_WD              - 1 : 0]    STAGE_3_co0_1_w    ;
  reg         [STAGE_3_SC0T1_IN_WD              - 1 : 0]    STAGE_3_co0_1_r    ;
  wire        [STAGE_3_SC0T1_IN_WD              - 1 : 0]    STAGE_3_ca0_1_w    ;

  // genvar
  genvar                            gvIdx                                      ;
//*** MAIN BODY ****************************************************************
  // output
  // val_o
  assign val_o = STAGE_3_val_o_r ;
  assign so    = STAGE_3_so0_1_r ;
  assign co    = STAGE_3_co0_1_r ;

  // main
  // STAGE3
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_3_val_o_r <= 1'b0 ;
    end
    else begin
      STAGE_3_val_o_r <= STAGE_3_val_i_w ;
    end
  end

  assign STAGE_3_val_i_w = STAGE_2_val_o_r ;
  
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_3_so0_1_r <= 'd0 ;
      STAGE_3_co0_1_r <= 'd0 ;
    end
    else begin
      if( STAGE_3_val_i_w ) begin
        STAGE_3_so0_1_r <= STAGE_3_so0_1_w ;
        STAGE_3_co0_1_r <= STAGE_3_co0_1_w ;
      end
    end
  end

  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_3_sc0_1_r <= 'd0 ;
    end
    else begin
      if( STAGE_2_val_i_w ) begin
        STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd1 - 'd1 -: STAGE_3_SC0T1_IN_WD] <= { 14'b0, STAGE_2_so0_1_w }                              ;
        STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd2 - 'd1 -: STAGE_3_SC0T1_IN_WD] <= { 13'b0, STAGE_2_co0_1_w, 1'b0 }                        ;
        STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd3 - 'd1 -: STAGE_3_SC0T1_IN_WD] <= { STAGE_2_so2_3_w, 14'b0 }                              ;
        STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd4 - 'd1 -: STAGE_3_SC0T1_IN_WD] <= { STAGE_2_co2_3_w[STAGE_2_SC2T3_IN_WD - 2 : 0], 15'b0 } ;        
      end
    end
  end

  booth2_mul_4to2compressor stage3_compressor0(
    .ai    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             ) ,
    .cout  ( STAGE_3_co0_1_w[0]                               ) ,
    .so    ( STAGE_3_so0_1_w[0]                               ) ,
    .co    ( STAGE_3_ca0_1_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_3_SC0T1_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage3ComIdx
      booth2_mul_4to2compressor stage3_compressor(
        .ai    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_3_sc0_1_r[STAGE_3_SC0T1_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_3_ca0_1_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_3_co0_1_w[gvIdx]                             ) ,
        .so    ( STAGE_3_so0_1_w[gvIdx]                             ) ,
        .co    ( STAGE_3_ca0_1_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  // STAGE2
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_2_val_o_r <= 1'b0 ;
    end
    else begin
      STAGE_2_val_o_r <= STAGE_2_val_i_w ;
    end
  end

  assign STAGE_2_val_i_w = STAGE_1_val_o_r ;
  
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_2_sc0_1_r <= 'd0 ;
    end
    else begin
      if( STAGE_1_val_i_w ) begin
        STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd1 - 'd1 -: STAGE_2_SC0T1_IN_WD] <= { 9'b0, STAGE_1_so0_3_w }       ;
        STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd2 - 'd1 -: STAGE_2_SC0T1_IN_WD] <= { 8'b0, STAGE_1_co0_3_w, 1'b0 } ;
        STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd3 - 'd1 -: STAGE_2_SC0T1_IN_WD] <= { 1'b0, STAGE_1_so4_7_w, 6'b0 } ;
        STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd4 - 'd1 -: STAGE_2_SC0T1_IN_WD] <= { STAGE_1_co4_7_w, 7'b0 }       ;        
      end
    end
  end

  booth2_mul_4to2compressor stage2_compressor0(
    .ai    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             ) ,
    .cout  ( STAGE_2_co0_1_w[0]                               ) ,
    .so    ( STAGE_2_so0_1_w[0]                               ) ,
    .co    ( STAGE_2_ca0_1_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_2_SC0T1_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage2Com0T1Idx
      booth2_mul_4to2compressor stage2_compressor(
        .ai    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_2_sc0_1_r[STAGE_2_SC0T1_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_2_ca0_1_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_2_co0_1_w[gvIdx]                             ) ,
        .so    ( STAGE_2_so0_1_w[gvIdx]                             ) ,
        .co    ( STAGE_2_ca0_1_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_2_sc2_3_r <= 'd0 ;
    end
    else begin
      if( STAGE_1_val_i_w ) begin
        STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd1 - 'd1 -: STAGE_2_SC2T3_IN_WD] <= { 7'b0, STAGE_1_so8_11_w }                                 ;
        STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd2 - 'd1 -: STAGE_2_SC2T3_IN_WD] <= { 6'b0, STAGE_1_co8_11_w, 1'b0 }                           ;
        STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd3 - 'd1 -: STAGE_2_SC2T3_IN_WD] <= { STAGE_1_so12_15_w, 8'b0 }                                ;
        STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd4 - 'd1 -: STAGE_2_SC2T3_IN_WD] <= { STAGE_1_co12_15_w[STAGE_1_PP12T15_IN_WD - 2 : 0], 9'b0 } ;        
      end
    end
  end

  booth2_mul_4to2compressor stage2_compressor1(
    .ai    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             ) ,
    .cout  ( STAGE_2_co2_3_w[0]                               ) ,
    .so    ( STAGE_2_so2_3_w[0]                               ) ,
    .co    ( STAGE_2_ca2_3_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_2_SC2T3_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage2Com2T3Idx
      booth2_mul_4to2compressor stage2_compressor(
        .ai    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_2_sc2_3_r[STAGE_2_SC2T3_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_2_ca2_3_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_2_co2_3_w[gvIdx]                             ) ,
        .so    ( STAGE_2_so2_3_w[gvIdx]                             ) ,
        .co    ( STAGE_2_ca2_3_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  // STAGE1
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      STAGE_1_val_o_r <= 1'b0 ;
    end
    else begin
      STAGE_1_val_o_r <= STAGE_1_val_i_w ;
    end
  end

  assign STAGE_1_val_i_w = val_i ;

  assign STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd1 - 'd1 -: STAGE_1_PP0T3_IN_WD] = { 5'b0, ei[0], ~ei[0], ~ei[0], ppi[PRODCUT_OUT_WD * 'd1 - 'd1 -: PRODCUT_OUT_WD] }          ;
  assign STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd2 - 'd1 -: STAGE_1_PP0T3_IN_WD] = { 4'b0, 1'b1, ei[1], ppi[PRODCUT_OUT_WD * 'd2 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[0] }       ;
  assign STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd3 - 'd1 -: STAGE_1_PP0T3_IN_WD] = { 2'b0, 1'b1, ei[2], ppi[PRODCUT_OUT_WD * 'd3 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[1], 2'b0 } ;
  assign STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd4 - 'd1 -: STAGE_1_PP0T3_IN_WD] = { 1'b1, ei[3], ppi[PRODCUT_OUT_WD * 'd4 - 'd1 -: PRODCUT_OUT_WD],1'b0, si[2], 4'b0 }             ;        

  booth2_mul_4to2compressor stage1_compressor0(
    .ai    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             ) ,
    .cout  ( STAGE_1_co0_3_w[0]                               ) ,
    .so    ( STAGE_1_so0_3_w[0]                               ) ,
    .co    ( STAGE_1_ca0_3_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_1_PP0T3_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage1Com0T3Idx
      booth2_mul_4to2compressor stage1_compressor(
        .ai    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_1_pp0_3_w[STAGE_1_PP0T3_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_1_ca0_3_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_1_co0_3_w[gvIdx]                             ) ,
        .so    ( STAGE_1_so0_3_w[gvIdx]                             ) ,
        .co    ( STAGE_1_ca0_3_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  assign STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd1 - 'd1 -: STAGE_1_PP4T7_IN_WD] = { 6'b0, 1'b1, ei[4], ppi[PRODCUT_OUT_WD * 'd5 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[3] }          ;
  assign STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd2 - 'd1 -: STAGE_1_PP4T7_IN_WD] = { 4'b0, 1'b1, ei[5], ppi[PRODCUT_OUT_WD * 'd6 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[4], 2'b0 }    ;
  assign STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd3 - 'd1 -: STAGE_1_PP4T7_IN_WD] = { 2'b0, 1'b1, ei[6], ppi[PRODCUT_OUT_WD * 'd7 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[5], 4'b0 }    ;
  assign STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd4 - 'd1 -: STAGE_1_PP4T7_IN_WD] = { 1'b1, ei[7], ppi[PRODCUT_OUT_WD * 'd8 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[6], 6'b0 }          ;        

  booth2_mul_4to2compressor stage1_compressor1(
    .ai    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             ) ,
    .cout  ( STAGE_1_co4_7_w[0]                               ) ,
    .so    ( STAGE_1_so4_7_w[0]                               ) ,
    .co    ( STAGE_1_ca4_7_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_1_PP4T7_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage1Com4T7Idx
      booth2_mul_4to2compressor stage1_compressor(
        .ai    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_1_pp4_7_w[STAGE_1_PP4T7_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_1_ca4_7_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_1_co4_7_w[gvIdx]                             ) ,
        .so    ( STAGE_1_so4_7_w[gvIdx]                             ) ,
        .co    ( STAGE_1_ca4_7_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  assign STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd1 - 'd1 -: STAGE_1_PP8T11_IN_WD] = { 6'b0, 1'b1, ei[8], ppi[PRODCUT_OUT_WD * 'd9 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[7] }          ;
  assign STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd2 - 'd1 -: STAGE_1_PP8T11_IN_WD] = { 4'b0, 1'b1, ei[9], ppi[PRODCUT_OUT_WD * 'd10 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[8], 2'b0 }   ;
  assign STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd3 - 'd1 -: STAGE_1_PP8T11_IN_WD] = { 2'b0, 1'b1, ei[10], ppi[PRODCUT_OUT_WD * 'd11 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[9], 4'b0 }  ;
  assign STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd4 - 'd1 -: STAGE_1_PP8T11_IN_WD] = { 1'b1, ei[11], ppi[PRODCUT_OUT_WD * 'd12 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[10], 6'b0 }       ;        

  booth2_mul_4to2compressor stage1_compressor3(
    .ai    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                             )  ,
    .cout  ( STAGE_1_co8_11_w[0]                               ) ,
    .so    ( STAGE_1_so8_11_w[0]                               ) ,
    .co    ( STAGE_1_ca8_11_w[0]                               )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_1_PP8T11_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage18T11ComIdx
      booth2_mul_4to2compressor stage1_compressor(
        .ai    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_1_pp8_11_w[STAGE_1_PP8T11_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_1_ca8_11_w[gvIdx - 'd1]                       ) ,
        .cout  ( STAGE_1_co8_11_w[gvIdx]                             ) ,
        .so    ( STAGE_1_so8_11_w[gvIdx]                             ) ,
        .co    ( STAGE_1_ca8_11_w[gvIdx]                             )
      ) ;
    end
  endgenerate

  assign STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd1 - 'd1 -: STAGE_1_PP12T15_IN_WD] = { 5'b0, 1'b1, ei[12], ppi[PRODCUT_OUT_WD * 'd13 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[11] }        ;
  assign STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd2 - 'd1 -: STAGE_1_PP12T15_IN_WD] = { 3'b0, 1'b1, ei[13], ppi[PRODCUT_OUT_WD * 'd14 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[12], 2'b0 }  ;
  assign STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd3 - 'd1 -: STAGE_1_PP12T15_IN_WD] = { 1'b0, 1'b1, ei[14], ppi[PRODCUT_OUT_WD * 'd15 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[13], 4'b0 }  ;
  assign STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd4 - 'd1 -: STAGE_1_PP12T15_IN_WD] = { ei[15], ppi[PRODCUT_OUT_WD * 'd16 - 'd1 -: PRODCUT_OUT_WD], 1'b0, si[14], 6'b0 }              ;        

  booth2_mul_4to2compressor stage1_compressor2(
    .ai    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd0 + 'd0] ) ,
    .bi    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd1 + 'd0] ) ,
    .ci    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd2 + 'd0] ) ,
    .di    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd3 + 'd0] ) ,
    .cin   ( 1'b0                                                 ) ,
    .cout  ( STAGE_1_co12_15_w[0]                                 ) ,
    .so    ( STAGE_1_so12_15_w[0]                                 ) ,
    .co    ( STAGE_1_ca12_15_w[0]                                 )
  ) ;

  generate
    for( gvIdx = 'd1 ;gvIdx < STAGE_1_PP12T15_IN_WD ;gvIdx = gvIdx + 'd1 ) begin : datStage1Com12T15Idx
      booth2_mul_4to2compressor stage1_compressor(
        .ai    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd0 + gvIdx] ) ,
        .bi    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd1 + gvIdx] ) ,
        .ci    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd2 + gvIdx] ) ,
        .di    ( STAGE_1_pp12_15_w[STAGE_1_PP12T15_IN_WD * 'd3 + gvIdx] ) ,
        .cin   ( STAGE_1_ca12_15_w[gvIdx - 'd1]                         ) ,
        .cout  ( STAGE_1_co12_15_w[gvIdx]                               ) ,
        .so    ( STAGE_1_so12_15_w[gvIdx]                               ) ,
        .co    ( STAGE_1_ca12_15_w[gvIdx]                               )
      ) ;
    end
  endgenerate

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule