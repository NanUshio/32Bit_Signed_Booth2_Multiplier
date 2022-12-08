//------------------------------------------------------------------------------
  //
  //  Filename       : sim_booth2_mul_top.v
  //  Author         : He Chenlong
  //  Status         : phase 000
  //  Reset          : 2022-12-5
  //  Description    : [testbench] for [booth2_mul_top]
  //
//------------------------------------------------------------------------------

//--- GLOBAL ---------------------------
  // DUT
  //`define DUT_TOP                              -1
  //`define DUT_TOP_STR                          -1

  `include "check_data/dut_setting.vh"

  // SIM
  //`define SIM_TOP                              -1
  //`define SIM_TOP_STR                          -1

  //`define STP_LVL                              -1

  //`define DMP_SHM                              -1
    `define DMP_SHM_FILE                         "simul_data/wave_form.shm"
  //`define DMP_SHM_BGN                          -1
  //`define DMP_SHM_LVL                          -1
  //`define DMP_FSDB                             -1
    `define DMP_FSDB_FILE                        "simul_data/wave_form.fsdb"
  //`define DMP_FSDB_BGN                         -1

  //`define SEED                                 -1
  //`define DBUG                                 -1

//--- LOCAL (VARIABLE) -----------------
  // SIM (chko)
  `define CHKO                                   "on"

  // SIM (dump)
  //`define DUMP_VCD
    `define DUMP_VCD_BGN                         0
  //`define DUMP_EVCD
    `define DUMP_EVCD_BGN                        0

//--- LOCAL (CONSTANT) -----------------
  // SIM (clk)
  `define CLK_FULL                               10
  `define CLK_HALF                               ( `CLK_FULL / 2 )

  // SIM (chki)
  `define CHKI_AI_FILE                           "check_data/Ai.dat"
  `define CHKI_BI_FILE                           "check_data/Bi.dat"

  // SIM (chko)
  `define CHKO_MO_FILE                           "check_data/Mo.dat"

  // SIM (dump)
  `define DUMP_VCD_FILE                          "simul_data/wave_form.vcd"
  `define DUMP_EVCD_FILE                         "simul_data/wave_form.evcd"

  // DUT (setting)

//---- EVENT -----------------------
module `SIM_TOP ;

event chki_ai_event ;
event chki_bi_event ;
event chko_mo_event ;

//*** PARAMETER ****************************************************************
  // NULL
//*** INPUT/OUTPUT *************************************************************

  // global
  reg                                          clk             ;
  reg                                          rstn            ;
  // dat_i
  reg                                          val_i           ;
  reg  signed [`MUL_IN_WD  - 1 : 0]            ai              ;
  reg  signed [`MUL_IN_WD  - 1 : 0]            bi              ;
  // dat_o
  wire                                         val_o           ;
  wire signed [`MUL_OUT_WD - 1 : 0]            dat_o           ;

//*** WIRE/REG *****************************************************************

  // seed
  integer                                      seed_r          ;

  // counter
  integer                                      cnt             ;
  integer                                      cnt_num_r       ;

//*** SUB BENCH ****************************************************************
  // Null
//*** MAIN BODY ****************************************************************
//--- PROC -----------------------------
  // clk
  initial begin
    clk = 'd0 ;
    forever begin
      #`CLK_HALF ;
      clk = ! clk ;
    end
  end

  // rstn
  initial begin
    rstn = 'd0 ;
    #( 5 * `CLK_FULL );
    @(negedge clk );
    rstn = 'd1 ;
  end

  // seed
  initial begin
    seed_r = `SEED ;
  end

  // main
  initial begin
    // init
    val_i  = 'd0 ;
    ai     = 'd0 ;
    bi     = 'd0 ;

    // delay
    #( 5 * `CLK_FULL );

    // log
    $write( "\n\n*** CHECK %s BEGIN ! ***\n" ,`DUT_TOP_STR );

    // delay
    #( 5 * `CLK_FULL );
    $display( "" );

    // core loop
    for( cnt_num_r = 'd0 ; cnt_num_r < `TEST_NUM ; cnt_num_r = cnt_num_r + 'd1 ) begin
      // start
      // log
      $display( "\t at %08d ns, launching Dat %02d..." ,$time ,cnt_num_r );
      
      @( posedge clk ) ;
      val_i <= 1 ;
      -> chki_ai_event ;
      -> chki_bi_event ;
      // wait
      @( negedge clk ) ;
      // check
      if( val_o ) begin
        -> chko_mo_event  ;
      end
    end
    @( posedge clk ) ;
    val_i <= 0 ;

    // log
    #( 1000 * `CLK_FULL );
    $display( "\n\n*** CHECK %s END ! ***\n" ,`DUT_TOP_STR );
    $finish;
  end


//--- INST -----------------------------
  // begin of DUT
    `DUT_TOP # (
      .MUL_IN_WD  ( `MUL_IN_WD  ),
      .MUL_OUT_WD ( `MUL_OUT_WD )
    ) dut (
      .clk        ( clk        ),
      .rstn       ( rstn       ),
      .val_i      ( val_i      ),
      .ai         ( ai         ),
      .bi         ( bi         ),
      .val_o      ( val_o      ),
      .dat_o      ( dat_o      )
    );
  // end  of DUT

//--- DUMP -----------------------------
  // shm
  `ifdef DMP_SHM
    initial begin
      if( `DMP_SHM=="on" ) begin
        #`DMP_SHM_BGN ;
        $shm_open( `DMP_SHM_FILE );
        $shm_probe( `SIM_TOP ,`DMP_SHM_LVL );
        #( 10 * `CLK_FULL );
        $display( "\t\t dump (shm,%s) to this test is on!" ,`DMP_SHM_LVL );
      end
    end
  `endif

  // fsdb
  `ifdef DMP_FSDB
    initial begin
      if( `DMP_FSDB=="on" ) begin
        #`DMP_FSDB_BGN ;
        $fsdbDumpfile( `DMP_FSDB_FILE );
        $fsdbDumpvars( `SIM_TOP );
        #( 10 * `CLK_FULL );
        $display( "\t\t dump (fsdb) to this test is on!" );
      end
    end
  `endif

  // vcd
  `ifdef DUMP_VCD
    initial begin
      #`DUMP_VCD_BGN ;
      $dumpfile( `DUMP_VCD_FILE );
      $dumpvars( 'd0, `SIM_TOP );
      #( 10 * `CLK_FULL );
      $display( "\t\t dump (vcd) to this test is on!" );
    end
  `endif

  // evcd
  `ifdef DUMP_EVCD
    initial begin
      #`DUMP_EVCD_BGN ;
      $dumpports( dut ,`DUMP_EVCD_FILE );
      #( 10 * `CLK_FULL );
      $display( "\t\t dump (evcd) to this test is on!" );
    end
  `endif


//--- TASK -----------------------------
  // chki_ai_event
  initial begin
    CHKI_AI_DAT ;
  end

  task CHKI_AI_DAT ;
   // variables
   integer                               fpt_ai  ;
   integer                               tmp     ;
   integer                               cnt_ai  ;
   reg   signed  [`MUL_IN_WD - 1 : 0]    dat     ;

  // main body
  begin
    // open file
    fpt_ai = $fopen( `CHKI_AI_FILE ,"r" );
    // top
    forever begin
      // wait
      @( chki_ai_event );
      // read ai
      tmp = $fscanf( fpt_ai ,"%x" ,dat );
      ai = dat;
    end
  end
  endtask
  
  // chki_bi_event
  initial begin
    CHKI_BI_DAT ;
  end

  task CHKI_BI_DAT ;
   // variables
   integer                               fpt_bi  ;
   integer                               tmp     ;
   integer                               cnt_bi  ;
   reg  signed   [`MUL_IN_WD - 1 : 0]    dat     ;

  // main body
  begin
    // open file
    fpt_bi = $fopen( `CHKI_BI_FILE ,"r" );
    // top
    forever begin
      // wait
      @( chki_bi_event );
      // read bi
      tmp = $fscanf( fpt_bi ,"%x" ,dat );
      bi = dat;
    end
  end
  endtask

  // chko_mo_event
  initial begin
    CHKI_MO_DAT ;
  end

  task CHKI_MO_DAT ;
   // variables
   integer                           fpt_mo  ;
   integer                           tmp     ;
   integer                           cnt_mo  ;
   reg signed [`MUL_OUT_WD - 1 : 0]  sim_dat ;
  // main body
  begin
    // open file
    fpt_mo = $fopen( `CHKO_MO_FILE ,"r" );
    // top
    forever begin
      // wait
      @( chko_mo_event );
      // read mo
      tmp = $fscanf( fpt_mo ,"%x" ,sim_dat );
      if( sim_dat !== dat_o ) begin
        $display("\n\t ERROR: at %08d ns, Mo should be %x, however is %x!\n"
          ,$time
          ,sim_dat
          ,dat_o
        );
      end
    end
  end
  endtask

//*** DEBUG ********************************************************************

  `ifdef DBUG

  `endif

endmodule
