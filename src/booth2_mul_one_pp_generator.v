//------------------------------------------------------------------------------
  //
  //  Filename       : booth2_mul_one_pp_generator.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-4
  //  Description    : [logic] to [generate one product]
  //
//------------------------------------------------------------------------------

module booth2_mul_one_pp_generator (
  // dat_i
  ai      ,
  bi      ,
  // dat_o
  ppo     ,
  so      ,
  eo
);

//*** PARAMETER ****************************************************************
  // global
  parameter    MUL_IN_WD      = -1             ;
  localparam   BOOTH2_TRA_WD  = 3              ;
  localparam   PRODCUT_OUT_WD = MUL_IN_WD + 1  ;
//*** INPUT/OUTPUT *************************************************************
  // dat_i
  input    [MUL_IN_WD        - 1 : 0]    ai    ;
  input    [BOOTH2_TRA_WD    - 1 : 0]    bi    ;
  // dat_o
  output   [PRODCUT_OUT_WD   - 1 : 0]    ppo   ;
  output                                 so    ;
  output                                 eo    ;
//*** WIRE/REG *****************************************************************
  reg                                    e_w   ;
  reg      [PRODCUT_OUT_WD   - 1 : 0]    pp_w  ;
//*** MaiN BODY ****************************************************************
  // output
  assign so  = bi[BOOTH2_TRA_WD - 1] ;
  assign eo  = e_w  ;
  assign ppo = pp_w ;

  // main
  always @( * ) begin
    case( bi )
      'b000 : begin
        pp_w = 'd0 ;
        e_w  = 'd1 ;
      end
      'b001 , 'b010 : begin
        pp_w = {ai[MUL_IN_WD - 'd1] , ai} ;
        e_w  = ~ai[MUL_IN_WD - 'd1] ;
      end
      'b011 : begin
        pp_w = {ai , 1'b0} ;
        e_w  = ~ai[MUL_IN_WD - 'd1] ;
      end
      'b100 : begin
        pp_w = ~({ai , 1'b0}) ;
        e_w  = ai[MUL_IN_WD - 'd1] ;
      end
      'b101 , 'b110 : begin
        pp_w = ~({ai[MUL_IN_WD - 'd1] , ai}) ;
        e_w  = ai[MUL_IN_WD - 'd1] ;
      end
      'b111 : begin
        pp_w = {PRODCUT_OUT_WD{1'b1}} ;
        e_w  = 'd0 ;
      end
      default : begin
        pp_w = 'd0 ;
        e_w  = 'd1 ;
      end
    endcase
  end

//*** DEBUG ********************************************************************
  `ifdef DBUG
    // NULL
  `endif
endmodule