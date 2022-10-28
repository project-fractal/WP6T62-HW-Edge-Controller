----------------------------------------------------------------------------------
-- Company:
-- Engineer: Farzad Nekouei
-- Debugged and modified by Hamidreza Ahmadian
-- Create Date:    00:57:13 01/26/2016
-- Design Name:
-- Module Name:    prescaler - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

library SYSTEMS;
use SYSTEMS.system_parameter.all;	-- count1_lengt

entity prescaler is
generic(
	n               : integer := 600;
	count1_length   : integer := 15
);
port(
	clk 			: in  std_logic;
	rstn			: in  std_logic;
	freq			: out std_logic            -- clk > 2freq  hz
);
end prescaler;

architecture Behavioral of prescaler is

signal count1 :  unsigned(count1_length downto 0):= (others => '0');

begin

count_proc: process (clk, rstn)
begin
	if rstn = '0' then 
		count1 <= (others => '0'); 
	elsif rising_edge (clk) then
		count1 <= count1 + 1;
  		if count1 = n-1 then
    		count1<=(others => '0');
  		end if;
  	end if;
end process;

freq_proc: process (clk)
begin
  if rising_edge (clk) then
    if count1 = n - 1 then
      freq<='1';
    else
      freq<='0';
    end if;
  end if;
  end process;
end Behavioral;
