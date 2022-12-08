.EXPORT_ALL_VARIABLES:
SHELL          := /bin/bash

PRJ_DIR        := ../..

EDA_TYP        := cds

DUT_TOP        := booth2_mul_top
DUT_INC        := $(PRJ_DIR)/src/booth2_mul_top_inc.f
DUT_LIB        := $(PRJ_DIR)/src/booth2_mul_top_lib.f
DUT_SRC        := $(PRJ_DIR)/src/booth2_mul_top_rtl.f

SIM_TOP        ?= sim_$(DUT_TOP)
SIM_LST        := sim_$(DUT_TOP).f

COV_TOP        ?= $(DUT_TOP)

SEED           ?= 0
DBUG           ?= off

T_V_DIR        ?= check_data
T_V_PTN        ?= none

STP_LVL        ?= local

DSP_PRM        ?= off

DMP_WAV        ?= off
DMP_WAV_BGN    ?= 0
DMP_WAV_LVL    ?= ASTF

BAK_SIM        ?= off

NUM_JOB        ?= 1

include ../script/makefile.mk
