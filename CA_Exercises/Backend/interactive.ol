
package require openlane
prep -design . -ignore_mismatches -tag 260420-180706_SOLUTION1_simple_program_and_MULT1
set_odb ./runs/260420-180706_SOLUTION1_simple_program_and_MULT1/results/floorplan/cpu.odb
set_def ./runs/260420-180706_SOLUTION1_simple_program_and_MULT1/results/floorplan/cpu.def
or_gui
