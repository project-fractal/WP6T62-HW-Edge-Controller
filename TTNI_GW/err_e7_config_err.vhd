----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
--
-- Create Date: 07/27/2016 09:07:49 PM
-- Design Name:
-- Module Name: config_error - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- count1_lengt

entity config_error is

  port(
    clk                 :in  std_logic;
    reset_n             :in  std_logic;
    clear_flag          :in std_logic;
    config_error_in     :in  std_logic;
    config_error_out    :out std_logic
  );
end config_error;

architecture Behavioral of config_error is

TYPE b_of_state is (RESET, IDLE, CE_DETECTED, CE_DETECTED_WAIT, CHK_CE);
-- list the definition of the steps:
-- RESET:
-- IDLE:
-- CE_DETECTED:
-- CE_DETECTED_WAIT:
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


state_hndlr: PROCESS (present_state, config_error_in , clear_flag)
BEGIN
	next_state <= present_state;
    CASE present_state IS
        WHEN RESET  =>
        	next_state <= IDLE;

        WHEN IDLE =>
        	IF config_error_in= '1' AND clear_flag='0' THEN
           		next_state <= CE_DETECTED;
        	ELSE
           		next_state <= IDLE;
        	END IF;

        WHEN CE_DETECTED =>
             next_state <= CE_DETECTED_WAIT;

        WHEN CE_DETECTED_WAIT =>
            IF clear_flag = '1' THEN
            	 next_state <= CHK_CE;
            ELSE
                 next_state <= CE_DETECTED_WAIT;
            END IF;

        WHEN CHK_CE =>
            IF config_error_in='0' then
           		next_state <= IDLE;
			ELSE
           		next_state <= CHK_CE;
           	END IF;

        WHEN OTHERS => next_state <= IDLE;
    END CASE;
END PROCESS;

report_proc: process(clk, reset_n)
begin
if reset_n = '0' then
	config_error_out <= '0';
elsif rising_edge(clk) then
	if present_state = CE_DETECTED_WAIT then
		config_error_out <= '1';
	else
		config_error_out <= '0';
 	end if;

end if;
end process;

end Behavioral;
