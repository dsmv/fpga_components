#
# AHDL regression script.
#


# ROOT/TC folders, etc:
#
set ROOT   [pwd]

set FAIL_MSG "TEST finished with ERR"
set PASS_MSG "TEST finished successfully"

set glbl_log "src/clk/ctrl_dcmphase_v6/simulation/log/global_tc_summary.log"
		 	
cd $dsn		

set    glbl_log_file [open $glbl_log w]
puts  $glbl_log_file "Global PROTEQ TC log:"
close $glbl_log_file

#
# Procedure:
#
proc set_and_run {} {
	 set StdArithNoWarnings   1
	 set NumericStdNoWarnings 1
	 set BreakOnAssertion     2

	run -all

	quit -sim
}

proc parse_log { filename tc_name } {
	set err_cnt 0
	set openfile [open $filename r]
	set ret 0
	while {[gets $openfile buffer] >= 0} {
 
		set ret [string first $::PASS_MSG $buffer  1]
		#echo $ret
		if { $ret>0 } {
			incr err_cnt
		}
		
	}
	if {$err_cnt>0} {return "$tc_name PASSED"} else {return "$tc_name FAILED"}
	close $openfile
}
	   
proc run_test { tc_name tc_time } {
 set log_name  "src/clk/ctrl_dcmphase_v6/simulation/log/"
 set log_name $log_name$tc_name.log
	transcript to $log_name
	asim -ieee_nowarn  -O5 +access +r +m+$tc_name $tc_name bhv		  
	run $tc_time	
	endsim;		
	
	set    glog_file [open $::glbl_log a]
	puts  $glog_file [parse_log $log_name $tc_name ]
	close $glog_file
	
}
	   
#
# Main BODY:
#

#
# 
cd $dsn

#
#
onerror {resume}
		
run_test "tc_00_01"  "6 ms"
run_test "tc_00_02"  "6 ms"
run_test "tc_00_03"  "6 ms"


#close $glbl_log_file
		  
exit