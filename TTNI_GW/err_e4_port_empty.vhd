----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date:    01:56:42 01/22/2016
-- Design Name:
-- Module Name:    port_empty - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- count1_lengt

entity port_empty is    --buffer_empty_vhdl

port(
	clk:                in  std_logic;
	reset_n:              in  std_logic;
	clear_flag          : in std_logic;
	p_empty :            in  std_logic;
	deq:                in  std_logic;
	port_empty : 	     out std_logic
);

end port_empty ;

architecture Behavioral of port_empty is

TYPE b_of_state is (RESET, IDLE, UF_DETECTED, UF_DETECTED_WAIT, CHK_DQ);
-- list the definition of the steps:
-- RESET:
-- IDLE:
-- UF_DETECTED:
-- UF_DETECTED_WAIT:
-- CHK_DQ:

SIGNAL  present_state       : b_of_state;
SIGNAL  next_state          : b_of_state;

begin

PROCESS (clk, reset_n)
BEGIN
  IF rising_edge (clk) THEN
	 IF reset_n = '0' THEN
		present_state <= RESET;
	 ELSE
		present_state <= next_state;
	 END IF;
  END IF;
END PROCESS;


state_hndlr: PROCESS (present_state, deq, p_empty, clear_flag)
BEGIN
	next_state <= present_state;
    CASE present_state IS
        WHEN RESET  =>
        	next_state <= IDLE;

        WHEN IDLE =>
        	IF deq = '1' AND p_empty = '1' AND clear_flag='0' THEN
           		next_state <= UF_DETECTED;
        	ELSE
           		next_state <= IDLE;
        	END IF;

        WHEN UF_DETECTED =>
             next_state <= UF_DETECTED_WAIT;

        WHEN UF_DETECTED_WAIT =>
            IF clear_flag = '1' THEN
            	 next_state <= CHK_DQ;
            ELSE
                 next_state <= UF_DETECTED_WAIT;
            END IF;

        WHEN CHK_DQ =>
            IF deq='0' then
           		next_state <= IDLE;
			ELSE
           		next_state <= CHK_DQ;
           	END IF;

        WHEN OTHERS => next_state <= IDLE;
    END CASE;
END PROCESS;

report_proc: process(clk)
begin
if reset_n = '0' then 
	port_empty <= '0';
elsif rising_edge(clk) then
	if present_state = UF_DETECTED_WAIT then
		port_empty <= '1';
	else
		port_empty <= '0';
 	end if;

end if;
end process;

end Behavioral;
