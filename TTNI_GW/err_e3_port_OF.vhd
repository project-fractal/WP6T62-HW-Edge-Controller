----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date:    01:48:45 01/22/2016
-- Design Name:
-- Module Name:    port_overflow - Behavioral
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

entity port_overflow  is

port(
	clk:                in  std_logic;
	reset_n:              in  std_logic;
	clear_flag          : in std_logic;
	port_full :            in  std_logic;
	enq:                in  std_logic;
	port_over : 	     out std_logic
);

end port_overflow ;

architecture Behavioral of port_overflow  is

	TYPE b_of_state is (RESET, IDLE, OF_DETECTED, OF_DETECTED_WAIT, CHK_ENQ);
	-- list the definition of the steps:
	-- RESET: reset state
	-- IDLE:
	-- OF_DETECTED:
	-- OF_DETECTED_WAIT:
	-- CHK_ENQ:

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


	state_hndlr: PROCESS (present_state, enq, port_full, clear_flag)
	BEGIN
		next_state <= present_state;
	    CASE present_state IS
	        WHEN RESET  =>
	        	next_state <= IDLE;

	        WHEN IDLE =>
	        	IF enq = '1' AND port_full = '1' AND clear_flag='0' THEN
	           		next_state <= OF_DETECTED;
	        	ELSE
	           		next_state <= IDLE;
	        	END IF;

	        WHEN OF_DETECTED =>
	             next_state <= OF_DETECTED_WAIT;

	        WHEN OF_DETECTED_WAIT =>
	            IF clear_flag = '1' THEN
	            	 next_state <= CHK_ENQ;
	            ELSE
	                 next_state <= OF_DETECTED_WAIT;
	            END IF;

	        WHEN CHK_ENQ =>
	            IF enq='0' then
	           		next_state <= IDLE;
				ELSE
	           		next_state <= CHK_ENQ;
	           	END IF;

	        WHEN OTHERS => next_state <= IDLE;
	    END CASE;
	END PROCESS;

	report_proc: process(clk)
	begin
	if reset_n = '0' then
		port_over <= '0';
	elsif rising_edge(clk) then
		if present_state = OF_DETECTED_WAIT then
			port_over <= '1';
		else
			port_over <= '0';
	 	end if;

	end if;
	end process;

	end Behavioral;
