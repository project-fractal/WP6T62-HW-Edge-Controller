----------------------------------------------------------------------------------
-- Company:
-- Engineer:
-- Modified and debugged by: Hamidreza Ahmadian
-- Create Date:    10:51:06 01/21/2016
-- Design Name:
-- Module Name:    Error_Controller_VHDL - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: this entity recognizes the case, in which a buffer of a port is
-- written into, while it's already full
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

entity buffer_overflow is
port(
	clk					: in  std_logic;
	reset_n				: in std_logic;
	clear_flag          : in std_logic;
	buff_full 			: in  std_logic;
	enq					: in  std_logic;
	buffer_over 		: out std_logic
);
end buffer_overflow;

architecture Behavioral of buffer_overflow is

	TYPE b_of_state is (RESET, IDLE, OF_DETECTED, OF_DETECTED_WAIT, CHK_ENQ);
	-- list the definition of the steps:
	-- RESET: reset state
	-- IDLE: wait state, it waits for enq while buffer full
	-- OF_DETECTED: in this state the OF error is detected for the first time, waits for the second time
	-- OF_DETECTED_WAIT: in this state the OF will be reported
	-- CHK_ENQ: in this state the error is already reported and it waits untill the enq input is released.

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


	state_hndlr: PROCESS (present_state, enq, buff_full, clear_flag)
	BEGIN
		next_state <= present_state;
	    CASE present_state IS
	        WHEN RESET  =>
	        	next_state <= IDLE;

	        WHEN IDLE =>
	        	IF enq = '1' AND buff_full = '1' AND clear_flag='0' THEN
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

	report_proc: process(clk, reset_n)
	begin
	if reset_n = '0' then
		buffer_over <= '0';
	elsif rising_edge(clk) then
		if present_state = OF_DETECTED_WAIT then
			buffer_over <= '1';
		else
			buffer_over <= '0';
	 	end if;
	end if;
	end process;

	end Behavioral;
