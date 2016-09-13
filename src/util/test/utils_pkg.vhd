----------------------------------------------------------------------------------
-- Company:         ;)
-- Engineer:        Kuzmi4
-- 
-- Create Date:     17:40:25 05/21/2010 
-- Design Name:     
-- Module Name:     utils_pkg - VHDL package
-- Project Name:    
-- Target Devices:  
-- Tool versions:   
-- Description:     
--                  TBD
--                  
--                  
-- Revision: 
-- Revision 0.01 - File Created
--                  
--                  
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;
use std.env.all;

package utils_pkg is
-- Stop SIM proc
procedure utils_stop_simulation;
-- Print STRING to transcript-file
procedure utils_print(text: string);

end package utils_pkg;

package body utils_pkg is
----------------------------------------------------------------------------------
-- Instantiate STOP_SIM procedure:
procedure utils_stop_simulation is
    begin
    -- 
    assert false
    report "... End of Testcase; Ending simulation (not a Failure)"
    severity failure;

--	FINISH( 1 );
    wait;
    -- Final
end utils_stop_simulation;
----------------------------------------------------------------------------------
-- Instantiate PRINT procedure:
procedure utils_print(text: string) is
    variable msg_line: line;
    begin
    --
    write(msg_line, text);
    writeline(output, msg_line);
    -- Final
end utils_print;
----------------------------------------------------------------------------------
end package body utils_pkg;
