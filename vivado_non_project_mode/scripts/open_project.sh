#!/usr/bin/env bash
cd "$(dirname "$0")" || exit;

export OUTPUT_DIR=../output
export SRC_DIR=../../design_sources
export CONSTRAINTS_DIR=../../constraint_sources
export SCRIPT_DIR=.
export TOP=top
export TESTBENCH=testbench

mkdir -p "$OUTPUT_DIR/vivado_tempdir"
vivado -mode batch -source tmp_project.tcl -tempDir "$OUTPUT_DIR/vivado_tempdir" -journal "$OUTPUT_DIR/vivado.jou" -log "$OUTPUT_DIR/vivado.log"
