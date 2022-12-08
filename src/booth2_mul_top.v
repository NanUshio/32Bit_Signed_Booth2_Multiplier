//-------------------------------------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_top.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [top] for [32 bit signed booth2 mul]
  //
//-------------------------------------------------------------------------------------------------------------
// stage 1 ( 1 clock ) : generate all product
// stage 2 ( 3 clock ) : binary tree compressor
// stage 3 ( 1 clock ) : 64 bit adder a + b = sum ( a and b is from binary tree compressor) 
// stage 4 ( 1 clock ) : 64 bit adder c + sum = dat_o ( c is the missing add one for highest pp)
//-------------------------------------------------------------------------------------------------------------
module booth2_mul_top (
  // global
  clk     ,
  rstn    ,
  // dat_i
  val_i   ,
  ai      ,
  bi      ,
  // dat_o
  val_o   ,
  dat_o
);

//*** PARAMETER ****************************************************************
  parameter    MUL_IN_WD             = -1                                      ;
  parameter    MUL_OUT_WD            = -1                                      ;
  localparam   BOOTH2_TRA_WD         = 3                                       ;
  localparam   PRODCUT_OUT_WD        = MUL_IN_WD + 1                           ;
  localparam   BOOTH2_TRA_NUM        = MUL_IN_WD / (BOOTH2_TRA_WD - 1)         ;
  localparam   AHEAD_ADD_WD          = MUL_OUT_WD                              ;
//*** INPUT/OUTPUT *************************************************************
  // global
  input                                                    clk  ;
  input                                                    rstn ;
  input                                                    val_i;
  // dat_i
  input  signed  [MUL_IN_WD                    - 1 : 0]    ai   ;
  input  signed  [MUL_IN_WD                    - 1 : 0]    bi   ;
  // dat_o
  output                                                   val_o;
  output signed  [MUL_OUT_WD                   - 1 : 0]    dat_o;
//*** WIRE/REG *****************************************************************
  // stage 1 GEAP ：Genrate All Product
  wire                                                    GEAP_val_i_w         ;
  wire       [MUL_IN_WD                       - 1 : 0]    GEAP_dat_a_i_w       ;
  wire       [MUL_IN_WD                       - 1 : 0]    GEAP_dat_b_i_w       ;
  wire                                                    GEAP_val_o_w         ;
  wire       [BOOTH2_TRA_NUM * PRODCUT_OUT_WD - 1 : 0]    GEAP_dat_pp_o_w      ;
  wire       [BOOTH2_TRA_NUM                  - 1 : 0]    GEAP_dat_s_o_w       ;
  wire       [BOOTH2_TRA_NUM                  - 1 : 0]    GEAP_dat_e_o_w       ;
  // stage 2 BTCA : Binary Tree Compressor Array
  wire                                                    BTCA_val_i_w         ;
  wire       [BOOTH2_TRA_NUM * PRODCUT_OUT_WD - 1 : 0]    BTCA_dat_pp_i_w      ;
  wire       [BOOTH2_TRA_NUM                  - 1 : 0]    BTCA_dat_s_i_w       ;
  wire       [BOOTH2_TRA_NUM                  - 1 : 0]    BTCA_dat_e_i_w       ;
  wire                                                    BTCA_val_o_w         ;
  wire       [MUL_OUT_WD                      - 1 : 0]    BTCA_dat_s_o_w       ;
  wire       [MUL_OUT_WD                      - 1 : 0]    BTCA_dat_c_o_w       ;
  // stage 3 ADDR : 64 bit Adder in stage 3
  wire                                                    ADD3_val_i_w         ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD3_dat_a_i_w       ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD3_dat_b_i_w       ;
  wire                                                    ADD3_val_o_w         ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD3_dat_sum_o_w     ;
  // stage 4 ADDR : 64 bit Adder in stage 4
  wire                                                    ADD4_val_i_w         ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD4_dat_a_i_w       ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD4_dat_b_i_w       ;
  wire                                                    ADD4_val_o_w         ;
  wire       [AHEAD_ADD_WD                    - 1 : 0]    ADD4_dat_sum_o_w     ;
  // pipline delay
  wire                                                    DLY_highest_pp_s_w   ;
  reg                                                     DLY_highest_pp_s_r0  ;
  reg                                                     DLY_highest_pp_s_r1  ;
  reg                                                     DLY_highest_pp_s_r2  ;
  reg                                                     DLY_highest_pp_s_r3  ;


  // genvar
  genvar                                                  gvIdx                ;
//*** MAIN BODY ****************************************************************
  // output
  assign val_o = ADD4_val_o_w     ;
  assign dat_o = ADD4_dat_sum_o_w ;

  // pipline delay
  assign DLY_highest_pp_s_w = GEAP_dat_s_o_w[BOOTH2_TRA_NUM - 1] ;
  always @ ( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      DLY_highest_pp_s_r0 <= 1'b0 ;
      DLY_highest_pp_s_r1 <= 1'b0 ;
      DLY_highest_pp_s_r2 <= 1'b0 ;
      DLY_highest_pp_s_r3 <= 1'b0 ;
    end
    else begin
      if( BTCA_val_i_w ) begin
        DLY_highest_pp_s_r0 <= DLY_highest_pp_s_w  ;     
      end
      DLY_highest_pp_s_r1 <= DLY_highest_pp_s_r0   ;
      DLY_highest_pp_s_r2 <= DLY_highest_pp_s_r1   ;
      if( ADD3_val_i_w ) begin
        DLY_highest_pp_s_r3 <= DLY_highest_pp_s_r2 ;
      end
    end
  end

  // stage 1 GEAP ：Genrate All Product
  assign GEAP_val_i_w   = val_i ;
  assign GEAP_dat_a_i_w = ai    ;
  assign GEAP_dat_b_i_w = bi    ;
  booth2_mul_all_pp_generator #(
    .MUL_IN_WD ( MUL_IN_WD )
  ) booth2_mul_all_pp_generator(
    .clk    ( clk             ) ,
    .rstn   ( rstn            ) ,
    .val_i  ( GEAP_val_i_w    ) ,
    .ai     ( GEAP_dat_a_i_w  ) ,
    .bi     ( GEAP_dat_b_i_w  ) ,
    .val_o  ( GEAP_val_o_w    ) ,
    .ppo    ( GEAP_dat_pp_o_w ) ,
    .so     ( GEAP_dat_s_o_w  ) ,
    .eo     ( GEAP_dat_e_o_w  )
  );
  // stage 2 BTCA : Binary Tree Compressor Array
  assign BTCA_val_i_w    = GEAP_val_o_w    ;
  assign BTCA_dat_pp_i_w = GEAP_dat_pp_o_w ;
  assign BTCA_dat_s_i_w  = GEAP_dat_s_o_w  ;
  assign BTCA_dat_e_i_w  = GEAP_dat_e_o_w  ;
  booth2_mul_binary_tree_compressor_array #(
    .MUL_IN_WD  ( MUL_IN_WD  )  ,
    .MUL_OUT_WD ( MUL_OUT_WD )
  ) booth2_mul_binary_tree_compressor_array(
    .clk    ( clk             ) ,
    .rstn   ( rstn            ) ,
    .val_i  ( BTCA_val_i_w    ) ,
    .ppi    ( BTCA_dat_pp_i_w ) ,
    .si     ( BTCA_dat_s_i_w  ) ,
    .ei     ( BTCA_dat_e_i_w  ) ,
    .val_o  ( BTCA_val_o_w    ) ,
    .so     ( BTCA_dat_s_o_w  ) ,
    .co     ( BTCA_dat_c_o_w  )
  );

  // stage 3 ADD3 : 64 bit carry look ahead adder in stage 3
  assign ADD3_val_i_w       = BTCA_val_o_w   ;
  assign ADD3_dat_a_i_w     = BTCA_dat_s_o_w ;
  assign ADD3_dat_b_i_w     = { BTCA_dat_c_o_w[AHEAD_ADD_WD - 2 : 0] , 1'b0 } ;
  booth2_mul_ahead_adder #(
    .DATA_THR( AHEAD_ADD_WD      )
  ) booth2_mul_64bit_ahead_adder_s3(
    .clk    ( clk                ) ,
    .rstn   ( rstn               ) ,
    .val_i  ( ADD3_val_i_w       ) ,
    .ai     ( ADD3_dat_a_i_w     ) ,
    .bi     ( ADD3_dat_b_i_w     ) ,
    .cin    ( 1'b0 ) ,
    .val_o  ( ADD3_val_o_w       ) ,
    .cout   ( /* unused */       ) ,
    .so     ( ADD3_dat_sum_o_w   )
  ) ;

  // stage 4 ADD4 : 64 bit carry look ahead adder in stage 4
  assign ADD4_val_i_w       = ADD3_val_o_w                        ;
  assign ADD4_dat_a_i_w     = ADD3_dat_sum_o_w                    ;
  assign ADD4_dat_b_i_w     = {33'b0, DLY_highest_pp_s_r3, 30'b0} ;
  booth2_mul_ahead_adder #(
    .DATA_THR( AHEAD_ADD_WD      )
  ) booth2_mul_64bit_ahead_adder_s4(
    .clk    ( clk                ) ,
    .rstn   ( rstn               ) ,
    .val_i  ( ADD4_val_i_w       ) ,
    .ai     ( ADD4_dat_a_i_w     ) ,
    .bi     ( ADD4_dat_b_i_w     ) ,
    .cin    ( 1'b0               ) ,
    .val_o  ( ADD4_val_o_w       ) ,
    .cout   ( /* unused */       ) ,
    .so     ( ADD4_dat_sum_o_w   )
  ) ;

//*** DEBUG ********************************************************************

  `ifdef DBUG
    // NULL
  `endif
endmodule