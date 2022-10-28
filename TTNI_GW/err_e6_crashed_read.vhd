----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date:    00:37:02 01/23/2016
-- Design Name:
-- Module Name:    crashed_read - Behavioral
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

entity crashed_read is
generic(
	MAX_CNT  			: unsigned (3 downto 0) :=x"8"
);
port(
	clk:                in  std_logic;
	m_clk :             in  std_logic;
	reset_n:              in  std_logic;
	clear_flag      : in  std_logic;
	ungoing_r:          in  std_logic;
	crashed_rd : 	     out std_logic:= '0'
);

end crashed_read;

architecture Behavioral of crashed_read is

	TYPE b_of_state is (RESET, IDLE, CR_DETECTED_ONCE, CR_COUNT, CR_REPORT, CR_REPORTED);
	-- list the definition of the steps:
	-- RESET: reset state
	-- IDLE:
	-- CR_DETECTED_ONCE:
	-- CR_COUNT:
	-- CR_REPORT:
	-- CR_REPORTED:

	SIGNAL  present_state       : b_of_state;
	SIGNAL  next_state          : b_of_state;

	SIGNAL count1 : unsigned (3 downto 0):= (others => '0');
	SIGNAL lock : bit := '0';

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


	state_hndlr: PROCESS (present_state, ungoing_r, clear_flag, count1)
	BEGIN
		next_state <= present_state;
	    CASE present_state IS
	        WHEN RESET  =>
	        	next_state <= IDLE;

	        WHEN IDLE =>
	        	IF ungoing_r = '1' AND clear_flag='0' THEN
	           		next_state <= CR_DETECTED_ONCE;
	        	ELSE
	           		next_state <= IDLE;
	        	END IF;

	        WHEN CR_DETECTED_ONCE =>
	        	IF ungoing_r = '1' AND clear_flag='0' AND count1 < MAX_CNT THEN
	            	next_state <= CR_COUNT;
	            ELSE
	           		next_state <= IDLE;
	        	END IF;

	        WHEN CR_COUNT =>
	            IF ungoing_r = '1' AND clear_flag='0' AND count1 = MAX_CNT THEN
	                next_state <= CR_REPORT;
	            ELSIF ungoing_r = '1' AND clear_flag='0' AND count1 /= MAX_CNT  THEN
	                next_state <= CR_COUNT;
	            ELSE
	                next_state <= IDLE;
	            END IF;

	        WHEN CR_REPORT =>
	            IF  clear_flag='1' THEN
	               	next_state <= CR_REPORTED;
	            ELSE
	                next_state <= CR_REPORT;
	            END IF;

	        WHEN CR_REPORTED =>
	           	IF ungoing_r='0' THEN
	           		next_state <= IDLE;
				ELSE
	           		next_state <= CR_REPORTED;
	            END IF;

	        WHEN OTHERS => next_state <= IDLE;
	    END CASE;
	END PROCESS;

	detected_proc: process (m_clk)
	begin
	if rising_edge(m_clk) then
		if present_state = CR_COUNT   then
			count1 <= count1 + 1;
			if count1 > MAX_CNT then
			    count1 <= MAX_CNT;
			end if;
		else
	        count1 <= (others => '0');
	 	end if;
	end if;

	end process;


	report_proc: process(clk)
	begin
	if reset_n = '0' then 
		crashed_rd <= '0';
	elsif rising_edge(clk) then
		if present_state = CR_REPORT  then
			crashed_rd <= '1';
		else
			crashed_rd <= '0';
	 	end if;
	end if;
	end process;

	end Behavioral;
