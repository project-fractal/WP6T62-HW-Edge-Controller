----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/06/2021 09:46:18 AM
-- Design Name: 
-- Module Name: mux_4_2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;	-- for conv_integer
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use std.textio.all;

library SAFEPOWER;
use SAFEPOWER.TTEL.all;        		-- constants, datatypes, and component declarations of the current TTEL
use SAFEPOWER.memorymap.all;    	-- convert std_logic_vector to t_ttcommsched

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- parameters of the current NoC instance
use SYSTEMS.configman.all;         	-- for extracting configuration parameters from the files

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux_4_2 is
--  Port ( );
port (
--- write addresse input
-- write data input
    write_data1 : in t_ttcommsched;
    write_data2 : in t_ttcommsched;
    sel : in bit;
    
 -- write data output 
    write_data : out t_ttcommsched
    
);
end mux_4_2;

architecture Behavioral of mux_4_2 is

begin

    write_data <= write_data1 when (sel = '0') else write_data2;

-- process (sel)
-- begin
--    case sel is 
--        when '1' => 
--        -- use the first schedule s1
--            write_data <= write_data1;
            
--        when '0' =>
--        -- use the second schedule s2
--            write_data <= write_data2;
--       when others =>
--        -- do nothing 
    
--    end case;
  
-- end process;

end Behavioral;
