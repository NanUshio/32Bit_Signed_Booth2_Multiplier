#*** PARAMETEr *****************************************************************
SHELL = /bin/bash

# EDA_CMD
ifeq ($(EDA_TYP), cds)
    EDA_CMD = ncverilog         \
              $(EDA_OPT_SIM)    \
              $(EDA_OPT_DEF)    \
              $(EDA_OPT_LST)    \
              $(EDA_OPT_LOG)
else
    EDA_CMD = vlogan                   \
              -full64                  \
              -debug_access+all        \
              $(EDA_OPT_DEF)           \
              $(EDA_OPT_LST)           \
              -l simul_data/com.log   ;\
              vcs                      \
              -R                       \
              $(EDA_OPT_SIM)           \
              $(EDA_OPT_LOG)
endif

# EDA_OPT_SIM
ifeq ($(EDA_TYP), cds)
    EDA_OPT_SIM = +access+r             \
                  +nospecify            \
                  +ncseq_udp_delay+1    \
                  +nctop+$(SIM_TOP)
else
    EDA_OPT_SIM = -full64              \
                  -debug_access+all    \
                  +nospecify           \
                  $(SIM_TOP)
endif

# EDA_OPT_DEF
ifeq ($(EDA_TYP), cds)
    EDA_OPT_DEF = $(EDA_OPT_DEF_TMP)                        \
                  +define+DMP_SHM=\"$(DMP_WAV)\"            \
                  +define+DMP_SHM_BGN=$(DMP_WAV_BGN)        \
                  +define+DMP_SHM_LVL=\"$(DMP_WAV_LVL)\"
else
    EDA_OPT_DEF = $(EDA_OPT_DEF_TMP)                     \
                  +define+DMP_FSDB=\"$(DMP_WAV)\"        \
                  +define+DMP_FSDB_BGN=$(DMP_WAV_BGN)
endif
EDA_OPT_DEF_TMP = +define+SIM_TOP=$(SIM_TOP)            \
                  +define+SIM_TOP_STR=\"$(SIM_TOP)\"    \
                  +define+DUT_TOP=$(DUT_TOP)            \
                  +define+DUT_TOP_STR=\"$(DUT_TOP)\"    \
                  +define+SEED=$(SEED)                  \
                  +define+DBUG=\"$(DBUG)\"              \
                  +define+STP_LVL=\"$(STP_LVL)\"

# EDA_OPT_LST
EDA_OPT_LST = -f inc_unique.f    \
              -f lft_unique.f

# EDA_OPT_LOG
EDA_OPT_LOG = -l simul_data/sim.log


#*** USAGE *********************************************************************
default:
	@ clear
	@ echo "MAKE TARGETS:                                                                                                                     "
	@ echo "  Single Targets                                                                                                                  "
	@ echo "    com_view                                                                         elaborate designs with ncverilog             "
	@ echo "                                                                                     show the elaboration warnings and errors     "
	@ echo "    chk_view                                                                         elaborate designs with verdi                 "
	@ echo "                                                                                     show the elaboration warnings and errors     "
	@ echo "    sim              [EDA_TYP=<vendor>]                                              simulate designs with ncverilog              "
	@ echo "                     [SEED=<seed>] [debug=<state>]                                                                                "
	@ echo "                     [DMP_WAV=<state>] [DMP_WAV_BGN=<time>] [DMP_WAV_LVL=<level>]                                                 "
	@ echo "                     [STP_LVL=<state>]                                                                                            "
	@ echo "    sim_view         [EDA_TYP=<vendor>]                                              show the waveform                            "
	@ echo "    cov              [COV_TOP=<module_name>]                                         do coverage collection with ncverilog        "
	@ echo "    cov_view                                                                         show the coverage reports                    "
	@ echo "    clean                                                                            clean temperary files                        "
	@ echo "    cleanall                                                                         clean all generated files                    "
	@ echo "                                                                                                                                  "
	@ echo "                                                                                                                                  "
	@ echo "  Parameters                                                                                                                      "
	@ echo "    EDA_TYP          syn / cds                                                       type (vendor) of eda (synopsys, cadence)     "
	@ echo "    COV_TOP                                                                          name of the module to do coverage collection "
	@ echo "    SEED             %d                                                              seed of random function                      "
	@ echo "    DBUG             on / off                                                        enable debug code                            "
	@ echo "    T_V_DIR                                                                          directory of the interested test vectors     "
	@ echo "    T_V_PTN                                                                          pattern of the interested test vectors       "
	@ echo "    DSP_PRM          on / off                                                        display parameters                           "
	@ echo "    DMP_WAV          on / off                                                        dump shm                                     "
	@ echo "    DMP_WAV_BGN      %d                                                              begin time to dump shm                       "
	@ echo "    DMP_WAV_LVL      as (all) / a (just tb)                                          dump level of shm                            "
	@ echo "    STP_LVL          global / local / off                                            stop all/cur/no case when encounter any error"
	@ echo "    BAK_SIM          on / off                                                        backup simulation results                    "
	@ echo "    NUM_JOB          %d                                                              number of jobs running parallelly            "
	@ echo "                                                                                                                                  "
	@ echo "NOTE:                                                                                                                             "
	@ echo "                                                                                                                                  "
	@ echo "                                                                                                                                  "


#*** MAIN BODY *****************************************************************
#--- SINGLE TASKS ----------------------
full2unique:
	@ echo "-f $(SIM_LST)" >  temp.f
	@ echo "-f $(DUT_INC)" >> temp.f
	@ echo "-f $(DUT_LIB)" >> temp.f
	@ echo "-f $(DUT_SRC)" >> temp.f
	@ chmod a+x ../script/full2unique.pl
	@ ../script/full2unique.pl temp.f inc_unique.f "INC"
	@ ../script/full2unique.pl temp.f lft_unique.f "LFT"

com_view: clean full2unique
	@  mkdir -p simul_data
	@- $(EDA_CMD) +elaborate
	@  echo '-----------------------------------'
	@  echo '- WARNINGS                        -'
	@  echo '-----------------------------------'
	@- cat simul_data/sim.log    \
	   | grep    '*W'            \
	   | grep -v 'MRSTAR'        \
	   | grep -v 'RECOME'
	@  echo '-----------------------------------'
	@  echo '- ERRORS                          -'
	@  echo '-----------------------------------'
	@- cat simul_data/sim.log    \
	   | grep    '*E'

chk_view: clean full2unique
	@  mkdir -p simul_data
	@  echo 'PLEASE WAIT FOR A LITTLE WHILE...'
	@  verdi -sx              \
	         -nogui           \
	         $(EDA_OPT_DEF)   \
	         $(EDA_OPT_LST) > /dev/null
	@  cp verdiLog/compiler.log simul_data/com.log
	@  echo '-----------------------------------'
	@  echo '- WARNINGS                        -'
	@  echo '-----------------------------------'
	@- cat simul_data/com.log              \
	   | grep -v 'Unknown argument -sx'    \
	   | grep    '*Warning*' -A 1
	@  echo '-----------------------------------'
	@  echo '- ERRORS                          -'
	@  echo '-----------------------------------'
	@- cat simul_data/com.log        \
	   | grep -v 'redefined'         \
	   | grep    '*Error*'   -A 1    \

sim: full2unique
	@ mkdir -p simul_data
	@ $(EDA_CMD)

sim_view:
	@ if [ $(EDA_TYP) = cds ]                                 ;\
	  then                                                     \
	    simvision -64bit                                       \
	              -waves                                       \
	              simul_data/wave_form.shm/wave_form.trn &     \
	  else                                                     \
	    verdi -sx                                              \
	          -ssf                                             \
	          simul_data/wave_form.fsdb &                      \
	  fi

cov: full2unique
	@ $(EDA_CMD)                  \
	  +nccovdut+$(COV_TOP)        \
	  +nccoverage+all             \
	  +nccovworkdir+simul_data    \
	  -covoverwrite

cov_view:
	@ iccr -GUI -test "simul_data/scope/test" &

clean:
	@ rm -rf INCA_libs
	@ rm -rf *.bak*
	@ rm -rf *.key*
	@ rm -rf *.log*
	@ rm -rf *.rpt*
	@ rm -rf *.sim*
	@ rm -rf *.tmp*
	@ rm -rf *.txt*
	@ rm -rf *verdi*
	@ rm -rf *novas*
	@ rm -rf *64*
	@ rm -rf *AN.DB*
	@ rm -rf *csrc*
	@ rm -rf *simv*
	@ rm -rf *ucli*

cleanall:: clean
	@ rm -rf .simvision
	@ rm -rf simul_data
